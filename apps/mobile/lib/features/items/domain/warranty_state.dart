enum WarrantyState {
  expired,
  expiring,
  valid,
  none;

  String get apiValue => name;
}
