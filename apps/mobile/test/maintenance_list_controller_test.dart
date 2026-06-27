import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/maintenance/data/maintenance_repository.dart';
import 'package:home_ledger/features/maintenance/domain/maintenance_task.dart';
import 'package:home_ledger/features/maintenance/presentation/maintenance_list_controller.dart';

class FakeMaintenanceRepository implements MaintenanceRepository {
  FakeMaintenanceRepository(this._tasks);

  final List<MaintenanceTask> _tasks;

  @override
  Future<MaintenanceTask> completeTask(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    final completed = _tasks[index].markCompleted(DateTime(2026, 6, 27));
    _tasks[index] = completed;
    return completed;
  }

  @override
  Future<MaintenanceTask> createTask(MaintenanceTask task) async {
    _tasks.add(task);
    return task;
  }

  @override
  Future<List<MaintenanceTask>> loadTasks({String? itemId}) async {
    if (itemId == null) {
      return List.unmodifiable(_tasks);
    }
    return List.unmodifiable(_tasks.where((task) => task.itemId == itemId));
  }

  @override
  Future<MaintenanceTask> updateTask(MaintenanceTask task) async {
    final index = _tasks.indexWhere((existing) => existing.id == task.id);
    _tasks[index] = task;
    return task;
  }
}

void main() {
  test('completion replaces a task and advances its next due date', () async {
    final task = MaintenanceTask(
      id: 'filter',
      itemId: 'washer',
      title: 'Clean filter',
      frequencyDays: 90,
      nextDueDate: DateTime(2026, 6, 20),
    );
    final container = ProviderContainer(
      overrides: [maintenanceRepositoryProvider.overrideWithValue(FakeMaintenanceRepository([task]))],
    );
    addTearDown(container.dispose);

    final initial = await container.read(maintenanceListControllerProvider.future);
    expect(initial.single.nextDueDate, DateTime(2026, 6, 20));

    await container.read(maintenanceListControllerProvider.notifier).completeTask(task.id);

    final completed = container.read(maintenanceListControllerProvider).valueOrNull!.single;
    expect(completed.nextDueDate, DateTime(2026, 9, 18));
    expect(completed.completedAt, DateTime(2026, 6, 27));
  });

  test('creation inserts a task in next due date order', () async {
    final existing = MaintenanceTask(
      id: 'later',
      itemId: 'router',
      title: 'Review firmware',
      frequencyDays: 180,
      nextDueDate: DateTime(2026, 9, 1),
    );
    final created = MaintenanceTask(
      id: 'earlier',
      itemId: 'washer',
      title: 'Clean filter',
      frequencyDays: 90,
      nextDueDate: DateTime(2026, 7, 1),
    );
    final container = ProviderContainer(
      overrides: [maintenanceRepositoryProvider.overrideWithValue(FakeMaintenanceRepository([existing]))],
    );
    addTearDown(container.dispose);

    await container.read(maintenanceListControllerProvider.future);
    await container.read(maintenanceListControllerProvider.notifier).createTask(created);

    final tasks = container.read(maintenanceListControllerProvider).valueOrNull!;
    expect(tasks.map((task) => task.id), ['earlier', 'later']);
  });

  test('editing replaces a task and reorders it by its new due date', () async {
    final first = MaintenanceTask(
      id: 'first',
      itemId: 'router',
      title: 'Review firmware',
      frequencyDays: 180,
      nextDueDate: DateTime(2026, 8, 1),
    );
    final second = MaintenanceTask(
      id: 'second',
      itemId: 'washer',
      title: 'Clean filter',
      frequencyDays: 90,
      nextDueDate: DateTime(2026, 9, 1),
    );
    final edited = MaintenanceTask(
      id: 'second',
      itemId: 'washer',
      title: 'Clean filter thoroughly',
      frequencyDays: 120,
      nextDueDate: DateTime(2026, 7, 1),
    );
    final container = ProviderContainer(
      overrides: [maintenanceRepositoryProvider.overrideWithValue(FakeMaintenanceRepository([first, second]))],
    );
    addTearDown(container.dispose);

    await container.read(maintenanceListControllerProvider.future);
    await container.read(maintenanceListControllerProvider.notifier).updateTask(edited);

    final tasks = container.read(maintenanceListControllerProvider).valueOrNull!;
    expect(tasks.map((task) => task.id), ['second', 'first']);
    expect(tasks.first.title, 'Clean filter thoroughly');
    expect(tasks.first.frequencyDays, 120);
  });
}
