import 'package:flutter_test/flutter_test.dart';
import 'package:gist_chatbot_flutter/gist_chatbot_flutter.dart';

void main() {
  group('GistChatbot', () {
    test('rejects an empty widget key', () {
      expect(
        () => GistChatbot(
          config: const GistChatbotConfig(
            apiBaseUrl: 'https://api.example.com',
            widgetKey: '',
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rejects a blank api base url', () {
      expect(
        () => GistChatbot(
          config: const GistChatbotConfig(
            apiBaseUrl: '  ',
            widgetKey: 'wk_live_x',
          ),
        ),
        throwsArgumentError,
      );
    });
  });

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
