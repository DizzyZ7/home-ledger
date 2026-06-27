import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock workspace opens the archived inventory screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Архив'));
    await tester.pumpAndSettle();

    expect(find.text('Архив'), findsOneWidget);
    expect(find.text('Архив пуст'), findsOneWidget);
  });
}
