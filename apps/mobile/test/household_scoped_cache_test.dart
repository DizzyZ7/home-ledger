import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_ledger/features/items/data/home_item_cache.dart';
import 'package:home_ledger/features/items/domain/home_item.dart';
import 'package:home_ledger/features/maintenance/data/maintenance_task_cache.dart';
import 'package:home_ledger/features/maintenance/domain/maintenance_completion.dart';
import 'package:home_ledger/features/maintenance/domain/maintenance_task.dart';

void main() {
  late Directory cacheDirectory;

  setUpAll(() async {
    cacheDirectory = await Directory.systemTemp.createTemp('homeledger-household-cache-');
    Hive.init(cacheDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await cacheDirectory.delete(recursive: true);
  });

  test('keeps inventory snapshots isolated by household', () async {
    final personalCache = HomeItemCache(householdId: 'personal');
    final sharedCache = HomeItemCache(householdId: 'shared');

    await personalCache.write([
      const HomeItem(id: 'router', name: 'Personal router', category: 'electronics'),
    ]);

    expect((await personalCache.read()).single.name, 'Personal router');
    expect(await sharedCache.read(), isEmpty);
  });

  test('keeps maintenance tasks and history isolated by household', () async {
    final personalCache = MaintenanceTaskCache(
      boxName: 'household-maintenance-cache',
      householdId: 'personal',
    );
    final sharedCache = MaintenanceTaskCache(
      boxName: 'household-maintenance-cache',
      householdId: 'shared',
    );
    final task = MaintenanceTask(
      id: 'personal-task',
      itemId: 'router',
      itemName: 'Personal router',
      title: 'Review firmware',
      frequencyDays: 90,
      nextDueDate: DateTime(2026, 7, 15),
    );
    final completion = MaintenanceCompletion(
      id: 'personal-completion',
      householdId: 'personal',
      itemId: 'router',
      itemName: 'Personal router',
      taskId: task.id,
      taskTitle: task.title,
      completedAt: DateTime.utc(2026, 7, 1),
    );

    await personalCache.write([task]);
    await personalCache.writeHistory([completion]);

    expect((await personalCache.read())!.single.id, task.id);
    expect((await personalCache.readHistory())!.single.id, completion.id);
    expect(await sharedCache.read(), isNull);
    expect(await sharedCache.readHistory(), isNull);
  });
}
