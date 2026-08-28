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
    String? sessionToken,
    String? accessToken,
    http.Client? client,
  })  : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _sessionToken = sessionToken,
        _accessToken = accessToken,
        _client = client ?? http.Client();

  final String _baseUrl;
  String? _sessionToken;
  final String? _accessToken;
  final http.Client _client;

  void setSessionToken(String? value) {
    _sessionToken = value;
  }

  String? get sessionToken => _sessionToken;

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = _sessionToken ?? _accessToken;
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  /// 세션 생성 (앱: clientType=app, appId)
  Future<CreateSessionResponse> createSession(
    CreateSessionRequest request,
  ) async {
    final url = Uri.parse('$_baseUrl/${ChatApiEndpoints.createSession}');
    final response = await _client.post(
      url,
      headers: _headers,
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

  /// 대화 내역 조회 (페이징)
  Future<GetMessagesResponse> getMessages({
    String? cursor,
    int limit = 20,
  }) async {
    final query = <String, String>{'limit': limit.toString()};
    if (cursor != null && cursor.isNotEmpty) query['cursor'] = cursor;
    final url = Uri.parse('$_baseUrl/${ChatApiEndpoints.getMessages}')
        .replace(queryParameters: query);
    final response = await _client.get(url, headers: _headers);

    if (response.statusCode != 200) {
      throw ChatApiException(
        _parseErrorBody(response.body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return GetMessagesResponse.fromJson(data);
  }

  /// 메시지 저장 (선택)
  Future<ChatMessageDto> postMessage(SaveMessageRequest request) async {
    final url = Uri.parse('$_baseUrl/${ChatApiEndpoints.postMessage}');
    final response = await _client.post(
      url,
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ChatApiException(
        _parseErrorBody(response.body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ChatMessageDto.fromJson(data);
  }

  /// 리소스 조회 (바이너리)
  Future<List<int>> getResource(String path) async {
    final encoded = Uri.encodeComponent(path);
    final url =
        Uri.parse('$_baseUrl/${ChatApiEndpoints.resourcesPrefix}$encoded');
    final response = await _client.get(url, headers: _headers);

    if (response.statusCode != 200) {
      throw ChatApiException(
        _parseErrorBody(response.body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    return response.bodyBytes;
  }

  /// 채팅 메시지 전송 (스트리밍)
  Future<SendChatResponse> sendChatMessage(
    SendChatRequest request, {
    void Function(String text, bool isComplete)? onChunk,
    Future<void> Function()? cancelSignal,
  }) async {
    final url = Uri.parse('$_baseUrl/${ChatApiEndpoints.sendChatStream}');
    final req = http.Request('POST', url)
      ..headers.addAll(_headers)
      ..body = jsonEncode(request.toJson());

    final streamedResponse = await _client.send(req);

    if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      throw ChatApiException(
        _parseErrorBody(body, streamedResponse.statusCode),
        statusCode: streamedResponse.statusCode,
      );
    }

    final completer = Completer<SendChatResponse>();
    String fullText = '';
    List<ChatSource> resources = [];

    final subscription = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (line.trim().isEmpty) return;

        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') {
            if (!completer.isCompleted) {
              completer.complete(
                SendChatResponse(answer: fullText, sources: resources),
              );
            }
            return;
          }

          try {
            final parsed = jsonDecode(data) as Map<String, dynamic>;

            if (parsed['error'] != null) {
              throw ChatApiException(parsed['error'] as String);
            }

            if (parsed['content'] != null) {
              fullText += parsed['content'] as String;
              onChunk?.call(fullText, false);
            }

            if (parsed['type'] == 'resources') {
              final raw = parsed['resources'] as List<dynamic>? ?? [];
              resources = raw.map((r) {
                final m = r as Map<String, dynamic>;
                final path = m['path'] as String?;
                final urlStr = m['url'] as String? ?? '';
                final isImage = urlStr.toLowerCase().endsWith('.png') ||
                    (m['formats'] as List<dynamic>?)
                        ?.any((f) => f.toString().toLowerCase() == 'png') ==
                        true;
                return ChatSource(
                  type: isImage ? 'image' : 'url',
                  url: urlStr,
                  title: path,
                  path: path,
                );
              }).toList();
            }
          } catch (e) {
            if (e is ChatApiException) rethrow;
          }
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(
            SendChatResponse(answer: fullText, sources: resources),
          );
        }
      },
      onError: (e, st) {
        if (!completer.isCompleted) {
          completer.completeError(e, st);
        }
      },
      cancelOnError: true,
    );

    if (cancelSignal != null) {
      cancelSignal().then((_) => subscription.cancel());
    }

    final result = await completer.future;
    onChunk?.call(result.answer, true);
    return result;
  }
}
