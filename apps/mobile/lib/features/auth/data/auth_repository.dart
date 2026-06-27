import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/user_session.dart';

class AuthRepository {
  AuthRepository(this._client, this._tokenStorage);

  final Dio _client;
  final TokenStorage _tokenStorage;

  Future<UserSession> login({required String email, required String password}) {
    return _authenticate('/auth/login', {'email': email, 'password': password});
  }

  Future<UserSession> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _authenticate('/auth/register', {
      'email': email,
      'password': password,
      'display_name': displayName,
    });
  }

  Future<UserSession> _authenticate(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(path, data: body);
      final data = response.data;
      if (data == null) {
        throw const ApiException('Empty authentication response.');
      }
      await _tokenStorage.save(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      return UserSession.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider)),
);
