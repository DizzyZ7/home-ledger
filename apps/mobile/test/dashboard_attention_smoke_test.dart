import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock dashboard routes warranty attention to the warranty overview', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('warranty-attention-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('maintenance-attention-card')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('warranty-attention-card')));
    await tester.pumpAndSettle();

    expect(find.text('Скоро заканчиваются'), findsOneWidget);
    expect(find.text('Wi-Fi router'), findsOneWidget);
  });

  testWidgets('mock dashboard routes maintenance attention to maintenance work', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('maintenance-attention-card')));
    await tester.pumpAndSettle();

    expect(find.text('Обслуживание'), findsOneWidget);
  });
}
