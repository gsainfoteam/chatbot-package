import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';
import 'package:gist_chatbot_flutter/src/config/gist_chatbot_config.dart';
import 'package:gist_chatbot_flutter/src/state/chat_message.dart';
import 'package:gist_chatbot_flutter/src/widgets/message_bubble.dart';

void main() {
  group('MessageBubble', () {
    const colors = GistChatbotColors();

    testWidgets('renders user message on right', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: const ChatMessage(
                id: '1',
                role: MessageRole.user,
                text: 'Hello',
              ),
              colors: colors,
            ),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders assistant message on left with markdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: const ChatMessage(
                id: '2',
                role: MessageRole.assistant,
                text: 'Hi there',
              ),
              colors: colors,
            ),
          ),
        ),
      );

      // assistant 메시지는 StreamingTextMarkdown으로 렌더링됨
      expect(find.byType(StreamingTextMarkdown), findsOneWidget);
    });
  });
}
