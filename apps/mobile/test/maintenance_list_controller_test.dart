import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/maintenance/data/maintenance_repository.dart';
import 'package:home_ledger/features/maintenance/domain/maintenance_task.dart';
import 'package:home_ledger/features/maintenance/presentation/maintenance_list_controller.dart';

class FakeMaintenanceRepository implements MaintenanceRepository {
  FakeMaintenanceRepository(this._task);

  MaintenanceTask _task;

  @override
  Future<MaintenanceTask> completeTask(String taskId) async {
    _task = _task.markCompleted(DateTime(2026, 6, 27));
    return _task;
  }

  @override
  Future<List<MaintenanceTask>> loadTasks() async => [_task];
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
      overrides: [maintenanceRepositoryProvider.overrideWithValue(FakeMaintenanceRepository(task))],
    );
    addTearDown(container.dispose);

    final initial = await container.read(maintenanceListControllerProvider.future);
    expect(initial.single.nextDueDate, DateTime(2026, 6, 20));

    await container.read(maintenanceListControllerProvider.notifier).completeTask(task.id);

    final completed = container.read(maintenanceListControllerProvider).valueOrNull!.single;
    expect(completed.nextDueDate, DateTime(2026, 9, 18));
    expect(completed.completedAt, DateTime(2026, 6, 27));
  });
}
