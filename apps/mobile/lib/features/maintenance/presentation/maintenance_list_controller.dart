import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/maintenance_repository.dart';
import '../domain/maintenance_task.dart';

final maintenanceListControllerProvider =
    AsyncNotifierProvider<MaintenanceListController, List<MaintenanceTask>>(
  MaintenanceListController.new,
);

class MaintenanceListController extends AsyncNotifier<List<MaintenanceTask>> {
  @override
  FutureOr<List<MaintenanceTask>> build() {
    return ref.read(maintenanceRepositoryProvider).loadTasks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(maintenanceRepositoryProvider).loadTasks(),
    );
  }

  Future<void> completeTask(String taskId) async {
    final completed = await ref.read(maintenanceRepositoryProvider).completeTask(taskId);
    final current = state.valueOrNull ?? const <MaintenanceTask>[];
    final updated = current
        .map((task) => task.id == completed.id ? completed : task)
        .toList(growable: false)
      ..sort((left, right) => left.nextDueDate.compareTo(right.nextDueDate));
    state = AsyncData(updated);
  }
}
