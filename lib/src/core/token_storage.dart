import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT access token and the (rotating) refresh token in the platform secure store
/// (iOS Keychain / Android EncryptedSharedPreferences). Never in plain prefs.
class TokenStorage {
  TokenStorage(this._storage);

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';
  static const String _userKey = 'cached_user';
  final FlutterSecureStorage _storage;

  Future<String?> readAccess() => _storage.read(key: _accessKey);

  Future<String?> readRefresh() => _storage.read(key: _refreshKey);

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  /// The last known profile JSON, kept so a transient `/users/me` failure on startup (offline /
  /// server cold-start) doesn't sign the user out — the cached copy keeps them in.
  Future<String?> readCachedUser() => _storage.read(key: _userKey);

  Future<void> cacheUser(String json) =>
      _storage.write(key: _userKey, value: json);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _userKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(
    // AndroidOptions defaults now use custom ciphers (the old
    // encryptedSharedPreferences flag is deprecated and ignored).
    const FlutterSecureStorage(),
  );
});
