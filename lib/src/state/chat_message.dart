/// 채팅 메시지 모델
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.sources = const [],
  });

  final String id;
  final MessageRole role;
  final String text;
  final List<ChatSource> sources;

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? text,
    List<ChatSource>? sources,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      sources: sources ?? this.sources,
    );
  }
}

enum MessageRole {
  user,
  assistant,
}

/// 참고 자료 (path로 리소스 조회 API 호출 가능)
class ChatSource {
  const ChatSource({
    required this.type,
    required this.url,
    this.title,
    this.path,
  });

  final String type;
  final String url;
  final String? title;
  final String? path;
}
