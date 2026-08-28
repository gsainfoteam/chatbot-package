# gist_chatbot_flutter

GIST 챗봇 Flutter 위젯 - 앱 하단 오버레이 형태의 챗봇 패키지

앱 전용 API 명세에 맞춰 **appId 기반 세션 발급**, 대화 내역 조회, 스트리밍 질의, 리소스 조회를 지원합니다.

## 기능

- 챗봇 화면 위젯 (하단 시트 형태)
- 메시지 입력창
- 메시지 리스트 (사용자/어시스턴트 말풍선, 대화 내역 페이징)
- 백엔드 API: 세션 발급(clientType=app, appId), 대화 내역 조회, 채팅 스트리밍, 리소스 조회
- 대화 세션 유지 (SharedPreferences)
- 로딩/에러/재시도 처리
- 세션당 질문 5회 제한 시 429 안내

## 설치

```yaml
dependencies:
  gist_chatbot_flutter: ^0.0.1
```

## 사용법

```dart
import 'package:flutter/material.dart';
import 'package:gist_chatbot_flutter/gist_chatbot_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            YourContent(),
            const GistChatbotLauncher(
              config: GistChatbotConfig(
                apiBaseUrl: 'https://api.example.com/api',
                widgetKey: 'wk_live_xxx',
                // appId 생략 시 package_info_plus로 자동 획득 (Android applicationId / iOS Bundle ID)
                // appId: 'com.company.myapp',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 설정 (GistChatbotConfig)

| 필드          | 필수 | 설명                                                      |
| ------------- | ---- | --------------------------------------------------------- |
| `apiBaseUrl`  | O    | 백엔드 API 베이스 URL (예: `https://api.example.com/api`) |
| `widgetKey`   | O    | 위젯 키 (대시보드에서 발급, 예: `wk_live_xxx`)            |
| `appId`       | X    | 앱 식별자. null이면 package_info_plus로 자동 획득         |
| `accessToken` | X    | OAuth 등 인증 토큰 (선택)                                 |
| `theme`       | X    | light / dark (기본: light)                                |
| `colors`      | X    | 색상 커스터마이징                                         |

## 예시

```dart
GistChatbotLauncher(
  config: GistChatbotConfig(
    apiBaseUrl: 'https://api.example.com/api',
    widgetKey: 'wk_live_xxx',
    appId: 'com.company.myapp',  // 생략 시 자동 획득
    theme: GistChatbotTheme.dark,
  ),
  position: ChatbotPosition.right,
  offset: 18,
  size: 56,
)
```

## API (앱 전용 명세)

- `POST /api/v1/widget/auth/session` — 세션 발급 (body: widgetKey, clientType: "app", appId)
- `GET /api/v1/widget/messages` — 대화 내역 조회 (cursor, limit)
- `POST /api/v1/widget/messages/chat/stream` — 챗봇 질의 (SSE 스트리밍)
- `GET /api/v1/widget/messages/resources/{encodedPath}` — 리소스 조회

세션당 user 질문은 **최대 5회**입니다. 6회째부터 429가 반환되며, 패키지에서 안내 메시지를 표시합니다.

## 라이선스

MIT

기숙사 납입금 언제 내?
