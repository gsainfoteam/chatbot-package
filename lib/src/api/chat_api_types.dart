/// 앱용 세션 발급 요청 (clientType=app, appId 필수)
class CreateSessionRequest {
  const CreateSessionRequest({
    required this.widgetKey,
    this.clientType = 'app',
    required this.appId,
  });

  final String widgetKey;
  final String clientType;
  final String appId;

  Map<String, dynamic> toJson() => {
        'widgetKey': widgetKey,
        'clientType': clientType,
        'appId': appId,
      };
}

/// 세션 발급 응답
class CreateSessionResponse {
  const CreateSessionResponse({
    required this.sessionToken,
    required this.expiresIn,
  });

  factory CreateSessionResponse.fromJson(Map<String, dynamic> json) {
    return CreateSessionResponse(
      sessionToken: json['sessionToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
    );
  }

  final String sessionToken;
  final int expiresIn;
}

/// 대화 내역 조회 응답
class GetMessagesResponse {
  const GetMessagesResponse({
    required this.messages,
    this.nextCursor,
  });

  factory GetMessagesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['messages'] as List<dynamic>? ?? [];
    final messages = list
        .map((e) => ChatMessageDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return GetMessagesResponse(
      messages: messages,
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<ChatMessageDto> messages;
  final String? nextCursor;
}

/// 서버 메시지 DTO
class ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.role,
    required this.content,
    this.metadata,
    this.createdAt,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String?,
    );
  }

  final String id;
  final String role;
  final String content;
  final Map<String, dynamic>? metadata;
  final String? createdAt;
}

/// 메시지 저장 요청 (선택)
class SaveMessageRequest {
  const SaveMessageRequest({
    required this.role,
    required this.content,
    this.metadata,
  });

  final String role;
  final String content;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        if (metadata != null) 'metadata': metadata,
      };
}

/// 채팅 메시지 전송 요청
class SendChatRequest {
  const SendChatRequest({required this.question});

  final String question;

  Map<String, dynamic> toJson() => {'question': question};
}

/// 채팅 메시지 응답 (스트리밍 완료 후)
class SendChatResponse {
  const SendChatResponse({
    required this.answer,
    this.sources = const [],
  });

  factory SendChatResponse.fromJson(Map<String, dynamic> json) {
    final sourcesList = json['sources'] as List<dynamic>?;
    final sources = (sourcesList ?? []).map((s) {
      final m = s as Map<String, dynamic>;
      return ChatSource(
        type: m['type'] as String? ?? 'url',
        url: m['url'] as String? ?? '',
        title: m['title'] as String?,
        path: m['path'] as String?,
      );
    }).toList();

    return SendChatResponse(
      answer: json['answer'] as String? ?? '',
      sources: sources,
    );
  }

  final String answer;
  final List<ChatSource> sources;
}

/// 참고 자료 (path로 리소스 조회 API 호출)
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
  /// 리소스 조회 시 사용할 path (GET .../resources/{encodedPath})
  final String? path;
}
