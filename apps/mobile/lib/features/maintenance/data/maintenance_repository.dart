import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/maintenance_completion.dart';
import '../domain/maintenance_task.dart';
import 'maintenance_task_cache.dart';
import 'maintenance_task_payload.dart';

abstract class MaintenanceRepository {
  Future<List<MaintenanceTask>> loadTasks({String? itemId});
  Future<List<MaintenanceCompletion>> loadHistory({String? itemId});
  Future<MaintenanceTask> createTask(MaintenanceTask task);
  Future<MaintenanceTask> updateTask(MaintenanceTask task);
  Future<MaintenanceTask> completeTask(String taskId);
}

class RemoteMaintenanceRepository implements MaintenanceRepository {
  RemoteMaintenanceRepository(this._client, this._cache);

  final Dio _client;
  final MaintenanceTaskCache _cache;

  @override
  Future<List<MaintenanceTask>> loadTasks({String? itemId}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/maintenance',
        queryParameters: itemId == null ? null : {'item_id': itemId},
      );
      final tasks = _sortTasks(_tasksFromPayload(response.data));
      if (itemId == null) {
        await _cache.write(tasks);
      }
      return tasks;
    } on DioException catch (exception) {
      final cached = await _cache.read();
      if (cached != null) {
        return _sortTasks(
          itemId == null ? cached : cached.where((task) => task.itemId == itemId),
        );
      }
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<List<MaintenanceCompletion>> loadHistory({String? itemId}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        '/maintenance/history',
        queryParameters: {
          'page_size': 100,
          if (itemId != null) 'item_id': itemId,
        },
      );
      return _sortHistory(_historyFromPayload(response.data));
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<MaintenanceTask> createTask(MaintenanceTask task) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/maintenance',
        data: task.toCreatePayload(),
      );
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty maintenance response.');
      }
      final created = MaintenanceTask.fromJson(payload);
      await _mergeCachedTask(created, addWhenMissing: true);
      return created;
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<MaintenanceTask> updateTask(MaintenanceTask task) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/maintenance/${task.id}',
        data: task.toUpdatePayload(),
      );
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty maintenance response.');
      }
      final updated = MaintenanceTask.fromJson(payload);
      await _mergeCachedTask(updated, addWhenMissing: false);
      return updated;
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  @override
  Future<MaintenanceTask> completeTask(String taskId) async {
    try {
      final response = await _client.post<Map<String, dynamic>>('/maintenance/$taskId/complete');
      final payload = response.data;
      if (payload == null) {
        throw const ApiException('Empty maintenance response.');
      }
      final completed = MaintenanceTask.fromJson(payload);
      await _mergeCachedTask(completed, addWhenMissing: false);
      return completed;
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  Future<void> _mergeCachedTask(
    MaintenanceTask task, {
    required bool addWhenMissing,
  }) async {
    final cached = await _cache.read();
    if (cached == null) {
      return;
    }

    final index = cached.indexWhere((existing) => existing.id == task.id);
    if (index == -1 && !addWhenMissing) {
      return;
    }

    final updated = [...cached];
    if (index == -1) {
      updated.add(task);
    } else {
      updated[index] = task;
    }
    await _cache.write(_sortTasks(updated));
  }

  List<MaintenanceTask> _tasksFromPayload(Map<String, dynamic>? payload) {
    final rawTasks = payload?['items'] as List<dynamic>? ?? const [];
    return rawTasks
        .whereType<Map<String, dynamic>>()
        .map(MaintenanceTask.fromJson)
        .toList(growable: false);
  }

  List<MaintenanceCompletion> _historyFromPayload(Map<String, dynamic>? payload) {
    final rawHistory = payload?['items'] as List<dynamic>? ?? const [];
    return rawHistory
        .whereType<Map<String, dynamic>>()
        .map(MaintenanceCompletion.fromJson)
        .toList(growable: false);
  }

  List<MaintenanceTask> _sortTasks(Iterable<MaintenanceTask> tasks) {
    final sorted = tasks.toList(growable: false)
      ..sort((left, right) => left.nextDueDate.compareTo(right.nextDueDate));
    return List.unmodifiable(sorted);
  }

  List<MaintenanceCompletion> _sortHistory(Iterable<MaintenanceCompletion> history) {
    final sorted = history.toList(growable: false)
      ..sort((left, right) => right.completedAt.compareTo(left.completedAt));
    return List.unmodifiable(sorted);
  }
}

class MockMaintenanceRepository implements MaintenanceRepository {
  MockMaintenanceRepository()
      : _tasks = [
          MaintenanceTask(
            id: 'demo-clean-filter',
            itemId: 'demo-washer',
            itemName: 'Washing machine',
            title: 'Clean the washing machine filter',
            frequencyDays: 90,
            nextDueDate: DateTime.now().subtract(const Duration(days: 2)),
          ),
          MaintenanceTask(
            id: 'demo-router-restart',
            itemId: 'demo-router',
            itemName: 'Wi-Fi router',
            title: 'Review router firmware',
            frequencyDays: 180,
            nextDueDate: DateTime.now().add(const Duration(days: 12)),
          ),
        ];

  final List<MaintenanceTask> _tasks;
  final List<MaintenanceCompletion> _history = [];
  var _completionSequence = 0;

  @override
  Future<List<MaintenanceTask>> loadTasks({String? itemId}) async {
    final tasks = itemId == null ? _tasks : _tasks.where((task) => task.itemId == itemId).toList();
    tasks.sort((left, right) => left.nextDueDate.compareTo(right.nextDueDate));
    return List.unmodifiable(tasks);
  }

  @override
  Future<List<MaintenanceCompletion>> loadHistory({String? itemId}) async {
    final history = itemId == null ? _history : _history.where((entry) => entry.itemId == itemId).toList();
    history.sort((left, right) => right.completedAt.compareTo(left.completedAt));
    return List.unmodifiable(history);
  }

  @override
  Future<MaintenanceTask> createTask(MaintenanceTask task) async {
    _tasks.add(task);
    return task;
  }

  @override
  Future<MaintenanceTask> updateTask(MaintenanceTask task) async {
    final index = _tasks.indexWhere((existing) => existing.id == task.id);
    if (index == -1) {
      throw const ApiException('Item was not found.');
    }
    _tasks[index] = task;
    return task;
  }

  @override
  Future<MaintenanceTask> completeTask(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) {
      throw const ApiException('Maintenance task was not found.');
    }

    final task = _tasks[index];
    final completedAt = DateTime.now().toUtc();
    _history.add(
      MaintenanceCompletion(
        id: 'mock-completion-${++_completionSequence}',
        householdId: 'mock-household',
        itemId: task.itemId,
        itemName: task.itemName ?? task.itemId,
        taskId: task.id,
        taskTitle: task.title,
        completedAt: completedAt,
      ),
    );
    final completed = task.markCompleted(completedAt);
    _tasks[index] = completed;
    return completed;
  }
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockMaintenanceRepository();
  }
  return RemoteMaintenanceRepository(ref.watch(apiClientProvider), MaintenanceTaskCache());
});
