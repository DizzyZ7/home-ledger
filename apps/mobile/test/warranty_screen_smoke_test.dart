import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock workspace opens the warranty overview', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Гарантии'));
    await tester.pumpAndSettle();

    expect(find.text('Скоро заканчиваются'), findsOneWidget);
    expect(find.text('Wi-Fi router'), findsOneWidget);
    expect(find.text('Нет истекших гарантий'), findsOneWidget);
  });
}
