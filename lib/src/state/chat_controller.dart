import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/chat_api_client.dart';
import '../api/chat_api_types.dart' as api;
import '../app_id_resolver.dart';
import '../config/gist_chatbot_config.dart';
import '../session/session_manager.dart';
import 'chat_message.dart';

/// 로딩 단계 문구 (웹 위젯과 동일)
const _loadingMessageInitial = '자료를 찾아보는 중';
const _loadingMessageReading = '파일을 읽어보는 중';
const _loadingMessageThinking = '조금 더 생각 중';
const _loadingMessageRegenerating = '답변을 다시 생성하는 중';

int _uidSeq = 0;

String _uid() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_uidSeq++}';

/// 채팅 컨트롤러 (ChangeNotifier)
///
/// 웹 위젯(ChatWidget.tsx)과 동일한 대화 흐름을 제공한다:
/// 웰컴 메시지로 시작하고, 첫 전송 시 세션을 발급하며,
/// 스트리밍 중지/피드백/재생성/429 카운트다운을 지원한다.
class ChatController extends ChangeNotifier {
  ChatController({
    required GistChatbotConfig config,
    ChatApiClient? apiClient,
    SessionManager? sessionManager,
  }) : _config = config,
       _apiClient =
           apiClient ??
           ChatApiClient(
             baseUrl: config.apiBaseUrl,
             resourceCenterUrl: config.resourceCenterUrl,
             accessToken: config.accessToken,
           ),
       _sessionManager = sessionManager ?? SessionManager() {
    _messages.add(
      ChatMessage(id: _uid(), role: MessageRole.assistant, text: '무엇을 도와드릴까요?'),
    );
  }

  final GistChatbotConfig _config;
  final ChatApiClient _apiClient;
  final SessionManager _sessionManager;

  final List<ChatMessage> _messages = [];
  bool _loading = false;
  String _loadingMessage = _loadingMessageInitial;
  Timer? _loadingPhaseTimer1;
  Timer? _loadingPhaseTimer2;
  StreamCancelToken? _cancelToken;
  String? _streamingMessageId;

  /// 429 발생 시 재시도 가능 시각(ms). null이면 경고 없음
  int? _rateLimitRetryAt;

  /// 피드백 전송 중인 메시지 ID (중복 클릭 방지)
  String? _feedbackBusyId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get loading => _loading;
  String get loadingMessage => _loadingMessage;
  int? get rateLimitRetryAt => _rateLimitRetryAt;
  String? get feedbackBusyId => _feedbackBusyId;

  /// 자주 묻는 질문 표시 여부: 사용자가 한 번이라도 보내면 숨김 (웹과 동일)
  bool get showFrequentQuestions =>
      _messages.every((m) => m.role == MessageRole.assistant);

  /// 피드백 BAD 시 재생성 대상이 되는 최신 assistant 메시지 ID
  String? get latestFeedbackMessageId {
    if (_messages.isEmpty) return null;
    final last = _messages.last;
    return last.role == MessageRole.assistant ? last.id : null;
  }

  bool get canSend => !_loading;

  void _setLoading(bool value, {bool regenerating = false}) {
    _loading = value;
    _loadingPhaseTimer1?.cancel();
    _loadingPhaseTimer2?.cancel();
    if (value) {
      _loadingMessage = regenerating
          ? _loadingMessageRegenerating
          : _loadingMessageInitial;
      // 로딩 시간에 따라 문구 변경 (웹과 동일: 3초/6초)
      _loadingPhaseTimer1 = Timer(const Duration(seconds: 3), () {
        _loadingMessage = _loadingMessageReading;
        notifyListeners();
      });
      _loadingPhaseTimer2 = Timer(const Duration(seconds: 6), () {
        _loadingMessage = _loadingMessageThinking;
        notifyListeners();
      });
    }
  }

  int _indexOf(String id) => _messages.indexWhere((m) => m.id == id);

  void _updateMessage(String id, ChatMessage Function(ChatMessage) update) {
    final idx = _indexOf(id);
    if (idx >= 0) {
      _messages[idx] = update(_messages[idx]);
      notifyListeners();
    }
  }

  String? _resolvedAppId;

  Future<String> _ensureSession() async {
    var token = await _sessionManager.loadSession();
    if (token != null) {
      _apiClient.setSessionToken(token);
      return token;
    }
    final appId = await resolveAppId(_config.appId);
    _resolvedAppId = appId;
    final response = await _apiClient.createSession(
      api.CreateSessionRequest(widgetKey: _config.widgetKey, appId: appId),
    );
    _apiClient.setSessionToken(response.sessionToken);
    await _sessionManager.saveSession(
      response.sessionToken,
      response.expiresIn,
    );
    return response.sessionToken;
  }

  /// 스트림 완료 후 서버 메시지 ID를 로컬 메시지에 연결 (피드백/재생성 API용)
  Future<void> _attachServerId(
    String localId, {
    bool regenerated = false,
  }) async {
    try {
      final latest = await _apiClient.getLatestAssistantMessage();
      if (latest == null) return;
      _updateMessage(localId, (m) {
        var next = m.copyWith(serverId: latest.id);
        if (latest.feedback != null) {
          next = next.copyWith(feedback: latest.feedback);
        }
        if (regenerated) next = next.copyWith(regeneratedAnswer: true);
        return next;
      });
    } catch (e) {
      // 실패 시 해당 답변의 피드백 버튼만 표시되지 않음 (채팅에는 영향 없음)
      debugPrint('Failed to attach server message id: $e');
    }
  }

  /// 메시지 전송
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;

    _rateLimitRetryAt = null;
    _messages.add(
      ChatMessage(id: _uid(), role: MessageRole.user, text: trimmed),
    );
    _setLoading(true);
    notifyListeners();

    final assistantId = _uid();
    _messages.add(
      ChatMessage(id: assistantId, role: MessageRole.assistant, text: ''),
    );
    _streamingMessageId = assistantId;
    notifyListeners();

    try {
      await _ensureSession();

      final cancelToken = StreamCancelToken();
      _cancelToken = cancelToken;

      final response = await _apiClient.sendChatMessage(
        api.SendChatRequest(question: trimmed),
        onChunk: (streamedText) {
          _updateMessage(assistantId, (m) => m.copyWith(text: streamedText));
        },
        cancelToken: cancelToken,
      );

      _cancelToken = null;
      _streamingMessageId = null;
      _updateMessage(
        assistantId,
        (m) => m.copyWith(text: response.answer, sources: response.sources),
      );
      _setLoading(false);
      notifyListeners();

      await _attachServerId(assistantId);
    } catch (e) {
      _cancelToken = null;
      _streamingMessageId = null;
      _setLoading(false);
      _handleStreamError(e, assistantId);
      notifyListeners();
    }
  }

  /// BAD 피드백 답변 1회 재생성 (웹과 동일: 원본 답변 자리에서 스트리밍)
  Future<void> _regenerateAnswer(ChatMessage originalMsg) async {
    final serverId = originalMsg.serverId;
    if (serverId == null || _loading) return;

    final regenId = _uid();
    final idx = _indexOf(originalMsg.id);
    if (idx < 0) return;
    _messages[idx] = ChatMessage(
      id: regenId,
      role: MessageRole.assistant,
      text: '',
      regeneratedAnswer: true,
    );
    _streamingMessageId = regenId;
    _setLoading(true, regenerating: true);
    notifyListeners();

    try {
      final cancelToken = StreamCancelToken();
      _cancelToken = cancelToken;

      final response = await _apiClient.regenerateAnswer(
        serverId,
        onChunk: (streamedText) {
          _updateMessage(regenId, (m) => m.copyWith(text: streamedText));
        },
        cancelToken: cancelToken,
      );

      _cancelToken = null;
      _streamingMessageId = null;
      _updateMessage(
        regenId,
        (m) => m.copyWith(text: response.answer, sources: response.sources),
      );
      _setLoading(false);
      notifyListeners();

      await _attachServerId(regenId, regenerated: true);
    } catch (e) {
      _cancelToken = null;
      _streamingMessageId = null;
      _setLoading(false);
      if (e is StreamCancelledException) {
        notifyListeners();
        return;
      }
      debugPrint('Failed to regenerate answer: $e');
      // 이미 받은 텍스트가 있으면 유지, 없으면 원본 답변 복원
      final regenIdx = _indexOf(regenId);
      if (regenIdx >= 0 && _messages[regenIdx].text.isEmpty) {
        _messages[regenIdx] = originalMsg;
      }
      notifyListeners();
    }
  }

  /// 답변 피드백 처리 (GOOD: 해결됨 / BAD: 해결 안 됨 + 1회 재생성)
  Future<void> submitFeedback(ChatMessage msg, FeedbackRating rating) async {
    if (msg.serverId == null || _loading || _feedbackBusyId != null) return;

    final canRegenerate =
        msg.id == latestFeedbackMessageId &&
        rating == FeedbackRating.bad &&
        !msg.regeneratedAnswer;
    // 같은 피드백 재클릭: 재생성이 남아있는 BAD가 아니면 무시
    if (msg.feedback == rating && !canRegenerate) return;

    _feedbackBusyId = msg.id;
    notifyListeners();
    try {
      if (msg.feedback != rating) {
        await _apiClient.submitFeedback(msg.serverId!, rating);
        _updateMessage(msg.id, (m) => m.copyWith(feedback: rating));
      }
      if (canRegenerate) {
        final current = _messages[_indexOf(msg.id)];
        _feedbackBusyId = null;
        await _regenerateAnswer(current);
        return;
      }
    } catch (e) {
      debugPrint('Failed to submit feedback: $e');
    } finally {
      _feedbackBusyId = null;
      notifyListeners();
    }
  }

  /// 스트리밍 중지: 받은 텍스트는 유지하고 중지 안내를 덧붙인다 (웹과 동일)
  void stopStreaming() {
    final msgId = _streamingMessageId;
    _setLoading(false);
    if (msgId != null) {
      _updateMessage(msgId, (m) {
        final text = m.text.trim().isNotEmpty
            ? '${m.text}\n\n_(응답이 중지되었습니다)_'
            : '응답이 중지되었습니다.';
        return m.copyWith(text: text);
      });
      _streamingMessageId = null;
    }
    _cancelToken?.cancel();
    _cancelToken = null;
    notifyListeners();
  }

  void _handleStreamError(Object e, String assistantId) {
    if (e is StreamCancelledException) return;

    // 위젯 키/앱 등록 설정 오류: 재시도해도 해결되지 않으므로 명확히 안내
    if (e is ChatApiException && _isConfigError(e)) {
      _replaceWithError(assistantId, _configErrorMessage(e));
      debugPrint(
        'GistChatbot: session rejected (status ${e.statusCode}) - '
        '${e.message} (widgetKey: ${_config.widgetKey}, '
        'appId: ${_resolvedAppId ?? _config.appId ?? 'auto'})',
      );
      return;
    }

    // 세션이 서버에서 무효화된 경우: 저장된 토큰을 버려 다음 전송에서 재발급
    if (e is ChatApiException && e.statusCode == 401) {
      _apiClient.setSessionToken(null);
      _sessionManager.clearSession();
      _replaceWithError(assistantId, '세션이 만료되었습니다. 다시 시도해주세요.');
      return;
    }

    if (e is ChatApiException && e.isRateLimit) {
      // 429: placeholder 제거 + 배너 카운트다운 (재시도 가능 시각 = 세션 만료)
      _messages.removeWhere((m) => m.id == assistantId);
      _sessionManager.expiresAt().then((retryAt) {
        if (retryAt != null) {
          _rateLimitRetryAt = retryAt;
          notifyListeners();
        }
      });
      return;
    }

    // 이미 일부 텍스트를 받았다면 유지, 없으면 에러 문구로 교체 (웹과 동일)
    final idx = _indexOf(assistantId);
    if (idx >= 0) {
      if (_messages[idx].text.isEmpty) {
        _messages[idx] = _messages[idx].copyWith(
          text: '죄송합니다. 응답을 받는 중 오류가 발생했습니다.',
        );
      }
    } else {
      _messages.add(
        ChatMessage(
          id: _uid(),
          role: MessageRole.assistant,
          text: '죄송합니다. 메시지를 전송하는 중 오류가 발생했습니다. 다시 시도해주세요.',
        ),
      );
    }
    debugPrint('Failed to send chat message: $e');
  }

  bool _isConfigError(ChatApiException e) =>
      e.statusCode == 400 || e.statusCode == 403 || e.statusCode == 404;

  String _configErrorMessage(ChatApiException e) {
    switch (e.statusCode) {
      case 404:
        return '위젯 키가 유효하지 않습니다. 앱 설정을 확인해주세요.';
      case 403:
        return '이 앱은 챗봇 서비스에 등록되어 있지 않습니다. 관리자에게 문의해주세요.';
      default:
        return '챗봇 설정이 올바르지 않습니다. 앱 설정을 확인해주세요.';
    }
  }

  /// placeholder 답변을 에러 안내 문구로 교체
  void _replaceWithError(String assistantId, String message) {
    final idx = _indexOf(assistantId);
    if (idx >= 0) {
      _messages[idx] = _messages[idx].copyWith(text: message);
    } else {
      _messages.add(
        ChatMessage(id: _uid(), role: MessageRole.assistant, text: message),
      );
    }
  }

  /// 429 카운트다운 종료 시 배너 해제
  void clearRateLimitWarning() {
    if (_rateLimitRetryAt == null) return;
    _rateLimitRetryAt = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _loadingPhaseTimer1?.cancel();
    _loadingPhaseTimer2?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }
}
