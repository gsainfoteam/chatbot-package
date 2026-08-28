import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/gist_chatbot_config.dart';
import '../state/chat_message.dart';
import 'loading_shimmer.dart';
import 'pressable.dart';

/// 메시지 말풍선 (웹 위젯과 동일: user는 primary 10%/25%, assistant는 흰 배경+테두리)
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.colors,
    this.isLoadingPlaceholder = false,
    this.loadingMessage = '',
  });

  final ChatMessage message;
  final GistChatbotColors colors;

  /// 스트리밍 텍스트가 아직 없을 때 로딩 문구를 표시
  final bool isLoadingPlaceholder;
  final String loadingMessage;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? colors.userMessageBg.withValues(alpha: 0.10)
              : colors.assistantMessageBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser
                ? colors.userMessageBg.withValues(alpha: 0.25)
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
                style: TextStyle(color: colors.text, fontSize: 14, height: 1.4),
              )
            else if (message.text.isEmpty && isLoadingPlaceholder)
              LoadingIndicatorRow(
                message: loadingMessage,
                color: colors.textSecondary,
              )
            else
              _AssistantMarkdown(text: message.text, colors: colors),
            if (message.sources.isNotEmpty)
              _SourcesSection(sources: message.sources, colors: colors),
          ],
        ),
      ),
    );
  }
}

class _AssistantMarkdown extends StatelessWidget {
  const _AssistantMarkdown({required this.text, required this.colors});

  final String text;
  final GistChatbotColors colors;

  @override
  Widget build(BuildContext context) {
    // 헤딩 위계: 웹 위젯(Streamdown)과 동일
    // h1 text-3xl ~ h6 text-sm, 모두 font-semibold
    TextStyle heading(double size) => TextStyle(
      color: colors.text,
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
    return GptMarkdownTheme(
      gptThemeData: GptMarkdownThemeData(
        brightness: Brightness.light,
        h1: heading(30),
        h2: heading(24),
        h3: heading(20),
        h4: heading(18),
        h5: heading(16),
        h6: heading(14),
        linkColor: colors.primary,
        linkHoverColor: colors.primary,
        hrLineColor: colors.border,
        autoAddDividerLineAfterH1: false,
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: colors.text, fontSize: 14, height: 1.4),
        child: GptMarkdown(
          text,
          style: TextStyle(color: colors.text, fontSize: 14, height: 1.4),
          linkBuilder: (context, span, url, style) {
            return GestureDetector(
              onTap: () => launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ),
              child: Text.rich(
                span,
                style: style.copyWith(
                  color: colors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: colors.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 출처 영역: 상단 구분선 + 배지 + 이미지 (웹 위젯과 동일)
class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.sources, required this.colors});

  final List<ChatSource> sources;
  final GistChatbotColors colors;

  @override
  Widget build(BuildContext context) {
    final images = sources.where((s) => s.isImage).toList();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final source in sources.where((s) => !s.isImage))
                _SourceBadge(source: source, colors: colors),
            ],
          ),
          for (final source in images)
            _SourceImage(source: source, colors: colors),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source, required this.colors});

  final ChatSource source;
  final GistChatbotColors colors;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => launchUrl(
        Uri.parse(source.url),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link, size: 12, color: colors.text),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                source.title ?? Uri.tryParse(source.url)?.host ?? source.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new, size: 12, color: colors.text),
          ],
        ),
      ),
    );
  }
}

/// 이미지 출처 (16:9 스켈레톤 → 이미지, 탭 시 외부 브라우저)
class _SourceImage extends StatelessWidget {
  const _SourceImage({required this.source, required this.colors});

  final ChatSource source;
  final GistChatbotColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse(source.url),
          mode: LaunchMode.externalApplication,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            source.url,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return AspectRatio(
                aspectRatio: 16 / 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
