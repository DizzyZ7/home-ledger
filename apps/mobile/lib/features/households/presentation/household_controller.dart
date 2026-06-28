import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dashboard/presentation/item_list_controller.dart';
import '../../items/data/home_item_repository.dart';
import '../../items/presentation/archived_item_list_controller.dart';
import '../../items/presentation/warranty_overview_provider.dart';
import '../../maintenance/data/maintenance_repository.dart';
import '../../maintenance/presentation/maintenance_history_controller.dart';
import '../../maintenance/presentation/maintenance_list_controller.dart';
import '../data/household_repository.dart';
import '../domain/household_summary.dart';
import 'active_household_provider.dart';

final householdControllerProvider =
    AsyncNotifierProvider<HouseholdController, List<HouseholdSummary>>(HouseholdController.new);

class HouseholdController extends AsyncNotifier<List<HouseholdSummary>> {
  @override
  FutureOr<List<HouseholdSummary>> build() async {
    final households = await ref.read(householdRepositoryProvider).loadHouseholds();
    _applyActiveHousehold(households);
    return households;
  }

  Future<void> selectHousehold(String householdId) async {
    final selected = await ref.read(householdRepositoryProvider).selectHousehold(householdId);
    final current = state.valueOrNull ?? const <HouseholdSummary>[];
    final updated = [
      for (final household in current)
        household.copyWith(isActive: household.id == selected.id),
    ];
    state = AsyncData(updated);
    _applyActiveHousehold(updated);
    _invalidateHouseholdData();
  }

  void _applyActiveHousehold(List<HouseholdSummary> households) {
    final active = households.where((household) => household.isActive).firstOrNull;
    if (active == null) {
      return;
    }
    ref.read(activeHouseholdIdProvider.notifier).state = active.id;
  }

  void _invalidateHouseholdData() {
    ref.invalidate(homeItemRepositoryProvider);
    ref.invalidate(maintenanceRepositoryProvider);
    ref.invalidate(itemListControllerProvider);
    ref.invalidate(archivedItemListControllerProvider);
    ref.invalidate(warrantyOverviewProvider);
    ref.invalidate(maintenanceListControllerProvider);
    ref.invalidate(maintenanceHistoryProvider(null));
  }
}
