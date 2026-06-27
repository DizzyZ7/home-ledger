import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock workspace opens a selected inventory item', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wi-Fi router'));
    await tester.pumpAndSettle();

    expect(find.text('Карточка вещи'), findsOneWidget);
    expect(find.text('Wi-Fi router'), findsOneWidget);
    expect(find.text('Серийный номер'), findsOneWidget);
  });
}
