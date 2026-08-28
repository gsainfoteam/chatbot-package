import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'chat_api_endpoints.dart';
import 'chat_api_types.dart';

/// API 호출 예외
class ChatApiException implements Exception {
  ChatApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isRateLimit => statusCode == 429;

  @override
  String toString() => 'ChatApiException: $message (status: $statusCode)';
}

/// 스트리밍 중지용 토큰. cancel() 호출 시 진행 중인 스트림 구독을 끊는다.
class StreamCancelToken {
  bool _cancelled = false;
  void Function()? _onCancel;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _onCancel?.call();
  }
}

String _parseErrorBody(String body, int statusCode) {
  if (body.isEmpty) return 'Request failed ($statusCode)';
  try {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final msg = json['message'] as String?;
    if (msg != null && msg.isNotEmpty) return msg;
  } catch (_) {}
  return body;
}

/// 채팅 API 클라이언트
class ChatApiClient {
  ChatApiClient({
    required String baseUrl,
    String? resourceCenterUrl,
    String? sessionToken,
    String? accessToken,
    http.Client? client,
  }) : _baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _resourceCenterUrl = resourceCenterUrl,
       _sessionToken = sessionToken,
       _accessToken = accessToken,
       _client = client ?? http.Client();

  final String _baseUrl;
  final String? _resourceCenterUrl;
  String? _sessionToken;
  final String? _accessToken;
  final http.Client _client;

  void setSessionToken(String? value) {
    _sessionToken = value;
  }

  String? get sessionToken => _sessionToken;

  Map<String, String> _headers({bool json = true}) {
    final h = <String, String>{};
    // 본문 없이 Content-Type: application/json을 보내면 Fastify가 400을 반환함
    if (json) h['Content-Type'] = 'application/json';
    final token = _sessionToken ?? _accessToken;
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl/$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  /// 세션 생성 (앱: clientType=app, appId)
  Future<CreateSessionResponse> createSession(
    CreateSessionRequest request,
  ) async {
    final response = await _client.post(
      _uri(ChatApiEndpoints.createSession),
      headers: _headers(),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ChatApiException(
        _parseErrorBody(response.body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CreateSessionResponse.fromJson(data);
  }

  /// 대화 내역 조회
  Future<GetMessagesResponse> getMessages({
    String? cursor,
    int limit = 20,
  }) async {
    final query = <String, String>{'limit': limit.toString()};
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    final response = await _client.get(
      _uri(ChatApiEndpoints.getMessages, query),
      headers: _headers(json: false),
    );

    if (response.statusCode != 200) {
      throw ChatApiException(
        _parseErrorBody(response.body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return GetMessagesResponse.fromJson(data);
  }

  /// 가장 최근에 저장된 assistant 메시지 조회.
  /// 스트리밍 응답에는 메시지 ID가 없으므로, 스트림 완료 직후 이 API로
  /// 서버 메시지 ID를 얻어 피드백/재생성에 사용한다.
  Future<ChatMessageDto?> getLatestAssistantMessage() async {
    final res = await getMessages(limit: 1);
    final latest = res.messages.isNotEmpty ? res.messages.first : null;
    return latest != null && latest.role == 'assistant' ? latest : null;
  }

  /// assistant 답변 피드백 등록/변경
  Future<void> submitFeedback(String messageId, FeedbackRating rating) async {
    final response = await _client.put(
      _uri(ChatApiEndpoints.feedback(messageId)),
      headers: _headers(),
      body: jsonEncode({'rating': rating.apiValue}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ChatApiException(
        _parseErrorBody(response.body, response.statusCode),
        statusCode: response.statusCode,
      );
    }
  }

  /// 채팅 메시지 전송 (스트리밍)
  Future<SendChatResponse> sendChatMessage(
    SendChatRequest request, {
    void Function(String text)? onChunk,
    StreamCancelToken? cancelToken,
  }) {
    return _streamChatResponse(
      ChatApiEndpoints.sendChatStream,
      body: jsonEncode(request.toJson()),
      onChunk: onChunk,
      cancelToken: cancelToken,
    );
  }

  /// BAD 피드백 답변 1회 재생성 (스트리밍, 본문 없음)
  Future<SendChatResponse> regenerateAnswer(
    String messageId, {
    void Function(String text)? onChunk,
    StreamCancelToken? cancelToken,
  }) {
    return _streamChatResponse(
      ChatApiEndpoints.regenerateStream(messageId),
      body: null,
      onChunk: onChunk,
      cancelToken: cancelToken,
    );
  }

  /// SSE 채팅 스트림 공통 처리 (웹 위젯의 streamWidgetChatResponse와 동일 규칙)
  Future<SendChatResponse> _streamChatResponse(
    String path, {
    String? body,
    void Function(String text)? onChunk,
    StreamCancelToken? cancelToken,
  }) async {
    final req = http.Request('POST', _uri(path))
      ..headers.addAll(_headers(json: body != null));
    if (body != null) req.body = body;

    final streamedResponse = await _client.send(req);

    if (streamedResponse.statusCode != 200) {
      final errorBody = await streamedResponse.stream.bytesToString();
      throw ChatApiException(
        _parseErrorBody(errorBody, streamedResponse.statusCode),
        statusCode: streamedResponse.statusCode,
      );
    }

    final completer = Completer<SendChatResponse>();
    var fullText = '';
    var resources = <RawResource>[];

    void completeWith() {
      if (!completer.isCompleted) {
        completer.complete(
          SendChatResponse(
            answer: fullText,
            sources: resources
                .map(
                  (r) =>
                      resolveSource(r, resourceCenterUrl: _resourceCenterUrl),
                )
                .toList(),
          ),
        );
      }
    }

    void failWith(Object error, [StackTrace? st]) {
      if (!completer.isCompleted) {
        completer.completeError(error, st);
      }
    }

    late final StreamSubscription<String> subscription;
    subscription = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (!line.startsWith('data: ')) return;
            final data = line.substring(6).trim();

            if (data == '[DONE]') {
              completeWith();
              subscription.cancel();
              return;
            }

            Map<String, dynamic> parsed;
            try {
              parsed = jsonDecode(data) as Map<String, dynamic>;
            } catch (_) {
              // 불완전한 JSON 청크는 무시 (웹 위젯과 동일)
              return;
            }

            final error = parsed['error'];
            if (error != null) {
              failWith(ChatApiException(error.toString()));
              subscription.cancel();
              return;
            }

            final content = parsed['content'];
            if (content is String) {
              fullText += content;
              onChunk?.call(fullText);
            }

            if (parsed['type'] == 'resources') {
              final raw = parsed['resources'] as List<dynamic>? ?? [];
              resources = raw
                  .map((r) => RawResource.fromJson(r as Map<String, dynamic>))
                  .toList();
            }
          },
          onDone: completeWith,
          onError: failWith,
          cancelOnError: true,
        );

    cancelToken?._onCancel = () {
      subscription.cancel();
      failWith(StreamCancelledException());
    };
    if (cancelToken?.isCancelled ?? false) {
      subscription.cancel();
      failWith(StreamCancelledException());
    }

    return completer.future;
  }
}

/// 사용자가 스트리밍을 중지했을 때 발생
class StreamCancelledException implements Exception {}
