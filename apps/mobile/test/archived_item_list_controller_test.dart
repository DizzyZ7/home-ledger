import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/dashboard/presentation/item_list_controller.dart';
import 'package:home_ledger/features/items/data/home_item_repository.dart';
import 'package:home_ledger/features/items/domain/home_item.dart';
import 'package:home_ledger/features/items/presentation/archived_item_list_controller.dart';

class FakeArchivedItemRepository implements HomeItemRepository {
  FakeArchivedItemRepository({required List<HomeItem> active, required List<HomeItem> archived})
      : _active = active,
        _archived = archived;

  final List<HomeItem> _active;
  final List<HomeItem> _archived;

  @override
  Future<void> archiveItem(String itemId) async {
    final index = _active.indexWhere((item) => item.id == itemId);
    _archived.add(_active.removeAt(index));
  }

  @override
  Future<HomeItem> createItem(HomeItem item) async {
    _active.insert(0, item);
    return item;
  }

  @override
  Future<List<HomeItem>> loadArchivedItems() async => List.unmodifiable(_archived);

  @override
  Future<List<HomeItem>> loadItems() async => List.unmodifiable(_active);

  @override
  Future<HomeItem> restoreItem(String itemId) async {
    final index = _archived.indexWhere((item) => item.id == itemId);
    final restored = _archived.removeAt(index);
    _active.insert(0, restored);
    return restored;
  }

  @override
  Future<HomeItem> updateItem(HomeItem item) async {
    final index = _active.indexWhere((existing) => existing.id == item.id);
    _active[index] = item;
    return item;
  }
}

void main() {
  test('restoring removes an item from archive and returns it to active inventory', () async {
    const active = HomeItem(id: 'active', name: 'Router', category: 'electronics');
    const archived = HomeItem(id: 'archived', name: 'Kettle', category: 'appliance');
    final repository = FakeArchivedItemRepository(active: [active], archived: [archived]);
    final container = ProviderContainer(
      overrides: [homeItemRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(itemListControllerProvider.future);
    final initialArchive = await container.read(archivedItemListControllerProvider.future);
    expect(initialArchive.single.id, 'archived');

    await container.read(archivedItemListControllerProvider.notifier).restoreItem('archived');

    expect(container.read(archivedItemListControllerProvider).valueOrNull, isEmpty);
    expect(
      container.read(itemListControllerProvider).valueOrNull!.map((item) => item.id),
      ['archived', 'active'],
    );
  });
}
