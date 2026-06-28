import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('owner can add and remove a household member', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('household-switcher-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('household-members-action')));
    await tester.pumpAndSettle();

    expect(find.text('Участники дома'), findsWidgets);
    expect(find.text('Анна'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('household-member-email')), 'guest@example.com');
    await tester.tap(find.byKey(const ValueKey('household-add-member')));
    await tester.pumpAndSettle();

    expect(find.text('guest'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('household-remove-member-mock-member-anna')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить участника'));
    await tester.pumpAndSettle();

    expect(find.text('Анна'), findsNothing);
  });

  testWidgets('member sees household roster without owner controls', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('household-switcher-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('household-select-mock-shared-household')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('household-switcher-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('household-members-action')));
    await tester.pumpAndSettle();

    expect(find.text('Только владелец дома может менять состав участников.'), findsOneWidget);
    expect(find.byKey(const ValueKey('household-add-member')), findsNothing);
    expect(find.byKey(const ValueKey('household-remove-member-another-demo-user')), findsNothing);
  });
}
