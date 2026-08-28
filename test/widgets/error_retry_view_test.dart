import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gist_chatbot_flutter/src/widgets/error_retry_view.dart';

void main() {
  group('ErrorRetryView', () {
    testWidgets('shows message and retry button', (tester) async {
      var retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRetryView(
              message: 'Something went wrong',
              onRetry: () => retryCount++,
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pump();

      expect(retryCount, 1);
    });
  });
}
