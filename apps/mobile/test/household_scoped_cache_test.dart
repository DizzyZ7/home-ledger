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

  test('keeps inventory snapshots isolated by user and household', () async {
    final ownerCache = HomeItemCache(householdId: 'shared-home', userId: 'owner');
    final guestCache = HomeItemCache(householdId: 'shared-home', userId: 'guest');
    final secondHomeCache = HomeItemCache(householdId: 'second-home', userId: 'owner');

    await ownerCache.write([
      const HomeItem(id: 'router', name: 'Owner router', category: 'electronics'),
    ]);

    expect((await ownerCache.read()).single.name, 'Owner router');
    expect(await guestCache.read(), isEmpty);
    expect(await secondHomeCache.read(), isEmpty);
  });

  test('keeps maintenance tasks and history isolated by user and household', () async {
    final ownerCache = MaintenanceTaskCache(
      boxName: 'household-maintenance-cache',
      householdId: 'shared-home',
      userId: 'owner',
    );
    final guestCache = MaintenanceTaskCache(
      boxName: 'household-maintenance-cache',
      householdId: 'shared-home',
      userId: 'guest',
    );
    final task = MaintenanceTask(
      id: 'owner-task',
      itemId: 'router',
      itemName: 'Owner router',
      title: 'Review firmware',
      frequencyDays: 90,
      nextDueDate: DateTime(2026, 7, 15),
    );
    final completion = MaintenanceCompletion(
      id: 'owner-completion',
      householdId: 'shared-home',
      itemId: 'router',
      itemName: 'Owner router',
      taskId: task.id,
      taskTitle: task.title,
      completedAt: DateTime.utc(2026, 7, 1),
    );

    await ownerCache.write([task]);
    await ownerCache.writeHistory([completion]);

    expect((await ownerCache.read())!.single.id, task.id);
    expect((await ownerCache.readHistory())!.single.id, completion.id);
    expect(await guestCache.read(), isNull);
    expect(await guestCache.readHistory(), isNull);
  });
}
