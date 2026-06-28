import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/dashboard/presentation/inventory_search.dart';
import 'package:home_ledger/features/items/domain/home_item.dart';

void main() {
  const router = HomeItem(
    id: 'router',
    name: 'Wi-Fi router',
    category: 'electronics',
    location: 'Living room',
    serialNumber: 'RT-42-A',
    notes: 'Main network device',
  );
  const washer = HomeItem(
    id: 'washer',
    name: 'Washing machine',
    category: 'appliance',
    location: 'Bathroom',
    serialNumber: 'WM-100',
  );

  test('matches inventory fields case-insensitively and preserves source order', () {
    final items = [router, washer];

    expect(filterInventoryItems(items, 'router'), [router]);
    expect(filterInventoryItems(items, 'bathroom'), [washer]);
    expect(filterInventoryItems(items, 'rt-42'), [router]);
    expect(filterInventoryItems(items, 'network'), [router]);
    expect(filterInventoryItems(items, '   '), items);
    expect(filterInventoryItems(items, 'missing'), isEmpty);
  });
}
