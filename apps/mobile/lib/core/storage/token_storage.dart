import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  const TokenStorage(this._storage);

  static const _accessKey = 'homeledger_access_token';
  static const _refreshKey = 'homeledger_refresh_token';

  final FlutterSecureStorage _storage;

  Future<void> save({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const TokenStorage(FlutterSecureStorage()),
);
