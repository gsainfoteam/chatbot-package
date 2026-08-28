import 'package:flutter_test/flutter_test.dart';
import 'package:gist_chatbot_flutter/src/session/session_manager.dart';

void main() {
  group('SessionManager (in-memory)', () {
    late SessionManager manager;

    setUp(() {
      manager = SessionManager.inMemory();
    });

    test('loadSession returns null when empty', () async {
      expect(await manager.loadSession(), isNull);
    });

    test('saveSession and loadSession roundtrip', () async {
      await manager.saveSession('token123', 3600);
      expect(await manager.loadSession(), 'token123');
    });

    test('clearSession removes token', () async {
      await manager.saveSession('token123', 3600);
      await manager.clearSession();
      expect(await manager.loadSession(), isNull);
    });
  });
}
