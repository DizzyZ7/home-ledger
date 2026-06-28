import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureKeyValueStore {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  const FlutterSecureKeyValueStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

class StoredSession {
  const StoredSession({
    required this.userId,
    required this.email,
    required this.displayName,
  });

  final String userId;
  final String email;
  final String displayName;

  Map<String, String> toJson() => {
        'user_id': userId,
        'email': email,
        'display_name': displayName,
      };

  factory StoredSession.fromJson(Map<String, dynamic> json) {
    final userId = json['user_id'];
    final email = json['email'];
    final displayName = json['display_name'];
    if (userId is! String || email is! String || displayName is! String) {
      throw const FormatException('Stored session has an invalid shape.');
    }
    return StoredSession(userId: userId, email: email, displayName: displayName);
  }
}

class TokenStorage {
  const TokenStorage(this._storage);

  static const _accessKey = 'homeledger_access_token';
  static const _refreshKey = 'homeledger_refresh_token';
  static const _sessionKey = 'homeledger_session_v1';

  final SecureKeyValueStore _storage;

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required StoredSession session,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<StoredSession?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Stored session is not a JSON object.');
      }
      return StoredSession.fromJson(decoded);
    } on FormatException {
      await _storage.delete(key: _sessionKey);
      return null;
    }
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _sessionKey),
    ]);
  }
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(FlutterSecureKeyValueStore(const FlutterSecureStorage())),
);
