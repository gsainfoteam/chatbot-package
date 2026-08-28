import 'package:flutter/material.dart';

/// 세션/메시지 로딩 인디케이터
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.message = '불러오는 중...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
