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

/// 답변 피드백 값 (문제 해결 여부)
enum FeedbackRating { good, bad }

extension FeedbackRatingApi on FeedbackRating {
  String get apiValue => this == FeedbackRating.good ? 'GOOD' : 'BAD';

  static FeedbackRating? tryParse(String? value) {
    switch (value) {
      case 'GOOD':
        return FeedbackRating.good;
      case 'BAD':
        return FeedbackRating.bad;
    }
    return null;
  }
}

/// 서버 메시지 DTO
class ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.role,
    required this.content,
    this.feedback,
    this.createdAt,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: json['id'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      feedback: FeedbackRatingApi.tryParse(json['feedback'] as String?),
      createdAt: json['createdAt'] as String?,
    );
  }

  final String id;
  final String role;
  final String content;
  final FeedbackRating? feedback;
  final String? createdAt;
}

/// 대화 내역 조회 응답
class GetMessagesResponse {
  const GetMessagesResponse({required this.messages, this.nextCursor});

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

/// 채팅 메시지 전송 요청
class SendChatRequest {
  const SendChatRequest({required this.question});

  final String question;

  Map<String, dynamic> toJson() => {'question': question};
}

/// 참고 자료
class ChatSource {
  const ChatSource({required this.type, required this.url, this.title});

  /// 'url' | 'image'
  final String type;
  final String url;
  final String? title;

  bool get isImage => type == 'image';
}

/// 스트림 완료 후 최종 응답
class SendChatResponse {
  const SendChatResponse({required this.answer, this.sources = const []});

  final String answer;
  final List<ChatSource> sources;
}

/// SSE 스트림의 resources 이벤트 원본 항목
class RawResource {
  const RawResource({required this.url, this.path, this.formats = const []});

  factory RawResource.fromJson(Map<String, dynamic> json) {
    return RawResource(
      url: json['url'] as String? ?? '',
      path: json['path'] as String?,
      formats: (json['formats'] as List<dynamic>? ?? [])
          .map((f) => f.toString().toLowerCase())
          .toList(),
    );
  }

  final String url;
  final String? path;
  final List<String> formats;
}

/// 웹 위젯과 동일한 규칙으로 리소스를 출처로 변환한다.
/// resourceCenterUrl이 있으면 `{base}/resource/{cleanPath}` 형태의 URL을 조립하고,
/// 없으면 원본 url을 그대로 사용한다.
ChatSource resolveSource(RawResource resource, {String? resourceCenterUrl}) {
  final url = resource.url;

  var path = url;
  final parsed = Uri.tryParse(url);
  if (parsed != null && parsed.hasAuthority) {
    path = parsed.path;
  }
  var cleanPath = path.startsWith('/') ? path.substring(1) : path;

  final lower = cleanPath.toLowerCase();
  final hasExt = lower.endsWith('.pdf') || lower.endsWith('.png');
  if (!hasExt) {
    if (resource.formats.contains('png')) {
      cleanPath = '$cleanPath.png';
    } else {
      cleanPath = '$cleanPath.pdf';
    }
  }

  final finalUrl = resourceCenterUrl != null && resourceCenterUrl.isNotEmpty
      ? '${resourceCenterUrl.endsWith('/') ? resourceCenterUrl.substring(0, resourceCenterUrl.length - 1) : resourceCenterUrl}/resource/$cleanPath'
      : url;
  final isImage = cleanPath.toLowerCase().endsWith('.png');

  var title = resource.path;
  if (title == null || title.isEmpty) {
    final parts = cleanPath.split('/');
    var fileName = parts.isNotEmpty ? parts.last : '참고자료';
    if (fileName.isEmpty) fileName = '참고자료';
    fileName = Uri.decodeComponent(
      fileName,
    ).replaceAll(RegExp(r'\.(pdf|png|jpg|jpeg)$', caseSensitive: false), '');
    title = fileName.length > 20 ? '${fileName.substring(0, 20)}...' : fileName;
  }

  return ChatSource(
    type: isImage ? 'image' : 'url',
    url: finalUrl,
    title: title,
  );
}
