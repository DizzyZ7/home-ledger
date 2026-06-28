import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';
import 'package:home_ledger/features/households/data/household_repository.dart';

void main() {
  testWidgets('mock user joins a household with the documented demo invitation code', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('household-switcher-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('household-accept-invite-action')));
    await tester.pumpAndSettle();

    expect(find.text('Вступить по коду'), findsWidgets);
    expect(find.textContaining('Демо-код:'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('household-invite-code')),
      MockHouseholdRepository.demoIncomingInviteCode,
    );
    await tester.tap(find.byKey(const ValueKey('household-accept-invite')));
    await tester.pumpAndSettle();

    expect(find.text('Вы присоединились к дому.'), findsOneWidget);
    expect(find.text('Дом друзей'), findsOneWidget);
    expect(find.text('Активный дом'), findsOneWidget);
  });
}
