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
    test('only the widget key is required; service urls default to prod', () {
      const config = GistChatbotConfig(widgetKey: 'test-key');
      expect(config.widgetKey, 'test-key');
      expect(config.apiBaseUrl, kDefaultApiBaseUrl);
      expect(config.resourceCenterUrl, kDefaultResourceCenterUrl);
      expect(config.accessToken, isNull);
    });

    test('service urls can be overridden for dev environments', () {
      const config = GistChatbotConfig(
        widgetKey: 'test-key',
        apiBaseUrl: 'https://dev.example.com/api',
        resourceCenterUrl: 'https://dev-resource.example.com',
      );
      expect(config.apiBaseUrl, 'https://dev.example.com/api');
      expect(config.resourceCenterUrl, 'https://dev-resource.example.com');
    });
  });
}
