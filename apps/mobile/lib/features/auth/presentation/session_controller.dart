import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../dashboard/presentation/item_list_controller.dart';
import '../../households/presentation/active_household_provider.dart';
import '../../households/presentation/household_controller.dart';
import '../../items/data/home_item_cache.dart';
import '../../items/presentation/archived_item_list_controller.dart';
import '../../items/presentation/warranty_overview_provider.dart';
import '../../maintenance/data/maintenance_task_cache.dart';
import '../../maintenance/presentation/maintenance_history_controller.dart';
import '../../maintenance/presentation/maintenance_list_controller.dart';
import '../data/auth_repository.dart';
import '../domain/user_session.dart';
import 'active_user_provider.dart';

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, UserSession?>(SessionController.new);

class SessionController extends AsyncNotifier<UserSession?> {
  @override
  FutureOr<UserSession?> build() async {
    final config = ref.read(appConfigProvider);
    if (config.useMockData) {
      _activateUser(UserSession.demo);
      return UserSession.demo;
    }

    final tokenStorage = ref.read(tokenStorageProvider);
    final token = await tokenStorage.readAccessToken();
    if (token == null) {
      return null;
    }

    final storedSession = await tokenStorage.readSession();
    if (storedSession == null) {
      await tokenStorage.clear();
      return null;
    }

    final session = UserSession(
      userId: storedSession.userId,
      email: storedSession.email,
      displayName: storedSession.displayName,
    );
    _activateUser(session);
    return session;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
    state = result;
    result.whenData(_activateUser);
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            displayName: displayName,
          ),
    );
    state = result;
    result.whenData(_activateUser);
  }

  Future<void> signOut() async {
    try {
      await ref.read(tokenStorageProvider).clear();
    } on Object {}
    await Future.wait([
      HomeItemCache.clearAll(),
      MaintenanceTaskCache.clearAll(),
    ]);
    _resetSessionBoundState();
    state = const AsyncData(null);
  }

  void _activateUser(UserSession session) {
    ref.read(activeUserIdProvider.notifier).state = session.userId;
  }

  void _resetSessionBoundState() {
    ref.read(activeUserIdProvider.notifier).state = null;
    ref.read(activeHouseholdIdProvider.notifier).state = null;
    ref.invalidate(householdControllerProvider);
    ref.invalidate(itemListControllerProvider);
    ref.invalidate(archivedItemListControllerProvider);
    ref.invalidate(warrantyOverviewProvider);
    ref.invalidate(maintenanceListControllerProvider);
    ref.invalidate(maintenanceHistoryProvider);
  }
}
