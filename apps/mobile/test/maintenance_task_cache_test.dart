import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_ledger/features/maintenance/data/maintenance_repository.dart';
import 'package:home_ledger/features/maintenance/data/maintenance_task_cache.dart';
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

  test('uses the cached full snapshot when the maintenance API is unavailable', () async {
    final cache = MaintenanceTaskCache(boxName: 'maintenance-cache-offline-fallback');
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

    final client = Dio()
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
    final repository = RemoteMaintenanceRepository(client, cache);

    final allTasks = await repository.loadTasks();
    final routerTasks = await repository.loadTasks(itemId: 'router');

    expect(allTasks.map((task) => task.id), ['washer-task', 'router-task']);
    expect(routerTasks.map((task) => task.id), ['router-task']);
  });
}
