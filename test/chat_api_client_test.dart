import 'package:flutter_test/flutter_test.dart';
import 'package:gist_chatbot_flutter/src/api/chat_api_client.dart';
import 'package:gist_chatbot_flutter/src/api/chat_api_types.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ChatApiClient', () {
    test('createSession returns session on success', () async {
      final client = ChatApiClient(
        baseUrl: 'https://api.example.com',
        client: _MockClient(
          (_) async =>
              http.Response('{"sessionToken":"tok","expiresIn":3600}', 200),
        ),
      );

      final response = await client.createSession(
        const CreateSessionRequest(widgetKey: 'wk', appId: 'com.example.app'),
      );

      expect(response.sessionToken, 'tok');
      expect(response.expiresIn, 3600);
    });

    test('createSession surfaces the server message for a bad key', () async {
      final client = ChatApiClient(
        baseUrl: 'https://api.example.com',
        client: _MockClient(
          (_) async => http.Response(
            '{"message":"Widget key not found","error":"Not Found","statusCode":404}',
            404,
          ),
        ),
      );

      try {
        await client.createSession(
          const CreateSessionRequest(widgetKey: 'wk_bad', appId: 'com.a.b'),
        );
        fail('should throw');
      } on ChatApiException catch (e) {
        expect(e.statusCode, 404);
        expect(e.message, 'Widget key not found');
      }
    });

    test('createSession parses array validation messages', () async {
      final client = ChatApiClient(
        baseUrl: 'https://api.example.com',
        client: _MockClient(
          (_) async => http.Response(
            '{"statusCode":400,"message":["widgetKey should not be empty"],"error":"Bad Request"}',
            400,
          ),
        ),
      );

      try {
        await client.createSession(
          const CreateSessionRequest(widgetKey: '', appId: 'com.a.b'),
        );
        fail('should throw');
      } on ChatApiException catch (e) {
        expect(e.statusCode, 400);
        expect(e.message, 'widgetKey should not be empty');
      }
    });

    test('createSession throws on error', () async {
      final client = ChatApiClient(
        baseUrl: 'https://api.example.com',
        client: _MockClient((_) async => http.Response('error', 500)),
      );

      expect(
        () => client.createSession(
          const CreateSessionRequest(widgetKey: 'wk', appId: 'com.example.app'),
        ),
        throwsA(isA<ChatApiException>()),
      );
    });
  });
}

class _MockClient extends http.BaseClient {
  _MockClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
    );
  }
}
