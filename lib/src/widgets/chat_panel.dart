import 'dart:ui';

import 'package:flutter/material.dart';

import '../config/gist_chatbot_config.dart';
import '../state/chat_controller.dart';
import 'chat_header.dart';
import 'chat_screen.dart';

/// 챗봇 패널: 라운드 카드 + 헤더 + 채팅 화면 (웹 위젯의 모바일 레이아웃과 동일)
///
/// 화면 하단에 배치되며 너비는 화면-24px, 높이는 가용 영역의 85%.
class ChatPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = config.colors;
    final mq = MediaQuery.of(context);
    final availableHeight =
        mq.size.height -
        mq.padding.top -
        mq.padding.bottom -
        mq.viewInsets.bottom;
    final panelHeight = (availableHeight * 0.85).clamp(320.0, availableHeight);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 배경 dim + blur, 탭 시 닫기
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: Colors.black26),
              ),
            ),
          ),
          SafeArea(
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
                            ChatHeader(config: config, onClose: onClose),
                            Expanded(
                              child: ChatScreen(
                                controller: controller,
                                config: config,
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
        ],
      ),
    );
  }
}
