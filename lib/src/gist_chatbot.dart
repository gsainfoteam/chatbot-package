import 'package:flutter/material.dart';

import 'config/gist_chatbot_config.dart';
import 'state/chat_controller.dart';
import 'widgets/chat_panel.dart';

/// GIST 챗봇 진입점.
///
/// 트리거 UI는 제공하지 않는다. 앱이 자체 버튼/메뉴에서 [open]을 호출해
/// 챗봇 패널을 연다. 인스턴스가 살아 있는 동안 대화가 유지된다.
///
/// ```dart
/// final chatbot = GistChatbot(
///   config: GistChatbotConfig(
///     apiBaseUrl: 'https://api.example.com/api',
///     widgetKey: 'wk_live_xxx',
///   ),
/// );
///
/// // 아무 위젯에서나:
/// onPressed: () => chatbot.open(context)
/// ```
class GistChatbot {
  GistChatbot({required this.config});

  final GistChatbotConfig config;

  ChatController? _controller;
  NavigatorState? _navigator;
  Route<void>? _route;

  /// 패널이 열려 있는지 여부
  bool get isOpen => _route != null;

  /// 챗봇 패널을 연다. 이미 열려 있으면 무시된다.
  Future<void> open(BuildContext context) async {
    if (isOpen) return;
    _controller ??= ChatController(config: config);

    final navigator = Navigator.of(context, rootNavigator: true);
    _navigator = navigator;

    final route = PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ChatPanel(
          config: config,
          controller: _controller!,
          onClose: close,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 웹 위젯과 동일: opacity + translateY(8px) + scale(0.98)
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.01),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
    );
    _route = route;

    await navigator.push(route);
    // pop 완료 (close() 또는 뒤로가기)
    _route = null;
    _navigator = null;
  }

  /// 챗봇 패널을 닫는다. 대화 상태는 유지된다.
  void close() {
    final route = _route;
    if (route == null) return;
    _navigator?.removeRoute(route);
    _route = null;
    _navigator = null;
  }

  /// 대화와 리소스를 정리한다. 이후 [open] 시 새 대화로 시작한다.
  void dispose() {
    close();
    _controller?.dispose();
    _controller = null;
  }
}
