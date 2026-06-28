import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/features/items/domain/warranty_health.dart';

void main() {
  final referenceDate = DateTime(2026, 6, 28);

  test('classifies warranty health across expired, expiring, and protected ranges', () {
    expect(resolveWarrantyHealth(null, now: referenceDate), WarrantyHealth.none);
    expect(
      resolveWarrantyHealth(DateTime(2026, 6, 27), now: referenceDate),
      WarrantyHealth.expired,
    );
    expect(
      resolveWarrantyHealth(DateTime(2026, 6, 28), now: referenceDate),
      WarrantyHealth.expiring,
    );
    expect(
      resolveWarrantyHealth(DateTime(2026, 8, 12), now: referenceDate),
      WarrantyHealth.expiring,
    );
    expect(
      resolveWarrantyHealth(DateTime(2026, 8, 13), now: referenceDate),
      WarrantyHealth.protected,
    );
  });
}
