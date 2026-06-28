import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/items/data/home_item_repository.dart';
import 'package:home_ledger/features/items/domain/home_item.dart';
import 'package:home_ledger/features/items/domain/warranty_state.dart';

void main() {
  final referenceDate = DateTime(2026, 6, 28);
  final items = [
    HomeItem(
      id: 'expired',
      name: 'Expired router',
      category: 'electronics',
      warrantyExpiresAt: DateTime(2026, 6, 27),
    ),
    HomeItem(
      id: 'soon',
      name: 'Soon toaster',
      category: 'appliance',
      warrantyExpiresAt: DateTime(2026, 6, 30),
    ),
    HomeItem(
      id: 'later',
      name: 'Later washer',
      category: 'appliance',
      warrantyExpiresAt: DateTime(2026, 7, 12),
    ),
    HomeItem(
      id: 'valid',
      name: 'Protected laptop',
      category: 'electronics',
      warrantyExpiresAt: DateTime(2026, 8, 13),
    ),
    const HomeItem(id: 'none', name: 'No warranty tool', category: 'tool'),
  ];

  test('classifies active warranty states and orders nearest dates first', () {
    expect(
      filterWarrantyItems(items, state: WarrantyState.expired, now: referenceDate)
          .map((item) => item.id),
      ['expired'],
    );
    expect(
      filterWarrantyItems(items, state: WarrantyState.expiring, now: referenceDate)
          .map((item) => item.id),
      ['soon', 'later'],
    );
    expect(
      filterWarrantyItems(items, state: WarrantyState.valid, now: referenceDate)
          .map((item) => item.id),
      ['valid'],
    );
    expect(
      filterWarrantyItems(items, state: WarrantyState.none, now: referenceDate)
          .map((item) => item.id),
      ['none'],
    );
  });
}
