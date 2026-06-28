import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock dashboard filters inventory and exposes empty search state', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('inventory-search-input')), 'bathroom');
    await tester.pumpAndSettle();

    expect(find.text('Washing machine'), findsOneWidget);
    expect(find.text('Wi-Fi router'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('inventory-search-input')), 'missing');
    await tester.pumpAndSettle();

    expect(find.text('Ничего не найдено'), findsOneWidget);
  });
}
