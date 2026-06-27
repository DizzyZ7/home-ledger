import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock workspace opens the maintenance task form', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Обслуживание'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить задачу'));
    await tester.pumpAndSettle();

    expect(find.text('Что нужно сделать'), findsOneWidget);
    expect(find.text('Периодичность, дней'), findsOneWidget);
    expect(find.textContaining('Следующее обслуживание'), findsOneWidget);
    expect(find.text('Wi-Fi router'), findsOneWidget);
  });
}
