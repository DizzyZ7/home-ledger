import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/household_repository.dart';
import '../domain/household_invite.dart';
import 'active_household_provider.dart';

final householdInvitesProvider = FutureProvider.autoDispose<List<HouseholdInvite>>((ref) async {
  ref.watch(activeHouseholdIdProvider);
  return ref.watch(householdRepositoryProvider).loadInvites();
});
