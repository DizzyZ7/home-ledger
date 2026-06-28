import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('owner creates and renames an active household', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('household-switcher-action')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('household-create-action')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('household-name-input')), 'Дача');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    final createdHousehold = find.byKey(const ValueKey('household-select-mock-created-household-1'));
    expect(createdHousehold, findsOneWidget);
    expect(tester.widget<ListTile>(createdHousehold).enabled, isFalse);
    expect(find.text('Дача'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('household-rename-action')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('household-name-input')), 'Дача у озера');
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Дача у озера'), findsOneWidget);
  });

  testWidgets('household member can create a personal home but cannot rename a shared home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('household-switcher-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('household-select-mock-shared-household')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('household-switcher-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('household-create-action')), findsOneWidget);
    expect(find.byKey(const ValueKey('household-rename-action')), findsNothing);
  });
}
