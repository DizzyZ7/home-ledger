import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/dashboard/presentation/item_list_controller.dart';
import 'package:home_ledger/features/items/data/home_item_repository.dart';
import 'package:home_ledger/features/items/domain/home_item.dart';

class FakeRepository implements HomeItemRepository {
  final List<HomeItem> _items = [const HomeItem(id: 'first', name: 'Router', category: 'electronics')];

  @override
  Future<HomeItem> createItem(HomeItem item) async {
    _items.add(item);
    return item;
  }

  @override
  Future<List<HomeItem>> loadItems() async => List.unmodifiable(_items);
}

void main() {
  test('loads items and prepends a newly created item', () async {
    final container = ProviderContainer(
      overrides: [homeItemRepositoryProvider.overrideWithValue(FakeRepository())],
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
}
