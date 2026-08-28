import 'package:flutter/material.dart';

import '../config/gist_chatbot_config.dart';
import '../state/chat_controller.dart';
import 'chatbot_overlay.dart';

enum ChatbotPosition { left, right }

class GistChatbotLauncher extends StatefulWidget {
  const GistChatbotLauncher({
    super.key,
    required this.config,
    this.position = ChatbotPosition.right,
    this.offset = 18,
    this.size = 56,
  });

  final GistChatbotConfig config;
  final ChatbotPosition position;
  final double offset;
  final double size;

  @override
  State<GistChatbotLauncher> createState() => _GistChatbotLauncherState();
}

class _GistChatbotLauncherState extends State<GistChatbotLauncher> {
  bool _isOpen = false;
  late ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatController(config: widget.config);
  }

  @override
  void didUpdateWidget(GistChatbotLauncher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _controller = ChatController(config: widget.config);
    }
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final btnColor = widget.config.colors.button;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final fabBottom = (bottomPadding > 0 ? bottomPadding : widget.offset) + 8;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (_isOpen)
          Positioned.fill(
            child: ChatbotOverlay(
              config: widget.config,
              controller: _controller,
              onClose: () => setState(() => _isOpen = false),
              bottomReservedHeight: fabBottom + widget.size + 2,
            ),
          ),
        Positioned(
          left: widget.position == ChatbotPosition.left ? widget.offset : null,
          right:
              widget.position == ChatbotPosition.right ? widget.offset : null,
          bottom: fabBottom,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: btnColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: btnColor.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: InkWell(
                onTap: _toggle,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Icon(
                    _isOpen ? Icons.close_rounded : Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: widget.size * 0.45,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
