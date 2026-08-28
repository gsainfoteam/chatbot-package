import '../api/chat_api_types.dart';

export '../api/chat_api_types.dart' show ChatSource, FeedbackRating;

enum MessageRole { user, assistant }

/// 채팅 메시지 모델
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.sources = const [],
    this.serverId,
    this.feedback,
    this.regeneratedAnswer = false,
  });

  final String id;
  final MessageRole role;
  final String text;
  final List<ChatSource> sources;

  /// 백엔드에 저장된 메시지 ID (피드백/재생성 API 호출용)
  final String? serverId;

  /// 현재 저장된 피드백
  final FeedbackRating? feedback;

  /// 재생성으로 만들어진 답변 (다시 재생성 불가)
  final bool regeneratedAnswer;

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? text,
    List<ChatSource>? sources,
    String? serverId,
    FeedbackRating? feedback,
    bool? regeneratedAnswer,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      sources: sources ?? this.sources,
      serverId: serverId ?? this.serverId,
      feedback: feedback ?? this.feedback,
      regeneratedAnswer: regeneratedAnswer ?? this.regeneratedAnswer,
    );
  }
}
