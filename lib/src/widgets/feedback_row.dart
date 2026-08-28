import 'package:flutter/material.dart';

import '../config/gist_chatbot_config.dart';
import '../state/chat_message.dart';

/// 답변 피드백 행: 👍 👎 + 안내 문구 (웹 위젯과 동일)
class FeedbackRow extends StatelessWidget {
  const FeedbackRow({
    super.key,
    required this.message,
    required this.colors,
    required this.disabled,
    required this.onFeedback,
  });

  final ChatMessage message;
  final GistChatbotColors colors;
  final bool disabled;
  final void Function(FeedbackRating rating) onFeedback;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          _FeedbackButton(
            rating: FeedbackRating.good,
            selected: message.feedback == FeedbackRating.good,
            disabled: disabled,
            colors: colors,
            onTap: () => onFeedback(FeedbackRating.good),
          ),
          const SizedBox(width: 2),
          _FeedbackButton(
            rating: FeedbackRating.bad,
            selected: message.feedback == FeedbackRating.bad,
            disabled: disabled,
            colors: colors,
            onTap: () => onFeedback(FeedbackRating.bad),
          ),
          const SizedBox(width: 4),
          if (message.regeneratedAnswer)
            Text(
              '다시 생성된 답변',
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            )
          else if (message.feedback == null)
            Text(
              '답변이 도움이 되었나요?',
              style: TextStyle(fontSize: 10, color: colors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.rating,
    required this.selected,
    required this.disabled,
    required this.colors,
    required this.onTap,
  });

  final FeedbackRating rating;
  final bool selected;
  final bool disabled;
  final GistChatbotColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = rating == FeedbackRating.good
        ? Icons.thumb_up_outlined
        : Icons.thumb_down_outlined;
    final label = rating == FeedbackRating.good ? '도움이 됐어요' : '도움이 안 됐어요';

    return Tooltip(
      message: label,
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Material(
          color: selected
              ? colors.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: disabled ? null : onTap,
            child: SizedBox(
              width: 24,
              height: 24,
              child: Icon(
                icon,
                size: 14,
                color: selected ? colors.primary : colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
