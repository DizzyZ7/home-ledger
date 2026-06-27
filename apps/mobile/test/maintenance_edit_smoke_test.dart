import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock workspace opens an existing maintenance task for editing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Обслуживание'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Редактировать задачу').first);
    await tester.pumpAndSettle();

    expect(find.text('Редактировать задачу'), findsOneWidget);
    expect(find.text('Washing machine'), findsOneWidget);
    expect(find.text('Периодичность, дней'), findsOneWidget);
  });
}
