import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_ledger/app.dart';

void main() {
  testWidgets('mock workspace shows and creates maintenance from a selected inventory item', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wi-Fi router'));
    await tester.pumpAndSettle();

    expect(find.text('Карточка вещи'), findsOneWidget);
    expect(find.text('Wi-Fi router'), findsOneWidget);
    expect(find.text('Серийный номер'), findsOneWidget);
    expect(find.text('Обслуживание'), findsOneWidget);
    expect(find.text('Review router firmware'), findsOneWidget);
    expect(find.text('Clean the washing machine filter'), findsNothing);

    await tester.tap(find.text('Добавить задачу'));
    await tester.pumpAndSettle();

    expect(find.text('Добавить задачу'), findsOneWidget);
    expect(find.text('Wi-Fi router'), findsOneWidget);
    expect(find.text('Что нужно сделать'), findsOneWidget);
  });

  testWidgets('mock workspace completes maintenance from a selected inventory item', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: HomeLedgerApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wi-Fi router'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Отметить выполненным'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Задача выполнена. Следующая дата обновлена.'), findsOneWidget);
    expect(find.text('Review router firmware'), findsOneWidget);
  });
}
