import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/dashboard/presentation/item_list_controller.dart';
import 'package:home_ledger/features/items/data/home_item_repository.dart';
import 'package:home_ledger/features/items/domain/home_item.dart';

class FakeHomeItemRepository implements HomeItemRepository {
  FakeHomeItemRepository(this._items, {List<HomeItem>? archivedItems})
      : _archivedItems = archivedItems ?? [];

  final List<HomeItem> _items;
  final List<HomeItem> _archivedItems;

  @override
  Future<void> archiveItem(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    _archivedItems.add(_items.removeAt(index));
  }

  @override
  Future<HomeItem> createItem(HomeItem item) async {
    _items.insert(0, item);
    return item;
  }

  @override
  Future<List<HomeItem>> loadArchivedItems() async => List.unmodifiable(_archivedItems);

  @override
  Future<List<HomeItem>> loadItems() async => List.unmodifiable(_items);

  @override
  Future<HomeItem> restoreItem(String itemId) async {
    final index = _archivedItems.indexWhere((item) => item.id == itemId);
    final item = _archivedItems.removeAt(index);
    _items.insert(0, item);
    return item;
  }

  @override
  Future<HomeItem> updateItem(HomeItem item) async {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    _items[index] = item;
    return item;
  }
}

void main() {
  test('loads items and prepends a newly created item', () async {
    final repository = FakeHomeItemRepository([
      const HomeItem(id: 'first', name: 'Router', category: 'electronics'),
    ]);
    final container = ProviderContainer(
      overrides: [homeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final initial = await container.read(itemListControllerProvider.future);
    expect(initial.single.name, 'Router');

    await container.read(itemListControllerProvider.notifier).add(
          const HomeItem(id: 'second', name: 'Kettle', category: 'appliance'),
        );

    final state = container.read(itemListControllerProvider);
    expect(state.valueOrNull?.first.name, 'Kettle');
  });

  test('update and archive keep the visible inventory state synchronized', () async {
    final original = HomeItem(id: 'router', name: 'Router', category: 'electronics');
    final edited = HomeItem(
      id: 'router',
      name: 'Home router',
      category: 'electronics',
      serialNumber: 'SN-42',
    );
    final repository = FakeHomeItemRepository([original]);
    final container = ProviderContainer(
      overrides: [homeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(itemListControllerProvider.future);
    await container.read(itemListControllerProvider.notifier).updateItem(edited);

    expect(container.read(itemListControllerProvider).valueOrNull!.single.name, 'Home router');
    expect(container.read(itemListControllerProvider).valueOrNull!.single.serialNumber, 'SN-42');

    await container.read(itemListControllerProvider.notifier).archiveItem(edited.id);

    expect(container.read(itemListControllerProvider).valueOrNull, isEmpty);
  });
}
