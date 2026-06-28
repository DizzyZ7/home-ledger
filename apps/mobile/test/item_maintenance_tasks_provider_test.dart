import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/maintenance/data/maintenance_repository.dart';
import 'package:home_ledger/features/maintenance/domain/maintenance_completion.dart';
import 'package:home_ledger/features/maintenance/domain/maintenance_task.dart';
import 'package:home_ledger/features/maintenance/presentation/item_maintenance_tasks_provider.dart';

class ItemScopedMaintenanceRepository implements MaintenanceRepository {
  ItemScopedMaintenanceRepository(this._tasks);

  final List<MaintenanceTask> _tasks;

  @override
  Future<MaintenanceTask> completeTask(String taskId) async => _tasks.firstWhere((task) => task.id == taskId);

  @override
  Future<MaintenanceTask> createTask(MaintenanceTask task) async => task;

  @override
  Future<List<MaintenanceTask>> loadTasks({String? itemId}) async {
    return List.unmodifiable(
      itemId == null ? _tasks : _tasks.where((task) => task.itemId == itemId),
    );
  }

  @override
  Future<List<MaintenanceCompletion>> loadHistory({String? itemId}) async => const [];

  @override
  Future<MaintenanceTask> updateTask(MaintenanceTask task) async => task;
}

void main() {
  test('item maintenance provider returns only tasks attached to its item', () async {
    final container = ProviderContainer(
      overrides: [
        maintenanceRepositoryProvider.overrideWithValue(
          ItemScopedMaintenanceRepository([
            MaintenanceTask(
              id: 'router-task',
              itemId: 'router',
              title: 'Review router firmware',
              frequencyDays: 180,
              nextDueDate: DateTime(2026, 7, 1),
            ),
            MaintenanceTask(
              id: 'washer-task',
              itemId: 'washer',
              title: 'Clean washer filter',
              frequencyDays: 90,
              nextDueDate: DateTime(2026, 7, 2),
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final tasks = await container.read(itemMaintenanceTasksProvider('router').future);

    expect(tasks.map((task) => task.id), ['router-task']);
  });
}
