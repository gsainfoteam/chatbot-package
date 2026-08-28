> English documentation: [README.md](../README.md)

# gist_chatbot_flutter

GIST 챗봇 Flutter 패키지 - 웹 위젯과 동일한 채팅 경험을 앱에서 제공합니다.

앱 전용 API 명세에 맞춰 **appId 기반 세션 발급**, 스트리밍 질의, 답변 피드백/재생성을 지원합니다.

## 기능

- 웹 위젯과 동일한 채팅 UI (헤더, 자주 묻는 질문, 말풍선, 출처 배지/이미지)
- 마크다운 답변 렌더링 + SSE 스트리밍
- 스트리밍 중지 (중지 버튼)
- 로딩 단계 문구 (자료를 찾아보는 중 → 파일을 읽어보는 중 → 조금 더 생각 중)
- 답변 피드백 (도움이 됐어요/안 됐어요) + BAD 시 1회 재생성
- 세션당 질문 5회 제한 시 안내 배너 + 재시도 카운트다운
- 대화 세션 유지 (SharedPreferences)
- 출처 링크/이미지를 외부 브라우저로 열기

## 설치

```yaml
dependencies:
  gist_chatbot_flutter: ^0.1.0
```

## 사용법

패키지는 트리거 UI(플로팅 버튼 등)를 제공하지 않습니다.
`GistChatbot` 인스턴스를 만들고, 앱의 아무 위젯에서나 `open()`을 호출하세요.

```dart
import 'package:flutter/material.dart';
import 'package:gist_chatbot_flutter/gist_chatbot_flutter.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _chatbot = GistChatbot(
    config: const GistChatbotConfig(
      widgetKey: 'wk_live_xxx',
      // appId 생략 시 package_info_plus로 자동 획득 (Android applicationId / iOS Bundle ID)
    ),
  );

  @override
  void dispose() {
    _chatbot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _chatbot.open(context),
        child: const Icon(Icons.chat_bubble_rounded),
      ),
    );
  }
}
```

- `open(context)` — 챗봇 패널을 엽니다. 인스턴스가 살아 있는 동안 대화가 유지됩니다.
- `close()` — 패널을 닫습니다 (뒤로가기/배경 탭/헤더 ✕로도 닫힘).
- `isOpen` — 패널 표시 여부.
- `dispose()` — 대화와 리소스를 정리합니다.

## 설정 (GistChatbotConfig)

| 필드                | 필수 | 설명                                                             |
| ------------------- | ---- | ---------------------------------------------------------------- |
| `widgetKey`         | O    | 위젯 키 (대시보드에서 발급, 예: `wk_live_xxx`)                   |
| `apiBaseUrl`        | X    | 백엔드 API 베이스 URL. 기본값은 운영 서버 (dev 환경에서만 지정)  |
| `resourceCenterUrl` | X    | 출처 리소스 베이스 URL. 기본값은 운영 리소스 센터                |
| `appId`             | X    | 앱 식별자. null이면 package_info_plus로 자동 획득                |
| `accessToken`       | X    | OAuth 등 인증 토큰 (선택)                                        |
| `reportUrl`         | X    | 헤더 신고 버튼 URL (기본: cs.gistory.me)                         |
| `colors`            | X    | 색상 커스터마이징 (웹 위젯 CSS 변수와 동일한 팔레트)             |

위젯 키만 넣으면 됩니다. 앱의 번들 ID(iOS) / applicationId(Android)가 챗봇 대시보드에
등록되어 있어야 하며, 미등록 시 채팅 화면에 안내 문구가 표시됩니다.

## API (앱 전용 명세)

- `POST /api/v1/widget/auth/session` — 세션 발급 (body: widgetKey, clientType: "app", appId)
- `GET /api/v1/widget/messages` — 대화 내역 조회 (스트림 완료 후 서버 메시지 ID 연결에 사용)
- `POST /api/v1/widget/messages/chat/stream` — 챗봇 질의 (SSE 스트리밍)
- `POST /api/v1/widget/messages/{id}/regenerate/stream` — 답변 재생성 (SSE 스트리밍)
- `PUT /api/v1/widget/messages/{id}/feedback` — 답변 피드백 (rating: GOOD | BAD)

세션당 user 질문은 **최대 5회**입니다. 초과 시 안내 배너와 함께 세션 만료까지 남은 시간이 표시됩니다.

## 라이선스

MIT
