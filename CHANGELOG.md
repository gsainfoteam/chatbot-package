## 0.1.1

- Upgrade package_info_plus to ^10.2.1 (also restores WASM compatibility)
- English package documentation; Korean version moved to doc/README.ko.md

## 0.1.0

- Full rewrite to mirror the web widget's (chatbot-fe) design and UX
- New trigger API: the fixed floating button is gone; apps call `GistChatbot.open(context)` from their own widgets
- Frequent questions with separate card labels and full question texts, as on the web
- Staged loading copy with shimmer text and thinking-dots animation
- Stop button while streaming; partial answers are kept
- Answer feedback (GOOD/BAD) with a one-time regeneration on BAD
- Rate-limit (429) banner with a live retry countdown
- Source badges/images open in the external browser (resourceCenterUrl)
- Markdown rendering switched to gpt_markdown
- Widget key validation with clear error messages for setup mistakes
  (invalid key, unregistered app id)
- Service URLs built in: widgetKey is the only required configuration

## 0.0.2

- App-specific API spec: session issuing with clientType=app and appId
  (pageUrl removed); appId resolved via package_info_plus when omitted
- Message history fetching with pagination and resource fetching
- Rate-limit (429) notice; error responses parsed from the message field

## 0.0.1

- Initial release: chat screen widget, message input/list, backend API
  calls (session, chat streaming), session persistence, loading/error
  handling, token injection
