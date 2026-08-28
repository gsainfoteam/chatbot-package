/// API 엔드포인트 상수
class ChatApiEndpoints {
  ChatApiEndpoints._();

  /// 세션 발급 (앱): POST /api/v1/widget/auth/session
  static const String createSession = 'v1/widget/auth/session';

  /// 대화 내역 조회: GET /api/v1/widget/messages
  static const String getMessages = 'v1/widget/messages';

  /// 챗봇 스트리밍: POST /api/v1/widget/messages/chat/stream
  static const String sendChatStream = 'v1/widget/messages/chat/stream';

  /// 답변 재생성 스트리밍: POST /api/v1/widget/messages/{id}/regenerate/stream
  static String regenerateStream(String messageId) =>
      'v1/widget/messages/${Uri.encodeComponent(messageId)}/regenerate/stream';

  /// 답변 피드백: PUT /api/v1/widget/messages/{id}/feedback
  static String feedback(String messageId) =>
      'v1/widget/messages/${Uri.encodeComponent(messageId)}/feedback';
}
