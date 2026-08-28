## 0.0.2

* 앱 전용 API 명세 반영
* 세션 발급: clientType=app, appId (pageUrl 제거)
* appId: Config에 선택 지정, 미지정 시 package_info_plus로 자동 획득
* 대화 내역 조회 (GET /messages, 페이징)
* 리소스 조회 (GET /messages/resources/{path})
* 세션당 질문 5회 제한 시 429 안내 메시지
* 에러 응답 JSON 파싱 (message 필드)

## 0.0.1

* 초기 릴리스
* 챗봇 화면 위젯 (GistChatbotLauncher)
* 메시지 입력창, 메시지 리스트
* 백엔드 API 호출 (세션 생성, 채팅 스트리밍)
* 대화 세션 유지
* 로딩/에러/재시도 처리
* 토큰 주입 지원
