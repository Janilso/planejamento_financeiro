// Linha de base de desempenho das animações da home, em modo profile no celular.
//
//   flutter drive --profile -d <celular> \
//     --driver=test_driver/integration_test.dart \
//     --target=integration_test/animacoes_perf_test.dart
//
// O resultado (média, p90, p99, pior frame e frames perdidos de build e raster
// por fluxo) fica em build/integration_response_data.json. Usa o dublê do
// repositório: não precisa de login nem de rede.
import 'package:flutter_test/flutter_test.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/screens/home.dart';
import 'package:planejamento_financeiro/theme/theme.dart';

import '../test/fakes.dart';
import '../test/helpers.dart';

// Um mês com ganhos e gastos de verdade, inclusive um parcelado.
Map<String, dynamic> _mes(String tag, String data, {int itens = 3}) => {
  'gains': [
    for (var i = 0; i < itens; i++)
      balanceJson(
        'Ganho $i',
        500.0 + i * 120,
        'gains',
        id: 'g$tag$i',
        date: data,
      ),
  ],
  'expenses': [
    for (var i = 0; i < itens; i++)
      balanceJson(
        'Gasto $i',
        80.0 + i * 45,
        'expenses',
        id: 'e$tag$i',
        date: data,
        realized: i.isEven,
      ),
    balanceJson(
      'TV',
      250,
      'expenses',
      id: 'tv$tag',
      date: data,
      installment: 2,
      totalInstallments: 4,
      totalValue: 1000,
      realized: false,
    ),
  ],
};

FakeBalanceRepository _repo() => FakeBalanceRepository(
  data: {
    'SET/26': _mes('set', '2026-09-15T12:00:00.000'),
    'OUT/26': _mes('out', '2026-10-15T12:00:00.000'),
    'NOV/26': _mes('nov', '2026-11-15T12:00:00.000'),
    'DEZ/26': _mes('dez', '2026-12-15T12:00:00.000'),
    'JAN/27': _mes('jan', '2027-01-15T12:00:00.000'),
    'FEV/27': _mes('fev', '2027-02-15T12:00:00.000'),
  },
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  setUpAll(setUpPtBr);

  Future<Size> abrirHome(WidgetTester tester) async {
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
          repository: _repo(),
          clock: () => DateTime(2026, 11, 25),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.view.physicalSize / tester.view.devicePixelRatio;
  }

  testWidgets('troca de mês: deslizar sobre o resumo', (tester) async {
    final tela = await abrirHome(tester);
    final ponto = Offset(tela.width / 2, tela.height * 0.21);
    await binding.watchPerformance(() async {
      for (final dx in [-300.0, -300.0, -300.0, 300.0, 300.0, 300.0]) {
        await tester.flingFrom(ponto, Offset(dx, 0), 1500);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'troca_mes');
  });

  testWidgets('troca GANHOS/GASTOS: deslizar na lista', (tester) async {
    final tela = await abrirHome(tester);
    // Espaço vazio da lista (sobre um item o Dismissible capturaria o gesto).
    final ponto = Offset(tela.width * 0.3, tela.height * 0.88);
    await binding.watchPerformance(() async {
      for (final dx in [-300.0, 300.0, -300.0, 300.0, -300.0, 300.0]) {
        await tester.flingFrom(ponto, Offset(dx, 0), 1500);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'troca_tipo');
  });

  testWidgets('modal de lançamento: abrir e fechar', (tester) async {
    final tela = await abrirHome(tester);
    await binding.watchPerformance(() async {
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        // Toque na área escurecida, acima do modal.
        await tester.tapAt(Offset(tela.width / 2, 40));
        await tester.pumpAndSettle();
      }
    }, reportKey: 'modal');
  });
}
