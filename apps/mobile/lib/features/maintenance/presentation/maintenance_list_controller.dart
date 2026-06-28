import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/household_scoped_repositories.dart';
import '../domain/maintenance_task.dart';

final maintenanceListControllerProvider =
    AsyncNotifierProvider<MaintenanceListController, List<MaintenanceTask>>(
  MaintenanceListController.new,
);

class MaintenanceListController extends AsyncNotifier<List<MaintenanceTask>> {
  @override
  FutureOr<List<MaintenanceTask>> build() {
    return ref.read(householdScopedMaintenanceRepositoryProvider).loadTasks();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(householdScopedMaintenanceRepositoryProvider).loadTasks(),
    );
  }

  Future<void> createTask(MaintenanceTask task) async {
    final created = await ref.read(householdScopedMaintenanceRepositoryProvider).createTask(task);
    final current = state.valueOrNull ?? const <MaintenanceTask>[];
    state = AsyncData(_sort([...current, created]));
  }

  Future<void> updateTask(MaintenanceTask task) async {
    final updatedTask = await ref.read(householdScopedMaintenanceRepositoryProvider).updateTask(task);
    final current = state.valueOrNull ?? const <MaintenanceTask>[];
    state = AsyncData(
      _sort([
        for (final existing in current)
          if (existing.id == updatedTask.id) updatedTask else existing,
      ]),
    );
  }

  Future<void> completeTask(String taskId) async {
    final completed = await ref.read(householdScopedMaintenanceRepositoryProvider).completeTask(taskId);
    final current = state.valueOrNull ?? const <MaintenanceTask>[];
    state = AsyncData(
      _sort([
        for (final task in current)
          if (task.id == completed.id) completed else task,
      ]),
    );
  }

  List<MaintenanceTask> _sort(List<MaintenanceTask> tasks) {
    tasks.sort((left, right) => left.nextDueDate.compareTo(right.nextDueDate));
    return tasks;
  }
}
