import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/household_scoped_repositories.dart';
import '../../dashboard/presentation/item_list_controller.dart';
import '../domain/home_item.dart';

final archivedItemListControllerProvider =
    AsyncNotifierProvider<ArchivedItemListController, List<HomeItem>>(
  ArchivedItemListController.new,
);

class ArchivedItemListController extends AsyncNotifier<List<HomeItem>> {
  @override
  FutureOr<List<HomeItem>> build() {
    return ref.read(householdScopedHomeItemRepositoryProvider).loadArchivedItems();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(householdScopedHomeItemRepositoryProvider).loadArchivedItems(),
    );
  }

  Future<void> restoreItem(String itemId) async {
    final restored = await ref.read(householdScopedHomeItemRepositoryProvider).restoreItem(itemId);
    final current = state.valueOrNull ?? const <HomeItem>[];
    state = AsyncData(current.where((item) => item.id != restored.id).toList(growable: false));
    ref.read(itemListControllerProvider.notifier).addRestoredItem(restored);
  }
}
