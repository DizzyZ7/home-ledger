import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/household_repository.dart';
import '../domain/household_member.dart';
import 'active_household_provider.dart';

final currentHouseholdProvider = FutureProvider.autoDispose<HouseholdDetail>((ref) async {
  ref.watch(activeHouseholdIdProvider);
  return ref.watch(householdRepositoryProvider).loadCurrentHousehold();
});
