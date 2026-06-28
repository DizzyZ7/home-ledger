import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  final options = BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {'Accept': 'application/json'},
  );
  final client = Dio(options);
  final renewalClient = Dio(options);

  client.interceptors.add(
    _AuthInterceptor(
      client: client,
      renewalClient: renewalClient,
      tokenStorage: tokenStorage,
    ),
  );
  ref.onDispose(() {
    client.close();
    renewalClient.close();
  });
  return client;
});

class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor({
    required Dio client,
    required Dio renewalClient,
    required TokenStorage tokenStorage,
  })  : _client = client,
        _renewalClient = renewalClient,
        _tokenStorage = tokenStorage;

  final Dio _client;
  final Dio _renewalClient;
  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final isUnauthorized = error.response?.statusCode == 401;
    final hasAlreadyRetried = request.extra['homeledger_retried'] == true;

    if (!isUnauthorized || hasAlreadyRetried) {
      handler.next(error);
      return;
    }

    final currentAccessToken = await _tokenStorage.readAccessToken();
    final originalAuthorization = request.headers['Authorization'];
    if (currentAccessToken != null && originalAuthorization != 'Bearer $currentAccessToken') {
      await _retryWithAccessToken(request, currentAccessToken, handler, error);
      return;
    }

    final sessionRenewalToken = await _tokenStorage.readRefreshToken();
    if (sessionRenewalToken == null || sessionRenewalToken.isEmpty) {
      handler.next(error);
      return;
    }

    try {
      final response = await _renewalClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': sessionRenewalToken},
      );
      final payload = response.data;
      final renewedAccessToken = payload?['access_token'];
      final renewedRefreshToken = payload?['refresh_token'];
      if (renewedAccessToken is! String || renewedRefreshToken is! String) {
        await _tokenStorage.clear();
        handler.next(error);
        return;
      }

      await _tokenStorage.saveTokens(
        accessToken: renewedAccessToken,
        refreshToken: renewedRefreshToken,
      );
      await _retryWithAccessToken(request, renewedAccessToken, handler, error);
    } on DioException {
      await _tokenStorage.clear();
      handler.next(error);
    }
  }

  Future<void> _retryWithAccessToken(
    RequestOptions request,
    String accessToken,
    ErrorInterceptorHandler handler,
    DioException originalError,
  ) async {
    try {
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.extra['homeledger_retried'] = true;
      final response = await _client.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException {
      handler.next(originalError);
    }
  }
}
