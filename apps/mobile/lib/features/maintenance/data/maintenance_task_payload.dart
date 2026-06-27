import '../domain/maintenance_task.dart';

extension MaintenanceTaskPayload on MaintenanceTask {
  Map<String, dynamic> toCreatePayload() => {
        'item_id': itemId,
        'title': title,
        'notes': notes,
        'frequency_days': frequencyDays,
        'next_due_date': _dateOnly(nextDueDate),
      };

  Map<String, dynamic> toUpdatePayload() => {
        'title': title,
        'notes': notes,
        'frequency_days': frequencyDays,
        'next_due_date': _dateOnly(nextDueDate),
      };

  String _dateOnly(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
