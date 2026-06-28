enum WarrantyHealth {
  none,
  expired,
  expiring,
  protected;
}

WarrantyHealth resolveWarrantyHealth(
  DateTime? warrantyExpiresAt, {
  DateTime? now,
  int expiringWindowDays = 45,
}) {
  if (warrantyExpiresAt == null) {
    return WarrantyHealth.none;
  }

  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final deadline = today.add(Duration(days: expiringWindowDays));
  final warrantyDate = DateTime(
    warrantyExpiresAt.year,
    warrantyExpiresAt.month,
    warrantyExpiresAt.day,
  );

  if (warrantyDate.isBefore(today)) {
    return WarrantyHealth.expired;
  }
  if (!warrantyDate.isAfter(deadline)) {
    return WarrantyHealth.expiring;
  }
  return WarrantyHealth.protected;
}
