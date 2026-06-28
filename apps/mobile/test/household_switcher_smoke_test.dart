import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock workspace switches the active household from inventory', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('household-switcher-action')));
    await tester.pumpAndSettle();

    expect(find.text('Дом'), findsOneWidget);
    expect(find.text('Мой дом'), findsOneWidget);
    expect(find.text('Дом с соседями'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('household-select-mock-shared-household')));
    await tester.pumpAndSettle();

    expect(find.text('Мои вещи'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('household-switcher-action')));
    await tester.pumpAndSettle();

    final sharedHousehold = tester.widget<ListTile>(
      find.byKey(const ValueKey('household-select-mock-shared-household')),
    );
    expect(sharedHousehold.enabled, isFalse);
    expect(find.text('Активный дом'), findsOneWidget);
  });
}
