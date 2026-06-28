import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/maintenance/domain/maintenance_task.dart';
import 'package:home_ledger/features/maintenance/presentation/maintenance_filter.dart';

void main() {
  final referenceDate = DateTime(2026, 6, 28);
  final tasks = [
    MaintenanceTask(
      id: 'overdue',
      itemId: 'washer',
      title: 'Clean washer filter',
      frequencyDays: 90,
      nextDueDate: DateTime(2026, 6, 27),
    ),
    MaintenanceTask(
      id: 'today',
      itemId: 'router',
      title: 'Review firmware',
      frequencyDays: 180,
      nextDueDate: DateTime(2026, 6, 28),
    ),
    MaintenanceTask(
      id: 'upcoming',
      itemId: 'kettle',
      title: 'Descale kettle',
      frequencyDays: 60,
      nextDueDate: DateTime(2026, 7, 28),
    ),
    MaintenanceTask(
      id: 'later',
      itemId: 'dryer',
      title: 'Clean dryer vent',
      frequencyDays: 180,
      nextDueDate: DateTime(2026, 7, 29),
    ),
  ];

  test('filters overdue and next 30-day maintenance inclusively', () {
    expect(
      filterMaintenanceTasks(tasks, filter: MaintenanceFilter.all, now: referenceDate).map((task) => task.id),
      ['overdue', 'today', 'upcoming', 'later'],
    );
    expect(
      filterMaintenanceTasks(tasks, filter: MaintenanceFilter.overdue, now: referenceDate).map((task) => task.id),
      ['overdue'],
    );
    expect(
      filterMaintenanceTasks(tasks, filter: MaintenanceFilter.upcoming, now: referenceDate).map((task) => task.id),
      ['today', 'upcoming'],
    );
  });
}
