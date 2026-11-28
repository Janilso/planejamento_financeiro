import 'package:flutter_test/flutter_test.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/months.dart';
import 'package:planejamento_financeiro/screens/home.dart';
import 'package:planejamento_financeiro/screens/login.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/button.dart';
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
    Future<void> Function()? signIn,
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
        home: LoginScreen(
          vindoDaSplash: true,
          signIn: signIn ?? () async {},
          repository: repo,
        ),
      ),
    );
    // O logo do login balança sem parar: avança o tempo, não espera assentar.
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> entrar(WidgetTester tester) async {
    await tester.tap(find.text('ENTRAR / CADASTRAR'));
    await tester.pump();
    // A busca termina e a rota é empurrada; o voo começa no quadro seguinte.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  bool voando(WidgetTester tester) =>
      find.byKey(const ValueKey('voo-do-cartao')).evaluate().isNotEmpty;

  testWidgets('a home abre com os lançamentos já buscados, sem nova busca', (
    tester,
  ) async {
    final repo = repoComDados();
    await montar(tester, repo);

    await entrar(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    // (O AppLoad do botão do login segue na tela até a rota terminar.)
    final loaderDaHome = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(AppLoad),
    );
    expect(loaderDaHome, findsNothing);
    // Durante o voo o cartão é só um espaço reservado; depois, a lista aparece.
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Salário'), findsOneWidget);
    expect(loaderDaHome, findsNothing);
    expect(repo.getCalls, 1);
  });

  testWidgets('o botão voa e cresce até o cartão da lista', (tester) async {
    await montar(tester, repoComDados());
    final botao = tester.getRect(find.byType(AppButton));

    await entrar(tester);
    expect(voando(tester), isTrue);
    final cedo = tester.getRect(find.byKey(const ValueKey('voo-do-cartao')));
    await tester.pump(const Duration(milliseconds: 200));
    final meio = tester.getRect(find.byKey(const ValueKey('voo-do-cartao')));

    expect(cedo.height, greaterThanOrEqualTo(botao.height - 1));
    expect(meio.height, greaterThan(cedo.height));
    expect(meio.top, lessThan(cedo.top));

    await tester.pump(const Duration(milliseconds: 700));
    expect(voando(tester), isFalse);
  });

  testWidgets('quando a rota termina, o Hero da home é desligado', (
    tester,
  ) async {
    await montar(tester, repoComDados());
    await entrar(tester);
    HeroMode modo() => tester.widget<HeroMode>(
      find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(HeroMode),
      ),
    );
    expect(modo().enabled, isTrue);

    await tester.pump(const Duration(milliseconds: 800));
    expect(modo().enabled, isFalse);
  });

  testWidgets('abas e resumo descem enquanto o botão vira o cartão', (
    tester,
  ) async {
    await montar(tester, repoComDados());
    await entrar(tester);
    await tester.pump(const Duration(milliseconds: 250));
    final cedo = tester.getTopLeft(find.byType(TabBar).first).dy;

    await tester.pump(const Duration(milliseconds: 800));
    final fim = tester.getTopLeft(find.byType(TabBar).first).dy;

    expect(cedo, lessThan(fim));
  });

  testWidgets('se a busca falhar, a home abre e mostra o erro', (tester) async {
    final repo = FakeBalanceRepository(error: Exception('sem rede'));
    await montar(tester, repo);

    await entrar(tester);
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      find.text('Não foi possível carregar os lançamentos'),
      findsOneWidget,
    );
    expect(repo.getCalls, 2);
  });

  testWidgets('se o login falhar, nada é buscado e o botão volta', (
    tester,
  ) async {
    final repo = repoComDados();
    await montar(tester, repo, signIn: () async => throw Exception('x'));

    await entrar(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.getCalls, 0);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('ENTRAR / CADASTRAR'), findsOneWidget);
  });

  testWidgets('com animações desligadas, o login não busca antes nem voa', (
    tester,
  ) async {
    final repo = repoComDados();
    await montar(tester, repo, semAnimacao: true);
    expect(
      find.byWidgetPredicate((w) => w is Hero && w.tag == 'cartao'),
      findsNothing,
    );

    await entrar(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(voando(tester), isFalse);
    expect(repo.getCalls, 1); // a própria home busca, uma vez
  });
}
