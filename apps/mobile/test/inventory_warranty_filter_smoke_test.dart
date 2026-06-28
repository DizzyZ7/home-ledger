import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock inventory filters between expiring and protected warranties', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('inventory-warranty-filter-expiring')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('warranty-status-demo-router')), findsOneWidget);
    expect(find.byKey(const ValueKey('warranty-status-demo-washer')), findsNothing);

    final protectedFilter = find.byKey(const ValueKey('inventory-warranty-filter-protected'));
    await tester.ensureVisible(protectedFilter);
    await tester.pumpAndSettle();
    await tester.tap(protectedFilter);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('warranty-status-demo-router')), findsNothing);
    expect(find.byKey(const ValueKey('warranty-status-demo-washer')), findsOneWidget);
  });
}
