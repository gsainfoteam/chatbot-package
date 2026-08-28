import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/gist_chatbot_config.dart';
import '../state/chat_controller.dart';
import 'chat_header.dart';
import 'chat_screen.dart';

/// 챗봇 패널: 라운드 카드 + 헤더 + 채팅 화면 (웹 위젯의 모바일 레이아웃과 동일)
///
/// 화면 하단에 배치되며 너비는 화면-24px, 높이는 가용 영역의 85%.
///
/// 전환 효과는 라우트 애니메이션을 받아 레이어별로 나눠 적용한다:
/// 배경(dim+blur)은 항상 풀스크린을 덮은 채 강도만 fade in/out 하고,
/// slide/scale은 패널 카드에만 적용해 중간 상태에서도 상단이 비지 않는다.
class ChatPanel extends StatefulWidget {
  const ChatPanel({
    super.key,
    required this.config,
    required this.controller,
    required this.onClose,
  });

  final GistChatbotConfig config;
  final ChatController controller;
  final VoidCallback onClose;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  Animation<double>? _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_t == null) {
      final routeAnimation = ModalRoute.of(context)?.animation;
      _t = routeAnimation == null
          ? const AlwaysStoppedAnimation(1)
          : CurvedAnimation(
              parent: routeAnimation,
              curve: Curves.easeOut,
              reverseCurve: Curves.easeIn,
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.config.colors;
    final mq = MediaQuery.of(context);
    final availableHeight =
        mq.size.height -
        mq.padding.top -
        mq.padding.bottom -
        mq.viewInsets.bottom;
    final panelHeight = (availableHeight * 0.85).clamp(320.0, availableHeight);
    final t = _t!;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 배경 dim + blur (탭 시 닫기): 항상 풀스크린, 강도만 전환에 연동
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              child: AnimatedBuilder(
                animation: t,
                builder: (context, _) {
                  final v = t.value;
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2 * v, sigmaY: 2 * v),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.26 * v),
                    ),
                  );
                },
              ),
            ),
          ),
          // 패널 카드: fade + 살짝 위로 + scale(0.98→1)
          FadeTransition(
            opacity: t,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(t),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(t),
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: SizedBox(
                          height: panelHeight,
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(24),
                              ),
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
                              borderRadius: const BorderRadius.all(
                                Radius.circular(24),
                              ),
                              child: Column(
                                children: [
                                  ChatHeader(
                                    config: widget.config,
                                    onClose: widget.onClose,
                                  ),
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
