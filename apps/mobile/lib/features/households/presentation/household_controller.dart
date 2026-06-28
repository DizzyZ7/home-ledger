import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/household_scoped_repositories.dart';
import '../../dashboard/presentation/item_list_controller.dart';
import '../../items/presentation/archived_item_list_controller.dart';
import '../../items/presentation/warranty_overview_provider.dart';
import '../../maintenance/presentation/maintenance_history_controller.dart';
import '../../maintenance/presentation/maintenance_list_controller.dart';
import '../data/household_repository.dart';
import '../domain/household_summary.dart';
import 'active_household_provider.dart';
import 'current_household_provider.dart';

final householdControllerProvider =
    AsyncNotifierProvider<HouseholdController, List<HouseholdSummary>>(HouseholdController.new);

class HouseholdController extends AsyncNotifier<List<HouseholdSummary>> {
  @override
  FutureOr<List<HouseholdSummary>> build() async {
    final households = await ref.read(householdRepositoryProvider).loadHouseholds();
    if (_applyActiveHousehold(households)) {
      _invalidateHouseholdData();
    }
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
    if (_applyActiveHousehold(updated)) {
      _invalidateHouseholdData();
    }
  }

  Future<void> createHousehold(String name) async {
    final created = await ref.read(householdRepositoryProvider).createHousehold(name);
    final current = state.valueOrNull ?? const <HouseholdSummary>[];
    final updated = [
      for (final household in current) household.copyWith(isActive: false),
      created,
    ];
    state = AsyncData(updated);
    if (_applyActiveHousehold(updated)) {
      _invalidateHouseholdData();
    }
  }

  Future<void> renameCurrentHousehold(String name) async {
    final renamed = await ref.read(householdRepositoryProvider).renameCurrentHousehold(name);
    final current = state.valueOrNull ?? const <HouseholdSummary>[];
    state = AsyncData([
      for (final household in current)
        if (household.id == renamed.id) renamed else household,
    ]);
    ref.invalidate(currentHouseholdProvider);
  }

  bool _applyActiveHousehold(List<HouseholdSummary> households) {
    for (final household in households) {
      if (household.isActive) {
        final current = ref.read(activeHouseholdIdProvider);
        if (current == household.id) {
          return false;
        }
        ref.read(activeHouseholdIdProvider.notifier).state = household.id;
        return true;
      }
    }
    return false;
  }

  void _invalidateHouseholdData() {
    ref.invalidate(householdScopedHomeItemRepositoryProvider);
    ref.invalidate(householdScopedMaintenanceRepositoryProvider);
    ref.invalidate(itemListControllerProvider);
    ref.invalidate(archivedItemListControllerProvider);
    ref.invalidate(warrantyOverviewProvider);
    ref.invalidate(maintenanceListControllerProvider);
    ref.invalidate(maintenanceHistoryProvider(null));
    ref.invalidate(currentHouseholdProvider);
  }
}
