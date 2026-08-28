import 'package:flutter/material.dart';

import '../config/gist_chatbot_config.dart';
import '../state/chat_controller.dart';
import 'error_retry_view.dart';
import 'loading_indicator.dart';
import 'message_input.dart';
import 'message_list.dart';
import 'quick_suggestions.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.controller,
    required this.config,
  });

  final ChatController controller;
  final GistChatbotConfig config;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
    widget.controller.initSession();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final config = widget.config;
    final colors = config.colors;

    return Container(
      color: colors.background,
      child: Column(
        children: [
          Expanded(
            child: _buildBody(controller, config),
          ),
          if (controller.sessionReady &&
              controller.status != ChatStatus.error)
            MessageInput(
              onSend: controller.sendMessage,
              colors: colors,
              enabled: controller.status != ChatStatus.sendingMessage,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ChatController controller, GistChatbotConfig config) {
    if (controller.status == ChatStatus.loadingSession) {
      return const LoadingIndicator(message: '세션을 준비하고 있습니다...');
    }

    if (controller.status == ChatStatus.error &&
        controller.messages.isEmpty &&
        controller.errorMessage != null) {
      return ErrorRetryView(
        message: controller.errorMessage!,
        onRetry: controller.retry,
      );
    }

    final isLoading = controller.status == ChatStatus.sendingMessage;
    final hasError =
        controller.status == ChatStatus.error &&
        controller.errorMessage != null;
    final hasMessages = controller.messages.isNotEmpty;

    return Column(
      children: [
        if (hasError)
          _buildErrorBanner(controller),
        if (!hasMessages)
          Expanded(
            child: SingleChildScrollView(
              child: QuickSuggestionsSection(
                onSelect: controller.sendMessage,
              ),
            ),
          )
        else
          Expanded(
            child: MessageList(
              messages: controller.messages,
              colors: config.colors,
              isLoading: isLoading,
              onSourceTap: (source) {
                if (source.path == null) return;
                controller.getResource(source.path!).then((_) {}).catchError((_) {});
              },
              hasMoreHistory: controller.hasMoreHistory,
              onLoadMoreHistory: controller.loadMoreHistory,
            ),
          ),
      ],
    );
  }

  Widget _buildErrorBanner(ChatController controller) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              controller.errorMessage ?? '',
              style: const TextStyle(
                color: Color(0xFF7F1D1D),
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: controller.retry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
