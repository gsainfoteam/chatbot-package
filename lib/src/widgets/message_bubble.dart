import 'package:flutter/material.dart';
import 'package:flutter_streaming_text_markdown/flutter_streaming_text_markdown.dart';

import '../config/gist_chatbot_config.dart';
import '../state/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.colors,
    this.onSourceTap,
  });

  final ChatMessage message;
  final GistChatbotColors colors;
  final void Function(ChatSource source)? onSourceTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? colors.primary.withValues(alpha: 0.10)
              : colors.assistantMessageBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isUser
                ? colors.primary.withValues(alpha: 0.25)
                : colors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUser)
              Text(
                message.text,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 14,
                  height: 1.5,
                ),
              )
            else
              StreamingTextMarkdown.claude(
                text: message.text,
                markdownEnabled: true,
                theme: StreamingTextTheme(
                  textStyle: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: message.sources
                      .map(
                        (s) => _SourceBadge(
                          source: s,
                          colors: colors,
                          onTap: onSourceTap,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source, required this.colors, this.onTap});

  final ChatSource source;
  final GistChatbotColors colors;
  final void Function(ChatSource source)? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap?.call(source),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link, size: 12, color: colors.text),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                source.title ?? source.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 10, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
