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
    expect(find.byKey(const ValueKey('household-create-invite')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('household-member-email')), 'guest@example.com');
    await tester.tap(find.byKey(const ValueKey('household-add-member')));
    await tester.pumpAndSettle();

    expect(find.text('guest'), findsOneWidget);

    final removeAnna = find.byKey(const ValueKey('household-remove-member-mock-member-anna'));
    await tester.ensureVisible(removeAnna);
    await tester.tap(removeAnna);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить участника'));
    await tester.pumpAndSettle();

    expect(find.text('Анна'), findsNothing);
    expect(find.text('guest'), findsOneWidget);
  });

  testWidgets('owner can create a one-time invite code with a selected lifetime', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('household-switcher-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('household-members-action')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('household-create-invite')));
    await tester.pumpAndSettle();

    expect(find.text('Срок действия кода'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('household-invite-lifetime-72')));
    await tester.pumpAndSettle();

    expect(find.text('Код приглашения'), findsOneWidget);
    expect(find.textContaining('HL-MOCK'), findsOneWidget);
    expect(find.text('Код создан. Передайте его участнику.'), findsOneWidget);
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
    expect(find.byKey(const ValueKey('household-create-invite')), findsNothing);
    expect(find.byKey(const ValueKey('household-remove-member-another-demo-user')), findsNothing);
  });
}
