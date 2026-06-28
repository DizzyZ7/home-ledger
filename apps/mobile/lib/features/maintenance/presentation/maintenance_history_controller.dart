import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/maintenance_repository.dart';
import '../domain/maintenance_completion.dart';

final maintenanceHistoryProvider = FutureProvider.autoDispose<List<MaintenanceCompletion>>((ref) {
  return ref.watch(maintenanceRepositoryProvider).loadHistory();
});
