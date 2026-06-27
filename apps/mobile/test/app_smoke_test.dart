import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock workspace navigates from inventory to maintenance', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    expect(find.text('Мои вещи'), findsWidgets);
    expect(find.text('Wi-Fi router'), findsOneWidget);

    await tester.tap(find.text('Обслуживание'));
    await tester.pumpAndSettle();

    expect(find.text('Clean the washing machine filter'), findsOneWidget);
    expect(find.text('Review router firmware'), findsOneWidget);
  });

  testWidgets('mock workspace opens an inventory item detail card', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wi-Fi router'));
    await tester.pumpAndSettle();

    expect(find.text('Карточка вещи'), findsOneWidget);
    expect(find.text('RT-AX58U-DEMO'), findsOneWidget);
  });
}
