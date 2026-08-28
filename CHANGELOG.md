## 0.1.0

* 웹 위젯(chatbot-fe)과 동일한 디자인/UX로 전면 재작성
* 트리거 재설계: 고정 플로팅 버튼 제거, `GistChatbot.open(context)` 메소드 제공
* 자주 묻는 질문: 웹과 동일한 라벨/실제 질문문 분리
* 로딩 단계 문구 + shimmer/thinking dots 애니메이션
* 스트리밍 중지 버튼 (부분 응답 유지)
* 답변 피드백(GOOD/BAD) 및 BAD 시 1회 재생성
* 429 안내 배너 + 재시도 카운트다운
* 출처 배지/이미지 → 외부 브라우저 열기
* 운영 API/리소스 센터 URL 내장: 필수 설정은 widgetKey 하나 (dev 환경만 URL 재정의)
* 마크다운 렌더러를 gpt_markdown으로 교체

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
