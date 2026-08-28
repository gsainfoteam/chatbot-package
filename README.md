# gist_chatbot_flutter

A Flutter package for the GIST chatbot - the same chat experience as the web widget, inside your app.

[한국어 문서 (Korean)](doc/README.ko.md)

## Features

- Chat UI mirroring the GIST chatbot web widget (header, frequent questions, bubbles, source badges/images)
- Markdown answers with SSE streaming
- Stop button while streaming (partial answers are kept)
- Staged loading messages with a shimmer indicator
- Answer feedback (helpful / not helpful) with a one-time regeneration on negative feedback
- Rate-limit banner with a live retry countdown (5 questions per session)
- Session persistence via SharedPreferences
- Sources open in the external browser

## Installation

```yaml
dependencies:
  gist_chatbot_flutter: ^0.1.1
```

## Usage

The package does not ship a trigger UI (no floating button).
Create a `GistChatbot` instance and call `open()` from any widget of your own.

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
      // appId is resolved automatically via package_info_plus when omitted
      // (Android applicationId / iOS bundle id)
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

- `open(context)` — opens the chatbot panel. The conversation is kept while the instance is alive.
- `close()` — closes the panel (back button, barrier tap, and the header ✕ also close it).
- `isOpen` — whether the panel is currently shown.
- `dispose()` — releases the conversation and resources.

## Configuration (GistChatbotConfig)

| Field               | Required | Description                                                              |
| ------------------- | -------- | ------------------------------------------------------------------------ |
| `widgetKey`         | Yes      | Widget key issued from the dashboard (e.g. `wk_live_xxx`)                |
| `apiBaseUrl`        | No       | Backend API base URL. Defaults to production; override for dev only     |
| `resourceCenterUrl` | No       | Base URL for source resources. Defaults to the production resource center |
| `appId`             | No       | App identifier. Resolved via package_info_plus when null                 |
| `accessToken`       | No       | Optional auth token (e.g. OAuth)                                         |
| `reportUrl`         | No       | URL opened by the report button in the header                            |
| `colors`            | No       | Color customization (same palette as the web widget's CSS variables)     |

Only the widget key is required. Your app's bundle id (iOS) / applicationId (Android)
must be registered on the chatbot dashboard; unregistered apps get a guidance message
in the chat.

## API (app-specific spec)

- `POST /api/v1/widget/auth/session` — issue a session (body: widgetKey, clientType: "app", appId)
- `GET /api/v1/widget/messages` — fetch messages (used to attach server message ids after streaming)
- `POST /api/v1/widget/messages/chat/stream` — ask a question (SSE streaming)
- `POST /api/v1/widget/messages/{id}/regenerate/stream` — regenerate an answer (SSE streaming)
- `PUT /api/v1/widget/messages/{id}/feedback` — rate an answer (rating: GOOD | BAD)

Each session allows up to **5 user questions**. When exceeded, a banner shows the
remaining time until a new session can be issued.

## License

MIT
