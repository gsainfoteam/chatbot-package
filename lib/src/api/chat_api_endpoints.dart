/// API 엔드포인트 상수
class ChatApiEndpoints {
  ChatApiEndpoints._();

  /// 세션 발급 (앱): POST /api/v1/widget/auth/session
  static const String createSession = 'v1/widget/auth/session';

  /// 대화 내역 조회: GET /api/v1/widget/messages
  static const String getMessages = 'v1/widget/messages';

  /// 메시지 저장 (선택): POST /api/v1/widget/messages
  static const String postMessage = 'v1/widget/messages';

  /// 챗봇 스트리밍: POST /api/v1/widget/messages/chat/stream
  static const String sendChatStream = 'v1/widget/messages/chat/stream';

  /// 리소스 조회: GET /api/v1/widget/messages/resources/{encodedPath}
  static const String resourcesPrefix = 'v1/widget/messages/resources/';
}
