import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/gist_chatbot_config.dart';
import '../state/chat_controller.dart';
import 'chat_screen.dart';

class ChatbotOverlay extends StatefulWidget {
  const ChatbotOverlay({
    super.key,
    required this.config,
    required this.controller,
    required this.onClose,
    this.bottomReservedHeight = 80,
    this.topReservedHeight = 72,
    this.heightFraction = 0.78,
  });

  final GistChatbotConfig config;
  final ChatController controller;
  final VoidCallback onClose;
  /// FAB 등 하단 위젯 위에 시트가 오도록 남겨둘 높이(px).
  final double bottomReservedHeight;
  /// 앱 헤더 등과 겹치지 않도록 상단에 남겨둘 높이(px).
  final double topReservedHeight;
  /// 사용 가능 높이 대비 시트 높이 비율 (0~1). 낮을수록 짧은 시트.
  final double heightFraction;

  @override
  State<ChatbotOverlay> createState() => _ChatbotOverlayState();
}

class _ChatbotOverlayState extends State<ChatbotOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animController.reverse().then((_) {
      if (mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.config.colors;
    final mq = MediaQuery.of(context);
    const inset = 12.0;
    final reserved = widget.bottomReservedHeight;
    final topReserved = widget.topReservedHeight;
    final availableHeight = mq.size.height -
        mq.padding.top -
        mq.padding.bottom -
        inset * 2 -
        reserved -
        topReserved;
    final rawHeight = availableHeight * widget.heightFraction;
    final sheetHeight = rawHeight.clamp(320.0, availableHeight);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: _handleClose,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(color: Colors.black26),
              ),
            ),
          ),
          Positioned(
            left: inset,
            right: inset,
            bottom: reserved,
            height: sheetHeight,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    border: Border.all(color: colors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x38000000),
                        blurRadius: 40,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    child: Column(
                      children: [
                        _buildHeader(colors),
                        Expanded(
                          child: ChatScreen(
                            controller: widget.controller,
                            config: widget.config,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(GistChatbotColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'packages/gist_chatbot_flutter/assets/images/logo.svg',
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'GIST 챗봇',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        color: colors.text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: colors.primary.withValues(alpha: 0.10),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        'Beta',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colors.primary,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '궁금한 내용을 질문해보세요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.close,
            tooltip: '닫기',
            color: colors.textSecondary,
            onTap: _handleClose,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}
