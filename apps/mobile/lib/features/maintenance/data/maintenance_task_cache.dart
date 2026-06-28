import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/maintenance_task.dart';

class MaintenanceTaskCache {
  MaintenanceTaskCache({String boxName = _defaultBoxName}) : _boxName = boxName;

  static const _defaultBoxName = 'homeledger_maintenance_v1';
  static const _tasksKey = 'tasks';

  final String _boxName;

  Future<List<MaintenanceTask>?> read() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final raw = box.get(_tasksKey);
      if (raw == null) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        await box.delete(_tasksKey);
        return null;
      }
      return List.unmodifiable(
        decoded
            .whereType<Map<String, dynamic>>()
            .map(MaintenanceTask.fromJson)
            .toList(growable: false),
      );
    } on FormatException {
      await _clearCorruptedSnapshot();
      return null;
    } on Object {
      return null;
    }
  }

  Future<void> write(Iterable<MaintenanceTask> tasks) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.put(
        _tasksKey,
        jsonEncode(tasks.map((task) => task.toJson()).toList(growable: false)),
      );
    } on Object {
      // Cache failures must never make the primary maintenance workflow fail.
    }
  }

  Future<void> _clearCorruptedSnapshot() async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.delete(_tasksKey);
    } on Object {
      // A corrupted optional cache is safe to ignore after a failed cleanup.
    }
  }
}
