import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/screens/home.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/formBalance/form_balance.dart';

import '../fakes.dart';
import '../helpers.dart';

void main() {
  setUpAll(setUpPtBr);

  Future<void> pumpHome(WidgetTester tester, FakeBalanceRepository repo) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.defaultTheme,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          ...GlobalMaterialLocalizations.delegates,
          FormBuilderLocalizations.delegate,
        ],
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

  Future<void> openFormAndSave(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    Finder field(String name) => find.byWidgetPredicate(
      (w) => w is FormBuilderTextField && w.name == name,
    );
    await tester.enterText(field('name'), 'Mercado');
    await tester.enterText(field('value'), '5000');
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('salvar fecha o modal e recarrega', (tester) async {
    final repo = FakeBalanceRepository(data: {});
    await pumpHome(tester, repo);

    await openFormAndSave(tester);

    expect(find.byType(FormBalance), findsNothing);
    expect(repo.createCalls, 1);
    expect(repo.lastCreatedValue, 50.0);
    expect(repo.getCalls, 2);
  });

  testWidgets('erro ao salvar mantém o modal e avisa', (tester) async {
    final repo = FakeBalanceRepository(data: {})..saveError = Exception('x');
    await pumpHome(tester, repo);

    await openFormAndSave(tester);

    expect(find.byType(FormBalance), findsOneWidget);
    expect(find.text('Não foi possível salvar'), findsOneWidget);
  });
}
