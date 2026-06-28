import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock workspace filters overdue and upcoming maintenance tasks', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Обслуживание'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Просроченные (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Clean the washing machine filter'), findsOneWidget);
    expect(find.text('Review router firmware'), findsNothing);

    await tester.tap(find.text('Ближайшие (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Review router firmware'), findsOneWidget);
    expect(find.text('Clean the washing machine filter'), findsNothing);
  });
}
