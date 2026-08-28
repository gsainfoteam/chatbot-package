import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/gist_chatbot_config.dart';

/// 패널 헤더: 로고 + 타이틀 + Beta + Powered by / 신고 · 안내 · 닫기 (웹 위젯과 동일)
class ChatHeader extends StatelessWidget {
  const ChatHeader({super.key, required this.config, required this.onClose});

  final GistChatbotConfig config;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = config.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
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
                    Flexible(
                      child: Text(
                        'GIST 챗봇',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: colors.text,
                        ),
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
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Powered by',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1,
                        letterSpacing: -0.2,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse('https://letsur.ai'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: SvgPicture.asset(
                        'packages/gist_chatbot_flutter/assets/images/letsur_logo.svg',
                        height: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.flag_outlined,
            tooltip: '신고',
            color: colors.textSecondary,
            onTap: () => launchUrl(
              Uri.parse(config.reportUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          _DisclaimerButton(colors: colors),
          _HeaderIconButton(
            icon: Icons.close,
            tooltip: '닫기',
            color: colors.textSecondary,
            onTap: onClose,
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
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

/// 면책 안내: 탭하면 툴팁 표시 (웹 위젯의 Info 툴팁)
class _DisclaimerButton extends StatelessWidget {
  const _DisclaimerButton({required this.colors});

  final GistChatbotColors colors;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 3),
      preferBelow: true,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.primary.withValues(alpha: 0.08),
          Colors.white,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withValues(alpha: 0.20)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      textStyle: TextStyle(fontSize: 11, height: 1.5, color: colors.text),
      message: '챗봇의 답변은 부정확할 수 있으니\n공식 자료를 다시 한 번 확인해 주세요.',
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(Icons.info_outline, size: 18, color: colors.textSecondary),
      ),
    );
  }
}
