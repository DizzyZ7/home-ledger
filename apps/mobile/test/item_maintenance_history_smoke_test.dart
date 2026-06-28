import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';
import 'package:home_ledger/features/maintenance/presentation/maintenance_list_controller.dart';

void main() {
  testWidgets('item detail shows only its own maintenance history', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const HomeLedgerApp(),
      ),
    );
    await tester.pumpAndSettle();

    await container.read(maintenanceListControllerProvider.future);
    await container.read(maintenanceListControllerProvider.notifier).completeTask('demo-clean-filter');
    await container.read(maintenanceListControllerProvider.notifier).completeTask('demo-router-restart');

    container.read(appRouterProvider).go('/items/demo-washer');
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
