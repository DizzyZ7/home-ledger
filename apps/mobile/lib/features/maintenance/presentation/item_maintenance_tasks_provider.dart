import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/maintenance_repository.dart';
import '../domain/maintenance_task.dart';

final itemMaintenanceTasksProvider =
    FutureProvider.autoDispose.family<List<MaintenanceTask>, String>((ref, itemId) {
  return ref.watch(maintenanceRepositoryProvider).loadTasks(itemId: itemId);
});
