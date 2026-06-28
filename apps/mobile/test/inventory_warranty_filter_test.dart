import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/dashboard/presentation/inventory_warranty_filter.dart';
import 'package:home_ledger/features/items/domain/home_item.dart';

void main() {
  final referenceDate = DateTime(2026, 6, 28);
  final noWarranty = HomeItem(id: 'none', name: 'Paper manual', category: 'documents');
  final expired = HomeItem(
    id: 'expired',
    name: 'Old router',
    category: 'electronics',
    warrantyExpiresAt: DateTime(2026, 6, 27),
  );
  final expiring = HomeItem(
    id: 'expiring',
    name: 'New router',
    category: 'electronics',
    warrantyExpiresAt: DateTime(2026, 8, 12),
  );
  final protected = HomeItem(
    id: 'protected',
    name: 'Washer',
    category: 'appliance',
    warrantyExpiresAt: DateTime(2026, 8, 13),
  );
  final items = [noWarranty, expired, expiring, protected];

  test('filters inventory by each warranty health state while preserving source order', () {
    expect(
      filterInventoryByWarrantyHealth(
        items,
        filter: InventoryWarrantyFilter.all,
        now: referenceDate,
      ),
      items,
    );
    expect(
      filterInventoryByWarrantyHealth(
        items,
        filter: InventoryWarrantyFilter.none,
        now: referenceDate,
      ),
      [noWarranty],
    );
    expect(
      filterInventoryByWarrantyHealth(
        items,
        filter: InventoryWarrantyFilter.expired,
        now: referenceDate,
      ),
      [expired],
    );
    expect(
      filterInventoryByWarrantyHealth(
        items,
        filter: InventoryWarrantyFilter.expiring,
        now: referenceDate,
      ),
      [expiring],
    );
    expect(
      filterInventoryByWarrantyHealth(
        items,
        filter: InventoryWarrantyFilter.protected,
        now: referenceDate,
      ),
      [protected],
    );
  });
}
