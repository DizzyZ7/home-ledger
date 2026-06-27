import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/maintenance_task.dart';
import 'maintenance_task_payload.dart';

abstract class MaintenanceRepository {
  Future<List<MaintenanceTask>> loadTasks();
  Future<MaintenanceTask> createTask(MaintenanceTask task);
  Future<MaintenanceTask> updateTask(MaintenanceTask task);
  Future<MaintenanceTask> completeTask(String taskId);
}

class RemoteMaintenanceRepository implements MaintenanceRepository {
  RemoteMaintenanceRepository(this._client);

  final Dio _client;

  @override
  Future<List<MaintenanceTask>> loadTasks() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/maintenance');
      final payload = response.data;
      final rawTasks = payload?['items'] as List<dynamic>? ?? const [];
      return rawTasks
          .whereType<Map<String, dynamic>>()
          .map(MaintenanceTask.fromJson)
          .toList(growable: false);
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
      return MaintenanceTask.fromJson(payload);
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
      return MaintenanceTask.fromJson(payload);
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
      return MaintenanceTask.fromJson(payload);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
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

  @override
  Future<List<MaintenanceTask>> loadTasks() async {
    _tasks.sort((left, right) => left.nextDueDate.compareTo(right.nextDueDate));
    return List.unmodifiable(_tasks);
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
      throw const ApiException('Maintenance task was not found.');
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
    final completed = _tasks[index].markCompleted(DateTime.now());
    _tasks[index] = completed;
    return completed;
  }
}

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockData) {
    return MockMaintenanceRepository();
  }
  return RemoteMaintenanceRepository(ref.watch(apiClientProvider));
});
