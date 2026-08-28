import 'package:flutter/material.dart';

import '../config/gist_chatbot_config.dart';
import '../state/chat_message.dart';
import 'message_bubble.dart';

class MessageList extends StatefulWidget {
  const MessageList({
    super.key,
    required this.messages,
    required this.colors,
    this.isLoading = false,
    this.loadingWidget,
    this.onSourceTap,
    this.hasMoreHistory = false,
    this.onLoadMoreHistory,
  });

  final List<ChatMessage> messages;
  final GistChatbotColors colors;
  final bool isLoading;
  final Widget? loadingWidget;
  final void Function(ChatSource source)? onSourceTap;
  final bool hasMoreHistory;
  final VoidCallback? onLoadMoreHistory;

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMoreHistory ||
        _loadingMore ||
        widget.onLoadMoreHistory == null) {
      return;
    }
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadingMore = true;
      widget.onLoadMoreHistory?.call();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadingMore = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.messages.length + (widget.isLoading ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (widget.isLoading && index == 0) {
          return widget.loadingWidget ??
              _TypingBubble(colors: widget.colors);
        }
        final msgIndex = widget.isLoading ? index - 1 : index;
        final message =
            widget.messages[widget.messages.length - 1 - msgIndex];
        return MessageBubble(
          message: message,
          colors: widget.colors,
          onSourceTap: widget.onSourceTap,
        );
      },
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble({required this.colors});

  final GistChatbotColors colors;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.colors.assistantMessageBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.colors.border),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i * 0.3;
                final t = (_controller.value - delay).clamp(0.0, 1.0);
                final opacity = 0.3 + 0.7 * (0.5 + 0.5 * _wave(t));
                return Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.colors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  double _wave(double t) {
    return (t < 0.5) ? (t * 2) : (2 - t * 2);
  }
}
