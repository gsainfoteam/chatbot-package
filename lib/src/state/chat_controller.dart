import 'package:flutter/foundation.dart';

import '../api/chat_api_client.dart';
import '../api/chat_api_types.dart';
import '../app_id_resolver.dart';
import '../config/gist_chatbot_config.dart';
import '../session/session_manager.dart';
import 'chat_message.dart' as msg;

/// 채팅 상태
enum ChatStatus {
  idle,
  loadingSession,
  sendingMessage,
  error,
}

/// 세션당 user 질문 최대 횟수 (API 명세)
const int kMaxQuestionsPerSession = 5;

/// 채팅 컨트롤러 (ChangeNotifier)
class ChatController extends ChangeNotifier {
  ChatController({
    required GistChatbotConfig config,
    ChatApiClient? apiClient,
    SessionManager? sessionManager,
  })  : _config = config,
        _apiClient = apiClient ??
            ChatApiClient(
              baseUrl: config.apiBaseUrl,
              accessToken: config.accessToken,
            ),
        _sessionManager = sessionManager ?? SessionManager();

  final GistChatbotConfig _config;
  final ChatApiClient _apiClient;
  final SessionManager _sessionManager;

  final List<msg.ChatMessage> _messages = [];
  ChatStatus _status = ChatStatus.idle;
  String? _errorMessage;
  bool _sessionReady = false;
  String? _nextCursor;

  List<msg.ChatMessage> get messages => List.unmodifiable(_messages);
  ChatStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get sessionReady => _sessionReady;
  bool get hasMoreHistory => _nextCursor != null;

  /// 세션 초기화 (앱: clientType=app, appId)
  Future<void> initSession() async {
    if (_sessionReady) return;

    _status = ChatStatus.loadingSession;
    _errorMessage = null;
    notifyListeners();

    try {
      var token = await _sessionManager.loadSession();
      if (token != null) {
        _apiClient.setSessionToken(token);
        _sessionReady = true;
        _status = ChatStatus.idle;
        _messages.clear();
        _nextCursor = null;
        await _loadHistory();
        notifyListeners();
        return;
      }

      final appId = await resolveAppId(_config.appId);
      final request = CreateSessionRequest(
        widgetKey: _config.widgetKey,
        clientType: 'app',
        appId: appId,
      );
      final response = await _apiClient.createSession(request);
      _apiClient.setSessionToken(response.sessionToken);
      await _sessionManager.saveSession(
        response.sessionToken,
        response.expiresIn,
      );
      _sessionReady = true;
      _status = ChatStatus.idle;
      _errorMessage = null;
      _messages.clear();
      _nextCursor = null;
      await _loadHistory();
    } catch (e) {
      _status = ChatStatus.error;
      _errorMessage = e is ChatApiException ? e.message : e.toString();
    }
    notifyListeners();
  }

  Future<void> _loadHistory() async {
    try {
      final res = await _apiClient.getMessages(limit: 20);
      _nextCursor = res.nextCursor;
      final list = res.messages.reversed.map((dto) {
        final role = dto.role == 'assistant'
            ? msg.MessageRole.assistant
            : msg.MessageRole.user;
        return msg.ChatMessage(
          id: dto.id,
          role: role,
          text: dto.content,
        );
      }).toList();
      _messages.insertAll(0, list);
    } catch (_) {
      // 히스토리 실패 시 무시
    }
  }

  /// 추가 대화 내역 로드 (페이징)
  Future<void> loadMoreHistory() async {
    if (_nextCursor == null || !_sessionReady) return;
    try {
      final res =
          await _apiClient.getMessages(cursor: _nextCursor, limit: 20);
      _nextCursor = res.nextCursor;
      final list = res.messages.reversed.map((dto) {
        final role = dto.role == 'assistant'
            ? msg.MessageRole.assistant
            : msg.MessageRole.user;
        return msg.ChatMessage(
          id: dto.id,
          role: role,
          text: dto.content,
        );
      }).toList();
      _messages.insertAll(0, list);
      notifyListeners();
    } catch (_) {}
  }

  /// 메시지 전송
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (!_sessionReady) {
      await initSession();
      if (!_sessionReady) return;
    }

    final userMsg = msg.ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      role: msg.MessageRole.user,
      text: trimmed,
    );
    _messages.add(userMsg);
    _status = ChatStatus.sendingMessage;
    _errorMessage = null;
    notifyListeners();

    final assistantId = 'assistant_${DateTime.now().millisecondsSinceEpoch}';
    final placeholderMsg = msg.ChatMessage(
      id: assistantId,
      role: msg.MessageRole.assistant,
      text: '',
    );
    _messages.add(placeholderMsg);
    notifyListeners();

    try {
      final response = await _apiClient.sendChatMessage(
        SendChatRequest(question: trimmed),
        onChunk: (chunkText, isComplete) {
          final idx = _messages.indexWhere((m) => m.id == assistantId);
          if (idx >= 0) {
            _messages[idx] = _messages[idx].copyWith(text: chunkText);
            notifyListeners();
          }
        },
      );

      final idx = _messages.indexWhere((m) => m.id == assistantId);
      if (idx >= 0) {
        _messages[idx] = msg.ChatMessage(
          id: assistantId,
          role: msg.MessageRole.assistant,
          text: response.answer,
          sources: response.sources
              .map((s) => msg.ChatSource(
                    type: s.type,
                    url: s.url,
                    title: s.title,
                    path: s.path,
                  ))
              .toList(),
        );
      }
      _status = ChatStatus.idle;
      _errorMessage = null;
    } catch (e) {
      _messages.removeWhere((m) => m.id == assistantId);
      _status = ChatStatus.error;
      if (e is ChatApiException && e.isRateLimit) {
        _errorMessage =
            '세션당 질문은 $kMaxQuestionsPerSession회까지 가능합니다. 새로 고침 후 다시 시도해 주세요.';
      } else {
        _errorMessage = e is ChatApiException ? e.message : e.toString();
      }
    }
    notifyListeners();
  }

  /// 재시도
  Future<void> retry() async {
    _errorMessage = null;
    _status = ChatStatus.idle;
    notifyListeners();
    await initSession();
  }

  /// 대화 초기화 (로컬만, 세션 유지)
  void clearMessages() {
    _messages.clear();
    _nextCursor = null;
    _errorMessage = null;
    _status = ChatStatus.idle;
    notifyListeners();
  }

  /// 리소스 다운로드 (GET .../resources/{encodedPath})
  Future<List<int>> getResource(String path) async {
    if (!_sessionReady) throw ChatApiException('Session required');
    return _apiClient.getResource(path);
  }
}
