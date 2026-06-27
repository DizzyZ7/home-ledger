import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock workspace renders the inventory dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    expect(find.text('Мои вещи'), findsOneWidget);
    expect(find.text('Wi-Fi router'), findsOneWidget);
  });
}
