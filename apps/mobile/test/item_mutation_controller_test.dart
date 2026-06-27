import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/dashboard/presentation/item_list_controller.dart';
import 'package:home_ledger/features/items/data/home_item_repository.dart';
import 'package:home_ledger/features/items/domain/home_item.dart';

class MutableRepository implements HomeItemRepository {
  MutableRepository(this.item);

  HomeItem item;

  @override
  Future<void> archiveItem(String itemId) async {}

  @override
  Future<HomeItem> createItem(HomeItem value) async => value;

  @override
  Future<List<HomeItem>> loadItems() async => [item];

  @override
  Future<HomeItem> updateItem(HomeItem value) async {
    item = value;
    return value;
  }
}

void main() {
  test('updates and archives the local inventory state', () async {
    const original = HomeItem(id: 'router', name: 'Router', category: 'electronics');
    final container = ProviderContainer(
      overrides: [homeItemRepositoryProvider.overrideWithValue(MutableRepository(original))],
    );
    addTearDown(container.dispose);

    await container.read(itemListControllerProvider.future);
    const updated = HomeItem(id: 'router', name: 'Office router', category: 'electronics');
    await container.read(itemListControllerProvider.notifier).update(updated);
    expect(container.read(itemListControllerProvider).valueOrNull!.single.name, 'Office router');

    await container.read(itemListControllerProvider.notifier).archive(updated.id);
    expect(container.read(itemListControllerProvider).valueOrNull, isEmpty);
  });
}
