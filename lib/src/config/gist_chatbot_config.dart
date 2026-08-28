import 'package:flutter/material.dart';

/// 챗봇 위젯 테마 (light / dark)
enum GistChatbotTheme { light, dark }

/// 챗봇 색상 설정
class GistChatbotColors {
  const GistChatbotColors({
    this.primary = const Color(0xFFDF3326),
    this.button = const Color(0xFFDF3326),
    this.background = const Color(0xFFF8FAFC),
    this.surface = Colors.white,
    this.text = const Color(0xFF1E293B),
    this.textSecondary = const Color(0xFF94A3B8),
    this.border = const Color(0xFFE2E8F0),
    this.userMessageBg = const Color(0xFFDF3326),
    this.assistantMessageBg = Colors.white,
  });

  final Color primary;
  final Color button;
  /// 전체 채팅 영역 배경 (연한 회색)
  final Color background;
  /// 카드/헤더/입력창 배경 (흰색)
  final Color surface;
  final Color text;
  final Color textSecondary;
  final Color border;
  final Color userMessageBg;
  final Color assistantMessageBg;

  GistChatbotColors copyWith({
    Color? primary,
    Color? button,
    Color? background,
    Color? surface,
    Color? text,
    Color? textSecondary,
    Color? border,
    Color? userMessageBg,
    Color? assistantMessageBg,
  }) {
    return GistChatbotColors(
      primary: primary ?? this.primary,
      button: button ?? this.button,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      userMessageBg: userMessageBg ?? this.userMessageBg,
      assistantMessageBg: assistantMessageBg ?? this.assistantMessageBg,
    );
  }
}

/// GIST 챗봇 위젯 설정
class GistChatbotConfig {
  const GistChatbotConfig({
    required this.apiBaseUrl,
    required this.widgetKey,
    this.appId,
    this.accessToken,
    this.theme = GistChatbotTheme.light,
    this.colors = const GistChatbotColors(),
  });

  final String apiBaseUrl;
  final String widgetKey;
  final String? appId;
  final String? accessToken;
  final GistChatbotTheme theme;
  final GistChatbotColors colors;
}
