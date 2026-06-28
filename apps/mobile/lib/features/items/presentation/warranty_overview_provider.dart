import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/household_scoped_repositories.dart';
import '../domain/home_item.dart';
import '../domain/warranty_state.dart';

class WarrantyOverview {
  const WarrantyOverview({
    required this.expiredItems,
    required this.expiringItems,
  });

  final List<HomeItem> expiredItems;
  final List<HomeItem> expiringItems;
}

final warrantyOverviewProvider = FutureProvider.autoDispose<WarrantyOverview>((ref) async {
  final repository = ref.watch(householdScopedHomeItemRepositoryProvider);
  final results = await Future.wait([
    repository.loadWarrantyItems(state: WarrantyState.expired),
    repository.loadWarrantyItems(state: WarrantyState.expiring),
  ]);
  return WarrantyOverview(
    expiredItems: results[0],
    expiringItems: results[1],
  );
});
