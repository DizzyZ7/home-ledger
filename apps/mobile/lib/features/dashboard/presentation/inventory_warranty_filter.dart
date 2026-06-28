import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../items/domain/home_item.dart';
import '../../items/domain/warranty_health.dart';
import '../../items/presentation/warranty_status_localizations.dart';

enum InventoryWarrantyFilter { all, none, expired, expiring, protected }

final inventoryWarrantyFilterProvider = StateProvider.autoDispose<InventoryWarrantyFilter>((ref) {
  return InventoryWarrantyFilter.all;
});

List<HomeItem> filterInventoryByWarrantyHealth(
  Iterable<HomeItem> items, {
  required InventoryWarrantyFilter filter,
  DateTime? now,
}) {
  if (filter == InventoryWarrantyFilter.all) {
    return List.unmodifiable(items.toList(growable: false));
  }

  final expectedHealth = switch (filter) {
    InventoryWarrantyFilter.none => WarrantyHealth.none,
    InventoryWarrantyFilter.expired => WarrantyHealth.expired,
    InventoryWarrantyFilter.expiring => WarrantyHealth.expiring,
    InventoryWarrantyFilter.protected => WarrantyHealth.protected,
    InventoryWarrantyFilter.all => throw ArgumentError.value(filter),
  };

  return List.unmodifiable(
    items.where((item) => resolveWarrantyHealth(item.warrantyExpiresAt, now: now) == expectedHealth).toList(),
  );
}

String inventoryWarrantyFilterLabel(BuildContext context, InventoryWarrantyFilter filter) {
  final l10n = context.l10n;
  return switch (filter) {
    InventoryWarrantyFilter.all => l10n.languageCode == 'ru' ? 'Все' : 'All',
    InventoryWarrantyFilter.none => l10n.warrantyHealthLabel(WarrantyHealth.none),
    InventoryWarrantyFilter.expired => l10n.warrantyHealthLabel(WarrantyHealth.expired),
    InventoryWarrantyFilter.expiring => l10n.warrantyHealthLabel(WarrantyHealth.expiring),
    InventoryWarrantyFilter.protected => l10n.warrantyHealthLabel(WarrantyHealth.protected),
  };
}

String inventoryWarrantyFilterEmptyTitle(BuildContext context, InventoryWarrantyFilter filter) {
  final l10n = context.l10n;
  return switch (filter) {
    InventoryWarrantyFilter.none => l10n.languageCode == 'ru' ? 'Нет вещей без гарантии' : 'No items without a warranty',
    InventoryWarrantyFilter.expired => l10n.languageCode == 'ru' ? 'Нет вещей с истекшей гарантией' : 'No items with an expired warranty',
    InventoryWarrantyFilter.expiring => l10n.languageCode == 'ru' ? 'Нет вещей с истекающей гарантией' : 'No items with an expiring warranty',
    InventoryWarrantyFilter.protected => l10n.languageCode == 'ru' ? 'Нет вещей с действующей гарантией' : 'No items with an active warranty',
    InventoryWarrantyFilter.all => l10n.languageCode == 'ru' ? 'Инвентарь пуст' : 'Inventory is empty',
  };
}

class InventoryWarrantyFilterBar extends StatelessWidget {
  const InventoryWarrantyFilterBar({
    required this.items,
    required this.selectedFilter,
    required this.onSelected,
    super.key,
  });

  final List<HomeItem> items;
  final InventoryWarrantyFilter selectedFilter;
  final ValueChanged<InventoryWarrantyFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = [
      InventoryWarrantyFilter.all,
      InventoryWarrantyFilter.expiring,
      InventoryWarrantyFilter.expired,
      InventoryWarrantyFilter.protected,
      InventoryWarrantyFilter.none,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            FilterChip(
              key: ValueKey('inventory-warranty-filter-${filter.name}'),
              label: Text(
                '${inventoryWarrantyFilterLabel(context, filter)} '
                '(${filterInventoryByWarrantyHealth(items, filter: filter).length})',
              ),
              selected: selectedFilter == filter,
              onSelected: (_) => onSelected(filter),
            ),
            if (filter != filters.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
