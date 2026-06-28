import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/session_controller.dart';
import '../../features/households/presentation/active_household_provider.dart';
import '../../features/items/data/home_item_cache.dart';
import '../../features/items/data/home_item_repository.dart';
import '../../features/maintenance/data/maintenance_repository.dart';
import '../../features/maintenance/data/maintenance_task_cache.dart';
import '../config/app_config.dart';
import '../network/api_client.dart';

final householdScopedHomeItemRepositoryProvider = Provider<HomeItemRepository>((ref) {
  final householdId = ref.watch(activeHouseholdIdProvider);
  final session = ref.watch(sessionControllerProvider).valueOrNull;
  final config = ref.watch(appConfigProvider);
  if (householdId == null || session == null || config.useMockData) {
    return ref.watch(homeItemRepositoryProvider);
  }
  return RemoteHomeItemRepository(
    ref.watch(apiClientProvider),
    HomeItemCache(householdId: householdId, userId: session.userId),
  );
});

final householdScopedMaintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final householdId = ref.watch(activeHouseholdIdProvider);
  final session = ref.watch(sessionControllerProvider).valueOrNull;
  final config = ref.watch(appConfigProvider);
  if (householdId == null || session == null || config.useMockData) {
    return ref.watch(maintenanceRepositoryProvider);
  }
  return RemoteMaintenanceRepository(
    ref.watch(apiClientProvider),
    MaintenanceTaskCache(householdId: householdId, userId: session.userId),
  );
});
