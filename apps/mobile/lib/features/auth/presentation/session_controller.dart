import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/user_session.dart';

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, UserSession?>(SessionController.new);

class SessionController extends AsyncNotifier<UserSession?> {
  @override
  FutureOr<UserSession?> build() async {
    final config = ref.read(appConfigProvider);
    if (config.useMockData) {
      return UserSession.demo;
    }
    final token = await ref.read(tokenStorageProvider).readAccessToken();
    return token == null ? null : const UserSession(userId: 'restored', email: '', displayName: '');
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            displayName: displayName,
          ),
    );
  }

  Future<void> signOut() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }
}
