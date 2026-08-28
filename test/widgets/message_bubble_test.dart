import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gist_chatbot_flutter/src/config/gist_chatbot_config.dart';
import 'package:gist_chatbot_flutter/src/state/chat_message.dart';
import 'package:gist_chatbot_flutter/src/widgets/message_bubble.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  group('MessageBubble', () {
    const colors = GistChatbotColors();

    testWidgets('renders user message as plain text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: ChatMessage(
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
      expect(find.byType(GptMarkdown), findsNothing);
    });

    testWidgets('renders assistant message with markdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: ChatMessage(
                id: '2',
                role: MessageRole.assistant,
                text: 'Hi there',
              ),
              colors: colors,
            ),
          ),
        ),
      );

      expect(find.byType(GptMarkdown), findsOneWidget);
    });

    testWidgets('shows loading indicator while streaming placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: ChatMessage(
                id: '3',
                role: MessageRole.assistant,
                text: '',
              ),
              colors: colors,
              isLoadingPlaceholder: true,
              loadingMessage: '자료를 찾아보는 중',
            ),
          ),
        ),
      );

      expect(find.text('자료를 찾아보는 중'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
