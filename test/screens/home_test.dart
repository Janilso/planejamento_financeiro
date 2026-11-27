import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/screens/home.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/widgets/balance_resume.dart';
import 'package:planejamento_financeiro/widgets/balance_tab_view.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/formBalance/form_balance.dart';
import 'package:planejamento_financeiro/widgets/load/load.dart';

import '../fakes.dart';
import '../helpers.dart';

void main() {
  setUpAll(setUpPtBr);

  Future<void> pumpHome(
    WidgetTester tester,
    FakeBalanceRepository repo, {
    Future<void> Function()? onLogout,
    int quadros = 2,
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
    for (var i = 0; i < quadros; i++) {
      await tester.pump();
    }
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

  Future<void> openMenuAndTapSair(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Mais opções'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
  }

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

    await openMenuAndTapSair(tester);
    expect(find.text('Sair da conta?'), findsOneWidget);
    expect(find.text('Seus lançamentos continuam salvos.'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(logouts, 0);

    await openMenuAndTapSair(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Sair'));
    await tester.pumpAndSettle();
    expect(logouts, 1);
  });

  testWidgets('sem barra de título', (tester) async {
    await pumpHome(tester, FakeBalanceRepository(data: {}));
    expect(find.text('GANHOS - Novembro 2026'), findsNothing);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('erro desativa o botão + até carregar de novo', (tester) async {
    final repo = FakeBalanceRepository(error: Exception('x'));
    await pumpHome(tester, repo);
    FloatingActionButton fab() =>
        tester.widget(find.byType(FloatingActionButton));
    expect(fab().onPressed, isNull);
    // Desativado, ele também parece desativado.
    expect(fab().backgroundColor!.a, lessThan(1));

    repo.error = null;
    repo.data = {};
    await tester.tap(find.text('Tentar de novo'));
    await tester.pump();
    await tester.pump();
    expect(fab().onPressed, isNotNull);
  });

  testWidgets('salvar avisa', (tester) async {
    await pumpHome(tester, FakeBalanceRepository(data: {}));
    await openFormAndSave(tester);
    expect(find.text('Lançamento salvo'), findsOneWidget);
  });

  testWidgets('botão + tem rótulo', (tester) async {
    await pumpHome(tester, FakeBalanceRepository(data: {}));
    expect(find.byTooltip('Novo lançamento'), findsOneWidget);
  });

  testWidgets('toque e rótulos na home', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester, FakeBalanceRepository(data: {}));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('fonte em 130% não estoura e mantém NOV/26 visível', (
    tester,
  ) async {
    final repo = FakeBalanceRepository(data: {});
    // Tela de celular, não os 800x600 padrão do teste.
    tester.view.physicalSize = const Size(392, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget app(double scale) => MaterialApp(
      theme: AppTheme.defaultTheme,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        FormBuilderLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: HomeScreen(repository: repo, clock: () => DateTime(2026, 11, 25)),
    );
    await tester.pumpWidget(app(1.0));
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(app(1.3));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final nov = tester.getRect(find.text('NOV/26'));
    final abas = tester.getRect(find.byType(TabBar).first);
    expect(abas.contains(nov.center), isTrue);
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
      await tester.drag(find.text('TV'), const Offset(-700, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('só esta parcela', (tester) async {
      final repo = repoWithTv();
      await pumpHome(tester, repo);
      await swipeTv(tester);

      await tester.tap(find.text('Só esta'));
      await tester.pumpAndSettle();

      expect(repo.calls, ['deleteInstallment abc 2']);
    });

    testWidgets('excluir avisa', (tester) async {
      await pumpHome(tester, repoWithTv());
      await swipeTv(tester);
      await tester.tap(find.text('Só esta'));
      await tester.pumpAndSettle();
      expect(find.text('Lançamento excluído'), findsOneWidget);
    });

    testWidgets('excluir pela edição', (tester) async {
      final repo = repoWithTv();
      await pumpHome(tester, repo);
      await tester.tap(find.text('TV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Só esta'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['deleteInstallment abc 2']);
      expect(find.text('Lançamento excluído'), findsOneWidget);
    });

    testWidgets('todas as parcelas', (tester) async {
      final repo = repoWithTv();
      await pumpHome(tester, repo);
      await swipeTv(tester);

      await tester.tap(find.text('Todas'));
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
      expect(find.text('TV'), findsOneWidget);
    });

    testWidgets('falha na API mantém o item e avisa', (tester) async {
      final repo = repoWithTv()..saveError = Exception('sem rede');
      await pumpHome(tester, repo);
      await swipeTv(tester);

      await tester.tap(find.text('Só esta'));
      await tester.pumpAndSettle();

      expect(find.text('TV'), findsOneWidget);
      expect(find.text('Não foi possível excluir'), findsOneWidget);
    });
  });

  group('editar parcelado', () {
    FakeBalanceRepository repoWithTv() => FakeBalanceRepository(
      data: {
        'NOV/26': {
          'gains': [
            balanceJson(
              'TV',
              1000,
              'gains',
              id: 'abc',
              installment: 2,
              totalInstallments: 3,
              realized: false,
              totalValue: 3000,
            ),
          ],
          'expenses': [],
        },
      },
    );

    Finder field(String name) => find.byWidgetPredicate(
      (w) => w is FormBuilderTextField && w.name == name,
    );

    Future<void> openTv(WidgetTester tester) async {
      await tester.tap(find.text('TV'));
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('mostra o valor total', (tester) async {
      await pumpHome(tester, repoWithTv());
      await openTv(tester);

      expect(find.text('Valor total'), findsOneWidget);
      expect(find.textContaining('3.000,00'), findsOneWidget);
    });

    testWidgets('marcar realizado altera só a parcela', (tester) async {
      final repo = repoWithTv();
      await pumpHome(tester, repo);
      await openTv(tester);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await save(tester);

      expect(repo.calls, ['realized abc 2 true']);
    });

    testWidgets('editar o nome altera o lançamento', (tester) async {
      final repo = repoWithTv();
      await pumpHome(tester, repo);
      await openTv(tester);

      await tester.enterText(field('name'), 'Televisão');
      await save(tester);

      expect(repo.calls, ['update abc {name: Televisão}']);
    });
  });

  testWidgets('o cartão da lista fica na mesma altura em todos os meses', (
    tester,
  ) async {
    // Nos testes a fonte é a Ahem, mais larga que a WorkSans: na tela padrão
    // (800 dp) os avisos não quebram de linha e só a altura reservada conta.
    final repo = FakeBalanceRepository(
      data: {
        // NOV/26 tem "Falta receber" e "Falta pagar".
        'NOV/26': {
          'gains': [balanceJson('Freela', 1200, 'gains', realized: false)],
          'expenses': [
            balanceJson('Internet', 120, 'expenses', realized: false),
          ],
        },
        // DEZ/26 não tem nenhum aviso.
        'DEZ/26': {
          'gains': [
            balanceJson('Bônus', 700, 'gains', date: '2026-12-15T12:00:00.000'),
          ],
          'expenses': [],
        },
      },
    );
    await pumpHome(tester, repo);
    final topoNov = tester.getTopLeft(find.byType(BalanceTabView)).dy;

    await tester.tap(find.text('DEZ/26'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Falta'), findsNothing);
    expect(tester.getTopLeft(find.byType(BalanceTabView)).dy, topoNov);
  });

  group('páginas de mês sem piscar o loader', () {
    FakeBalanceRepository repoComMeses() => FakeBalanceRepository(
      data: {
        'NOV/26': {
          'gains': [balanceJson('Salário', 1500, 'gains')],
          'expenses': [],
        },
        'DEZ/26': {
          'gains': [
            balanceJson('Bônus', 700, 'gains', date: '2026-12-15T12:00:00.000'),
          ],
          'expenses': [],
        },
        'JAN/27': {
          'gains': [
            balanceJson(
              'Freela',
              300,
              'gains',
              date: '2027-01-15T12:00:00.000',
            ),
          ],
          'expenses': [],
        },
      },
    );

    // Avança quadro a quadro: o loader de um quadro só aparece assim.
    Future<void> semLoaderPor(WidgetTester tester, int quadros) async {
      for (var i = 0; i < quadros; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          find.byType(AppLoad),
          findsNothing,
          reason: 'AppLoad no quadro $i',
        );
      }
    }

    testWidgets('trocar de mês, pelo toque e pelo deslize', (tester) async {
      await pumpHome(tester, repoComMeses());

      await tester.tap(find.text('DEZ/26'));
      await semLoaderPor(tester, 45);

      await tester.flingFrom(
        tester.getCenter(find.byType(BalanceResume).last),
        const Offset(300, 0),
        1500,
      );
      await semLoaderPor(tester, 60);
    });

    testWidgets('a lista de meses crescendo', (tester) async {
      await pumpHome(tester, repoComMeses());
      // A nona aba (FEV/26) fica a 4 abas do começo e faz a lista passar de
      // 25 para 37 meses; ao fim da animação o controlador é recriado.
      for (final mes in [
        'OUT/26',
        'SET/26',
        'AGO/26',
        'JUL/26',
        'JUN/26',
        'MAI/26',
        'ABR/26',
        'MAR/26',
        'FEV/26',
      ]) {
        await tester.tap(find.text(mes).first);
        await semLoaderPor(tester, 45);
      }
      expect(find.text('JAN/26'), findsWidgets);
    });

    testWidgets('o primeiro carregamento ainda mostra o loader', (
      tester,
    ) async {
      await pumpHome(tester, repoComMeses(), quadros: 0);
      expect(find.byType(AppLoad), findsOneWidget);

      await tester.pump();
      await tester.pump();
      expect(find.byType(AppLoad), findsNothing);
      expect(find.text('Salário'), findsOneWidget);
    });

    testWidgets('recarga que falha depois de carregar mostra o erro', (
      tester,
    ) async {
      final repo = repoComMeses();
      await pumpHome(tester, repo);

      repo.error = Exception('sem rede');
      await openFormAndSave(tester);

      expect(
        find.text('Não foi possível carregar os lançamentos'),
        findsOneWidget,
      );
    });
  });

  group('cor do fundo e do botão +', () {
    Color? fundo(WidgetTester tester) =>
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
    Color? corDoBotao(WidgetTester tester) => tester
        .widget<FloatingActionButton>(find.byType(FloatingActionButton))
        .backgroundColor;
    bool perto(Color? a, Color b) =>
        a != null &&
        (a.r - b.r).abs() < 0.01 &&
        (a.g - b.g).abs() < 0.01 &&
        (a.b - b.b).abs() < 0.01;

    testWidgets('segue o dedo ao arrastar de ganhos para gastos', (
      tester,
    ) async {
      await pumpHome(tester, FakeBalanceRepository(data: {}));
      expect(perto(fundo(tester), AppColors.primary), isTrue);
      // Espaço vazio da lista: o gesto vai para as abas, não para um item.
      final ponto =
          tester.getBottomLeft(find.byType(BalanceTabView)) +
          const Offset(60, -60);

      final gesto = await tester.startGesture(ponto);
      // O primeiro movimento só vence a folga do toque e assume o gesto.
      await gesto.moveBy(const Offset(-30, 0));
      await gesto.moveBy(const Offset(-200, 0));
      await tester.pump();
      // Com o dedo ainda na tela, a cor já saiu do verde e não chegou ao coral.
      final primeiro = fundo(tester)!;
      expect(perto(primeiro, AppColors.primary), isFalse);
      expect(perto(primeiro, AppColors.secondary), isFalse);
      expect(corDoBotao(tester), primeiro);

      await gesto.moveBy(const Offset(-200, 0));
      await tester.pump();
      final segundo = fundo(tester)!;
      expect(segundo, isNot(primeiro));
      // Mais perto do coral: o canal vermelho cresce de ganhos para gastos.
      expect(segundo.r, greaterThan(primeiro.r));

      await gesto.up();
      await tester.pumpAndSettle();
      expect(perto(fundo(tester), AppColors.secondary), isTrue);
      expect(perto(corDoBotao(tester), AppColors.secondary), isTrue);
    });

    testWidgets('toque na aba GASTOS anda junto com a página', (tester) async {
      await pumpHome(tester, FakeBalanceRepository(data: {}));

      await tester.tap(find.widgetWithText(Tab, 'GASTOS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final meio = fundo(tester);
      expect(perto(meio, AppColors.primary), isFalse);
      expect(perto(meio, AppColors.secondary), isFalse);
      expect(corDoBotao(tester), meio);

      await tester.pumpAndSettle();
      expect(perto(fundo(tester), AppColors.secondary), isTrue);
    });

    testWidgets('trocar de mês estando em gastos mantém o coral', (
      tester,
    ) async {
      await pumpHome(tester, FakeBalanceRepository(data: {}));
      await tester.tap(find.widgetWithText(Tab, 'GASTOS'));
      await tester.pumpAndSettle();
      expect(perto(fundo(tester), AppColors.secondary), isTrue);

      await tester.tap(find.text('DEZ/26'));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          perto(fundo(tester), AppColors.secondary),
          isTrue,
          reason: 'a cor mudou no quadro $i',
        );
      }
    });
  });

  group('a aba de tipo se mantém ao trocar de mês', () {
    FakeBalanceRepository repoComGastos() => FakeBalanceRepository(
      data: {
        'NOV/26': {
          'gains': [balanceJson('Salário', 1500, 'gains')],
          'expenses': [balanceJson('Mercado', 200, 'expenses')],
        },
        'DEZ/26': {
          'gains': [
            balanceJson('Bônus', 700, 'gains', date: '2026-12-15T12:00:00.000'),
          ],
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

    // 0 = GANHOS, 1 = GASTOS, na página de mês que está na tela.
    int abaAtiva(WidgetTester tester) => tester
        .widget<TabBar>(
          find.descendant(
            of: find.byType(BalanceTabView),
            matching: find.byType(TabBar),
          ),
        )
        .controller!
        .index;

    testWidgets('pelo toque na aba do mês', (tester) async {
      await pumpHome(tester, repoComGastos());
      await tester.tap(find.widgetWithText(Tab, 'GASTOS'));
      await tester.pumpAndSettle();
      expect(find.text('Mercado'), findsOneWidget);

      await tester.tap(find.text('DEZ/26'));
      await tester.pumpAndSettle();

      expect(abaAtiva(tester), 1);
      expect(find.text('Aluguel'), findsOneWidget);
      expect(find.text('Bônus'), findsNothing);
    });

    testWidgets('em ganhos, o mês novo também abre em ganhos', (tester) async {
      await pumpHome(tester, repoComGastos());
      await tester.tap(find.text('DEZ/26'));
      await tester.pumpAndSettle();

      expect(abaAtiva(tester), 0);
      expect(find.text('Bônus'), findsOneWidget);
    });

    testWidgets('pelo deslize sobre o resumo', (tester) async {
      await pumpHome(tester, repoComGastos());
      await tester.tap(find.widgetWithText(Tab, 'GASTOS'));
      await tester.pumpAndSettle();

      await tester.flingFrom(
        tester.getCenter(find.byType(BalanceResume).last),
        const Offset(-300, 0),
        1500,
      );
      await tester.pumpAndSettle();

      expect(abaAtiva(tester), 1);
      expect(find.text('Aluguel'), findsOneWidget);
    });

    testWidgets('quando a lista de meses cresce', (tester) async {
      await pumpHome(tester, repoComGastos());
      await tester.tap(find.widgetWithText(Tab, 'GASTOS'));
      await tester.pumpAndSettle();

      // A nona aba (FEV/26) faz a lista crescer e recria o controlador.
      for (final mes in [
        'OUT/26',
        'SET/26',
        'AGO/26',
        'JUL/26',
        'JUN/26',
        'MAI/26',
        'ABR/26',
        'MAR/26',
        'FEV/26',
      ]) {
        await tester.tap(find.text(mes).first);
        await tester.pumpAndSettle();
        expect(abaAtiva(tester), 1, reason: 'a aba mudou em $mes');
      }
    });
  });
}
