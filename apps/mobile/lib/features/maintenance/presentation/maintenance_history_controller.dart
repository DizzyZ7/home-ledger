import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/household_scoped_repositories.dart';
import '../domain/maintenance_completion.dart';

final maintenanceHistoryProvider = FutureProvider.autoDispose
    .family<List<MaintenanceCompletion>, String?>((ref, itemId) {
  return ref.watch(householdScopedMaintenanceRepositoryProvider).loadHistory(itemId: itemId);
});
