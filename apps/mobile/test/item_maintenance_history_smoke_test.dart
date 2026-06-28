import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('item detail shows only its own maintenance history', (tester) async {
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

    final routerCompletion = find.byKey(const ValueKey('maintenance-complete-demo-router-restart'));
    await tester.ensureVisible(routerCompletion);
    await tester.tap(routerCompletion);
    await tester.pumpAndSettle();

    final navigationBar = find.byType(NavigationBar);
    final navigationBounds = tester.getRect(navigationBar);
    await tester.tapAt(
      Offset(
        navigationBounds.left + navigationBounds.width / 6,
        navigationBounds.center.dy,
      ),
    );
    await tester.pumpAndSettle();

    final washerItem = find.text('Washing machine');
    await tester.ensureVisible(washerItem);
    await tester.tap(washerItem);
    await tester.pumpAndSettle();

    final historyAction = find.byKey(const ValueKey('item-maintenance-history-action'));
    await tester.ensureVisible(historyAction);
    await tester.tap(historyAction);
    await tester.pumpAndSettle();

    expect(find.text('История обслуживания: Washing machine'), findsOneWidget);
    expect(find.byKey(const ValueKey('maintenance-history-mock-completion-1')), findsOneWidget);
    expect(find.text('Clean the washing machine filter'), findsOneWidget);
    expect(find.text('Review router firmware'), findsNothing);
  });
}
