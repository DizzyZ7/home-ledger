import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/maintenance_repository.dart';
import '../domain/maintenance_completion.dart';

final maintenanceHistoryProvider = FutureProvider.autoDispose
    .family<List<MaintenanceCompletion>, String?>((ref, itemId) {
  return ref.watch(maintenanceRepositoryProvider).loadHistory(itemId: itemId);
});
