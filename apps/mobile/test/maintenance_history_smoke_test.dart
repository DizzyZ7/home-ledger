import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock completion appears in maintenance history immediately', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Обслуживание'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('maintenance-complete-demo-clean-filter')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('maintenance-history-action')));
    await tester.pumpAndSettle();

    expect(find.text('История обслуживания'), findsOneWidget);
    expect(find.byKey(const ValueKey('maintenance-history-mock-completion-1')), findsOneWidget);
    expect(find.text('Clean the washing machine filter'), findsOneWidget);
    expect(find.textContaining('Washing machine'), findsOneWidget);
  });
}
