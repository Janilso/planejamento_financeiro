import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/screens/home.dart';
import 'package:planejamento_financeiro/theme/theme.dart';

import '../fakes.dart';
import '../helpers.dart';

void main() {
  setUpAll(setUpPtBr);

  Future<void> pumpHome(WidgetTester tester, FakeBalanceRepository repo) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.defaultTheme,
        home: HomeScreen(repository: repo, clock: () => DateTime(2026, 11, 25)),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('busca uma vez e cada aba mostra o próprio mês', (tester) async {
    final repo = FakeBalanceRepository(
      data: {
        'NOV/26': {
          'gains': [balanceJson('Salário', 1500, 'gains')],
          'expenses': [],
        },
        'DEZ/26': {
          'gains': [],
          'expenses': [
            balanceJson(
              'Aluguel',
              1300,
              'expenses',
              date: '2026-12-15T12:00:00.000',
            ),
          ],
        },
      },
    );

    await pumpHome(tester, repo);
    expect(find.text('Salário'), findsOneWidget);

    await tester.tap(find.text('DEZ/26'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'GASTOS'));
    await tester.pumpAndSettle();

    expect(find.text('Aluguel'), findsOneWidget);
    expect(repo.getCalls, 1);
  });

  testWidgets('mostra erro com Tentar de novo', (tester) async {
    final repo = FakeBalanceRepository(error: Exception('sem rede'));

    await pumpHome(tester, repo);

    expect(
      find.text('Não foi possível carregar os lançamentos'),
      findsOneWidget,
    );
    await tester.tap(find.text('Tentar de novo'));
    await tester.pump();
    await tester.pump();

    expect(repo.getCalls, 2);
  });
}
