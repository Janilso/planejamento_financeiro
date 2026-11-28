import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/months.dart';
import 'package:planejamento_financeiro/screens/home.dart';
import 'package:planejamento_financeiro/screens/login.dart';
import 'package:planejamento_financeiro/screens/splash.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/balance_tab_view.dart';
import 'package:planejamento_financeiro/widgets/load/load.dart';

import '../fakes.dart';
import '../helpers.dart';

void main() {
  setUpAll(setUpPtBr);

  FakeBalanceRepository repoComDados() => FakeBalanceRepository(
    data: {
      monthKey(DateTime.now()): {
        'gains': [balanceJson('Salário', 5000, 'gains')],
        'expenses': [balanceJson('Aluguel', 1300, 'expenses')],
      },
    },
  );

  Future<void> montar(
    WidgetTester tester,
    FakeBalanceRepository repo, {
    bool logado = true,
    bool semAnimacao = false,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.defaultTheme,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          ...GlobalMaterialLocalizations.delegates,
          FormBuilderLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: semAnimacao),
          child: child!,
        ),
        home: SplashScreen(temSessao: () async => logado, repository: repo),
      ),
    );
  }

  // Avança o tempo em passos de 50 ms (um salto único não monta a rota nova).
  Future<void> passar(WidgetTester tester, int ms) async {
    for (var t = 0; t < ms; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder folha1() => find.descendant(
    of: find.byType(SplashScreen),
    matching: find.byWidgetPredicate(
      (w) =>
          w is SvgPicture &&
          (w.bytesLoader as SvgAssetLoader).assetName ==
              'assets/images/logo/folha-1.svg',
    ),
  );

  Finder loaderDaHome() => find.descendant(
    of: find.byType(HomeScreen),
    matching: find.byType(AppLoad),
  );

  testWidgets('logado, busca durante a splash e a home abre com os dados', (
    tester,
  ) async {
    final repo = repoComDados();
    await montar(tester, repo);

    await passar(tester, 1000);
    expect(repo.getCalls, 1, reason: 'a busca começa durante a splash');

    await passar(tester, 1400);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(loaderDaHome(), findsNothing);
    await passar(tester, 700);
    expect(find.text('Salário'), findsOneWidget);
    expect(loaderDaHome(), findsNothing);
    expect(repo.getCalls, 1, reason: 'a home não busca de novo');
  });

  testWidgets('as folhas saem voando para a direita antes da home', (
    tester,
  ) async {
    await montar(tester, repoComDados());
    await passar(tester, 1900);
    final antes = tester.getRect(folha1()).left;

    await passar(tester, 200);
    await passar(tester, 100);

    expect(find.byType(HomeScreen), findsNothing);
    expect(tester.getRect(folha1()).left, greaterThan(antes + 20));
    await passar(tester, 1000);
  });

  testWidgets('a home entra com as abas descendo e o cartão subindo', (
    tester,
  ) async {
    await montar(tester, repoComDados());
    await passar(tester, 2000);
    await passar(tester, 300);
    await passar(tester, 250);
    final abasCedo = tester.getTopLeft(find.byType(TabBar).first).dy;
    final cartaoCedo = tester.getTopLeft(find.byType(BalanceTabView)).dy;

    await passar(tester, 800);
    final abasFim = tester.getTopLeft(find.byType(TabBar).first).dy;
    final cartaoFim = tester.getTopLeft(find.byType(BalanceTabView)).dy;

    expect(abasCedo, lessThan(abasFim));
    expect(cartaoCedo, greaterThan(cartaoFim));
  });

  testWidgets('sem sessão, vai para o login sem buscar', (tester) async {
    final repo = repoComDados();
    await montar(tester, repo, logado: false);

    await passar(tester, 2000);
    await passar(tester, 400);

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(repo.getCalls, 0);
  });

  testWidgets('se a busca falhar, a home abre e faz a própria busca', (
    tester,
  ) async {
    final repo = FakeBalanceRepository(error: Exception('sem rede'));
    await montar(tester, repo);

    await passar(tester, 2000);
    await passar(tester, 300);
    await passar(tester, 700);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.text('Não foi possível carregar os lançamentos'),
      findsOneWidget,
    );
    expect(repo.getCalls, 2);
  });

  testWidgets('com animações desligadas, sem saída das folhas nem entrada', (
    tester,
  ) async {
    final repo = repoComDados();
    await montar(tester, repo, semAnimacao: true);
    await passar(tester, 1900);
    final antes = tester.getRect(folha1()).left;

    await passar(tester, 150);
    expect(tester.getRect(folha1()).left, closeTo(antes, 0.5));

    await passar(tester, 100);
    final abasCedo = tester.getTopLeft(find.byType(TabBar).first).dy;
    await passar(tester, 700);
    expect(tester.getTopLeft(find.byType(TabBar).first).dy, abasCedo);
    expect(find.text('Salário'), findsOneWidget);
    expect(repo.getCalls, 1);
  });
}
