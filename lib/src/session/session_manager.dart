import 'package:shared_preferences/shared_preferences.dart';

const _keyToken = 'gist_chatbot_session_token';
const _keyExpiresAt = 'gist_chatbot_session_expires_at';

/// 세션 토큰 저장/복원 관리
class SessionManager {
  SessionManager({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized && _prefs != null) return;
    _prefs ??= await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// 세션 토큰 저장
  Future<void> saveSession(String token, int expiresInSeconds) async {
    await _ensureInitialized();
    await _prefs!.setString(_keyToken, token);
    final expiresAt =
        DateTime.now().millisecondsSinceEpoch + expiresInSeconds * 1000;
    await _prefs!.setString(_keyExpiresAt, expiresAt.toString());
  }

  /// 세션 토큰 로드 (만료 시 null)
  Future<String?> loadSession() async {
    await _ensureInitialized();
    final token = _prefs!.getString(_keyToken);
    final expiresAtStr = _prefs!.getString(_keyExpiresAt);

    if (token == null || expiresAtStr == null) return null;

    final expiresAt = int.tryParse(expiresAtStr);
    if (expiresAt == null ||
        DateTime.now().millisecondsSinceEpoch > expiresAt) {
      await clearSession();
      return null;
    }

    return token;
  }

  /// 세션 만료 시각(ms). 없으면 null
  Future<int?> expiresAt() async {
    await _ensureInitialized();
    final expiresAtStr = _prefs!.getString(_keyExpiresAt);
    if (expiresAtStr == null) return null;
    return int.tryParse(expiresAtStr);
  }

  /// 세션 토큰 삭제
  Future<void> clearSession() async {
    await _ensureInitialized();
    await _prefs!.remove(_keyToken);
    await _prefs!.remove(_keyExpiresAt);
  }

  /// 테스트용: 인메모리 스토어
  static SessionManager inMemory() {
    return _InMemorySessionManager();
  }
}

class _InMemorySessionManager extends SessionManager {
  String? _token;
  int? _expiresAt;

  @override
  Future<void> saveSession(String token, int expiresInSeconds) async {
    _token = token;
    _expiresAt =
        DateTime.now().millisecondsSinceEpoch + expiresInSeconds * 1000;
  }

  @override
  Future<String?> loadSession() async {
    if (_token == null || _expiresAt == null) return null;
    if (DateTime.now().millisecondsSinceEpoch > _expiresAt!) {
      _token = null;
      _expiresAt = null;
      return null;
    }
    return _token;
  }

  @override
  Future<int?> expiresAt() async => _expiresAt;

  @override
  Future<void> clearSession() async {
    _token = null;
    _expiresAt = null;
  }
}
