import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/maintenance_task.dart';

enum MaintenanceFilter {
  all,
  overdue,
  upcoming;
}

final maintenanceFilterProvider = StateProvider.autoDispose<MaintenanceFilter>((ref) {
  return MaintenanceFilter.all;
});

List<MaintenanceTask> filterMaintenanceTasks(
  Iterable<MaintenanceTask> tasks, {
  required MaintenanceFilter filter,
  DateTime? now,
  int upcomingDays = 30,
}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final upcomingDeadline = today.add(Duration(days: upcomingDays));

  final filtered = tasks.where((task) {
    final dueDate = DateTime(
      task.nextDueDate.year,
      task.nextDueDate.month,
      task.nextDueDate.day,
    );
    return switch (filter) {
      MaintenanceFilter.all => true,
      MaintenanceFilter.overdue => dueDate.isBefore(today),
      MaintenanceFilter.upcoming => !dueDate.isBefore(today) && !dueDate.isAfter(upcomingDeadline),
    };
  }).toList(growable: false);

  return List.unmodifiable(filtered);
}
