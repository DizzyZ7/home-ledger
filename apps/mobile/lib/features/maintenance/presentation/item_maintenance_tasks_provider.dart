import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/household_scoped_repositories.dart';
import '../domain/maintenance_task.dart';

final itemMaintenanceTasksProvider =
    FutureProvider.autoDispose.family<List<MaintenanceTask>, String>((ref, itemId) {
  return ref.watch(householdScopedMaintenanceRepositoryProvider).loadTasks(itemId: itemId);
});
