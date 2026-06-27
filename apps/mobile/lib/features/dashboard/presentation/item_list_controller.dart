import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../items/data/home_item_repository.dart';
import '../../items/domain/home_item.dart';

final itemListControllerProvider =
    AsyncNotifierProvider<ItemListController, List<HomeItem>>(ItemListController.new);

class ItemListController extends AsyncNotifier<List<HomeItem>> {
  @override
  FutureOr<List<HomeItem>> build() => ref.read(homeItemRepositoryProvider).loadItems();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(homeItemRepositoryProvider).loadItems());
  }

  Future<void> add(HomeItem item) async {
    final previous = state.valueOrNull ?? const <HomeItem>[];
    final created = await ref.read(homeItemRepositoryProvider).createItem(item);
    state = AsyncData([created, ...previous]);
  }
}
