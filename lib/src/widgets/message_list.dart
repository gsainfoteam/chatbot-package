import 'package:flutter/material.dart';

import '../config/gist_chatbot_config.dart';
import '../state/chat_controller.dart';
import '../state/chat_message.dart';
import 'feedback_row.dart';
import 'frequent_questions.dart';
import 'message_bubble.dart';

/// 메시지 리스트: 웰컴 → FAQ → 대화, 스트리밍 시 하단 자동 스크롤 (웹 위젯과 동일)
class MessageList extends StatefulWidget {
  const MessageList({
    super.key,
    required this.controller,
    required this.colors,
  });

  final ChatController controller;
  final GistChatbotColors colors;

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();
  String _scrollSignal = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  /// 메시지 본문/로딩 변화에만 하단 스크롤.
  /// 피드백 등 메타 갱신 시 스크롤하면 화면이 튀므로 제외 (웹과 동일)
  void _onUpdate() {
    final signal = widget.controller.messages
        .map((m) => '${m.id}:${m.text.length}:${m.sources.length}')
        .join('|');
    if (signal != _scrollSignal) {
      _scrollSignal = signal;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final messages = controller.messages;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isStreamingPlaceholder =
            controller.loading &&
            index == messages.length - 1 &&
            message.role == MessageRole.assistant &&
            message.text.isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MessageBubble(
              message: message,
              colors: widget.colors,
              isLoadingPlaceholder: isStreamingPlaceholder,
              loadingMessage: controller.loadingMessage,
            ),
            // 서버에 저장된 assistant 답변에만 피드백 표시
            if (message.role == MessageRole.assistant &&
                message.serverId != null)
              FeedbackRow(
                message: message,
                colors: widget.colors,
                disabled:
                    controller.loading || controller.feedbackBusyId != null,
                onFeedback: (rating) =>
                    controller.submitFeedback(message, rating),
              ),
            // 첫 번째 메시지 뒤에 자주 묻는 질문 표시
            if (index == 0 && controller.showFrequentQuestions)
              FrequentQuestionsSection(
                colors: widget.colors,
                onSelect: controller.sendMessage,
              ),
          ],
        );
      },
    );
  }
}
