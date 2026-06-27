import 'package:flutter/foundation.dart';

@immutable
class MaintenanceTask {
  const MaintenanceTask({
    required this.id,
    required this.itemId,
    required this.title,
    required this.frequencyDays,
    required this.nextDueDate,
    this.itemName,
    this.notes,
    this.completedAt,
  });

  final String id;
  final String itemId;
  final String? itemName;
  final String title;
  final String? notes;
  final int frequencyDays;
  final DateTime nextDueDate;
  final DateTime? completedAt;

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(String key) {
      final value = json[key];
      if (value is! String) {
        throw FormatException('Missing maintenance date: $key');
      }
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        throw FormatException('Invalid maintenance date: $key');
      }
      return parsed;
    }

    DateTime? parseOptionalDate(String key) {
      final value = json[key];
      if (value is! String) {
        return null;
      }
      return DateTime.tryParse(value);
    }

    return MaintenanceTask(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      itemName: json['item_name'] as String?,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      frequencyDays: json['frequency_days'] as int,
      nextDueDate: parseDate('next_due_date'),
      completedAt: parseOptionalDate('completed_at'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'item_name': itemName,
        'title': title,
        'notes': notes,
        'frequency_days': frequencyDays,
        'next_due_date': nextDueDate.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  MaintenanceTask markCompleted(DateTime completedAt) {
    return MaintenanceTask(
      id: id,
      itemId: itemId,
      itemName: itemName,
      title: title,
      notes: notes,
      frequencyDays: frequencyDays,
      nextDueDate: nextDueDate.add(Duration(days: frequencyDays)),
      completedAt: completedAt,
    );
  }
}
