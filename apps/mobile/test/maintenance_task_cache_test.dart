import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_ledger/features/maintenance/data/maintenance_repository.dart';
import 'package:home_ledger/features/maintenance/data/maintenance_task_cache.dart';
import 'package:home_ledger/features/maintenance/domain/maintenance_completion.dart';
import 'package:home_ledger/features/maintenance/domain/maintenance_task.dart';

void main() {
  late Directory cacheDirectory;

  setUpAll(() async {
    cacheDirectory = await Directory.systemTemp.createTemp('homeledger-maintenance-cache-');
    Hive.init(cacheDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await cacheDirectory.delete(recursive: true);
  });

  MaintenanceTask task({
    required String id,
    required String itemId,
    required DateTime nextDueDate,
  }) {
    return MaintenanceTask(
      id: id,
      itemId: itemId,
      itemName: itemId == 'router' ? 'Wi-Fi router' : 'Washing machine',
      title: 'Maintain $itemId',
      frequencyDays: 90,
      nextDueDate: nextDueDate,
    );
  }

  MaintenanceCompletion completion({
    required String id,
    required String itemId,
    required DateTime completedAt,
  }) {
    return MaintenanceCompletion(
      id: id,
      householdId: 'household',
      itemId: itemId,
      itemName: itemId == 'router' ? 'Wi-Fi router' : 'Washing machine',
      taskId: '$itemId-task',
      taskTitle: 'Maintain $itemId',
      completedAt: completedAt,
    );
  }

  Dio offlineClient() {
    return Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
              ),
            );
          },
        ),
      );
  }

  test('serializes a task snapshot and discards malformed cache data', () async {
    final cache = MaintenanceTaskCache(boxName: 'maintenance-cache-serialization');
    final storedTask = task(
      id: 'router-task',
      itemId: 'router',
      nextDueDate: DateTime(2026, 7, 10),
    );

    await cache.write([storedTask]);
    final cached = await cache.read();
    expect(cached, hasLength(1));
    expect(cached!.single.toJson(), storedTask.toJson());

    final box = await Hive.openBox<String>('maintenance-cache-serialization');
    await box.put('tasks', '{not valid json');

    expect(await cache.read(), isNull);
  });

  test('uses the cached full task snapshot when the maintenance API is unavailable', () async {
    final cache = MaintenanceTaskCache(boxName: 'maintenance-cache-offline-tasks');
    final routerTask = task(
      id: 'router-task',
      itemId: 'router',
      nextDueDate: DateTime(2026, 7, 10),
    );
    final washerTask = task(
      id: 'washer-task',
      itemId: 'washer',
      nextDueDate: DateTime(2026, 7, 1),
    );
    await cache.write([routerTask, washerTask]);

    final repository = RemoteMaintenanceRepository(offlineClient(), cache);

    final allTasks = await repository.loadTasks();
    final routerTasks = await repository.loadTasks(itemId: 'router');

    expect(allTasks.map((task) => task.id), ['washer-task', 'router-task']);
    expect(routerTasks.map((task) => task.id), ['router-task']);
  });

  test('uses the cached completion history when the history API is unavailable', () async {
    final cache = MaintenanceTaskCache(boxName: 'maintenance-cache-offline-history');
    final routerHistory = completion(
      id: 'router-completion',
      itemId: 'router',
      completedAt: DateTime(2026, 7, 10),
    );
    final washerHistory = completion(
      id: 'washer-completion',
      itemId: 'washer',
      completedAt: DateTime(2026, 7, 11),
    );
    await cache.writeHistory([routerHistory, washerHistory]);

    final repository = RemoteMaintenanceRepository(offlineClient(), cache);

    final allHistory = await repository.loadHistory();
    final routerOnlyHistory = await repository.loadHistory(itemId: 'router');

    expect(allHistory.map((entry) => entry.id), ['washer-completion', 'router-completion']);
    expect(routerOnlyHistory.map((entry) => entry.id), ['router-completion']);

    final box = await Hive.openBox<String>('maintenance-cache-offline-history');
    await box.put('history', '{not valid json');
    expect(await cache.readHistory(), isNull);
  });
}
