import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/items/domain/home_item.dart';

void main() {
  test('serializes create payload dates without a time component', () {
    final item = HomeItem(
      id: 'local-id',
      name: 'Kettle',
      category: 'appliance',
      purchaseDate: DateTime(2026, 6, 27, 13, 45),
      warrantyExpiresAt: DateTime(2028, 6, 27, 23, 59),
    );

    final payload = item.toCreatePayload();

    expect(payload['id'], isNull);
    expect(payload['purchase_date'], '2026-06-27');
    expect(payload['warranty_expires_at'], '2028-06-27');
  });
}
