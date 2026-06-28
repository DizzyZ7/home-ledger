import 'package:flutter/foundation.dart';

@immutable
class MaintenanceCompletion {
  const MaintenanceCompletion({
    required this.id,
    required this.householdId,
    required this.itemId,
    required this.itemName,
    required this.taskId,
    required this.taskTitle,
    required this.completedAt,
  });

  final String id;
  final String householdId;
  final String itemId;
  final String itemName;
  final String taskId;
  final String taskTitle;
  final DateTime completedAt;

  factory MaintenanceCompletion.fromJson(Map<String, dynamic> json) {
    final completedAt = json['completed_at'];
    if (completedAt is! String) {
      throw const FormatException('Missing maintenance completion timestamp.');
    }
    final parsedCompletedAt = DateTime.tryParse(completedAt);
    if (parsedCompletedAt == null) {
      throw const FormatException('Invalid maintenance completion timestamp.');
    }

    return MaintenanceCompletion(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      itemId: json['item_id'] as String,
      itemName: json['item_name'] as String,
      taskId: json['task_id'] as String,
      taskTitle: json['task_title'] as String,
      completedAt: parsedCompletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'household_id': householdId,
        'item_id': itemId,
        'item_name': itemName,
        'task_id': taskId,
        'task_title': taskTitle,
        'completed_at': completedAt.toIso8601String(),
      };
}
