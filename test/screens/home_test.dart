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

  Future<void> pumpHome(
    WidgetTester tester,
    FakeBalanceRepository repo, {
    Future<void> Function()? onLogout,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.defaultTheme,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          ...GlobalMaterialLocalizations.delegates,
          FormBuilderLocalizations.delegate,
        ],
        home: HomeScreen(
          repository: repo,
          clock: () => DateTime(2026, 11, 25),
          onLogout: onLogout,
        ),
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

  testWidgets('Sair pede confirmação e chama onLogout', (tester) async {
    var logouts = 0;
    await pumpHome(
      tester,
      FakeBalanceRepository(data: {}),
      onLogout: () async => logouts++,
    );

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(logouts, 0);

    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sair'));
    await tester.pumpAndSettle();
    expect(logouts, 1);
  });

  group('arrastar para excluir', () {
    FakeBalanceRepository repoWithTv() => FakeBalanceRepository(
      data: {
        'NOV/26': {
          'gains': [
            balanceJson(
              'TV',
              100,
              'gains',
              id: 'abc',
              installment: 2,
              totalInstallments: 3,
            ),
          ],
          'expenses': [],
        },
      },
    );

    Future<void> swipeTv(WidgetTester tester) async {
      await tester.drag(find.text('TV - 2/3'), const Offset(-700, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('só esta parcela', (tester) async {
      final repo = repoWithTv();
      await pumpHome(tester, repo);
      await swipeTv(tester);

      await tester.tap(find.text('Só esta parcela'));
      await tester.pumpAndSettle();

      expect(repo.calls, ['deleteInstallment abc 2']);
    });

    testWidgets('todas as parcelas', (tester) async {
      final repo = repoWithTv();
      await pumpHome(tester, repo);
      await swipeTv(tester);

      await tester.tap(find.text('Todas as parcelas'));
      await tester.pumpAndSettle();

      expect(repo.calls, ['deleteBalance abc']);
    });

    testWidgets('cancelar mantém o item', (tester) async {
      final repo = repoWithTv();
      await pumpHome(tester, repo);
      await swipeTv(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.calls, isEmpty);
      expect(find.text('TV - 2/3'), findsOneWidget);
    });

    testWidgets('falha na API mantém o item e avisa', (tester) async {
      final repo = repoWithTv()..saveError = Exception('sem rede');
      await pumpHome(tester, repo);
      await swipeTv(tester);

      await tester.tap(find.text('Só esta parcela'));
      await tester.pumpAndSettle();

      expect(find.text('TV - 2/3'), findsOneWidget);
      expect(find.text('Não foi possível excluir'), findsOneWidget);
    });
  });
}
