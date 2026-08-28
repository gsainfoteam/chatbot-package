import 'package:flutter_test/flutter_test.dart';
import 'package:gist_chatbot_flutter/gist_chatbot_flutter.dart';

void main() {
  group('GistChatbotConfig', () {
    test('creates config with required fields', () {
      const config = GistChatbotConfig(
        apiBaseUrl: 'https://api.example.com',
        widgetKey: 'test-key',
      );
      expect(config.apiBaseUrl, 'https://api.example.com');
      expect(config.widgetKey, 'test-key');
      expect(config.accessToken, isNull);
    });
  });
}
