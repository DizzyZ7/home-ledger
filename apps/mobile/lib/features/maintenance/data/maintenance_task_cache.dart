import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/maintenance_completion.dart';
import '../domain/maintenance_task.dart';

class MaintenanceTaskCache {
  MaintenanceTaskCache({String boxName = _defaultBoxName}) : _boxName = boxName;

  static const _defaultBoxName = 'homeledger_maintenance_v1';
  static const _tasksKey = 'tasks';
  static const _historyKey = 'history';

  final String _boxName;

  Future<List<MaintenanceTask>?> read() {
    return _readList(_tasksKey, MaintenanceTask.fromJson);
  }

  Future<List<MaintenanceCompletion>?> readHistory() {
    return _readList(_historyKey, MaintenanceCompletion.fromJson);
  }

  Future<void> write(Iterable<MaintenanceTask> tasks) {
    return _writeList(_tasksKey, tasks.map((task) => task.toJson()));
  }

  Future<void> writeHistory(Iterable<MaintenanceCompletion> history) {
    return _writeList(_historyKey, history.map((entry) => entry.toJson()));
  }

  Future<void> clearHistory() => _delete(_historyKey);

  Future<List<T>?> _readList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      final raw = box.get(key);
      if (raw == null) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        await _delete(key);
        return null;
      }
      return List.unmodifiable(
        decoded.whereType<Map<String, dynamic>>().map(fromJson).toList(growable: false),
      );
    } on FormatException {
      await _delete(key);
      return null;
    } on Object {
      return null;
    }
  }

  Future<void> _writeList(String key, Iterable<Map<String, dynamic>> entries) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.put(key, jsonEncode(entries.toList(growable: false)));
    } on Object {
      // Cache failures must never make the primary maintenance workflow fail.
    }
  }

  Future<void> _delete(String key) async {
    try {
      final box = await Hive.openBox<String>(_boxName);
      await box.delete(key);
    } on Object {
      // A corrupted optional cache is safe to ignore after a failed cleanup.
    }
  }
}
