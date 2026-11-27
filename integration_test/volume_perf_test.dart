// Desempenho da home com histórico grande, em modo profile no celular.
//
//   flutter drive --profile --no-dds -d <celular> \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/volume_perf_test.dart \
//     [--dart-define=VOLUMES=leve,pesado,extremo]
//
// A home usa o BalanceRepository e o HttpClient de verdade, sobre um adaptador
// do Dio que serve o histórico sintético (sem login e sem rede). O resultado
// de cada rodada fica em build/perf/volume_<carimbo>.json; o resumo com os
// critérios sai de `dart run tool/perf_resumo.dart`.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/models/month_balance.dart';
import 'package:planejamento_financeiro/network/http_client.dart';
import 'package:planejamento_financeiro/repository/balance.dart';
import 'package:planejamento_financeiro/screens/home.dart';
import 'package:planejamento_financeiro/theme/theme.dart';
import 'package:planejamento_financeiro/widgets/balance_resume.dart';
import 'package:planejamento_financeiro/widgets/formBalance/form_balance.dart';

import '../test/helpers.dart';
import '../test/volumes.dart';

const _volumesPedidos = String.fromEnvironment(
  'VOLUMES',
  defaultValue: 'leve,pesado,extremo',
);

final _hoje = DateTime(2026, 11, 25);

// Serve o histórico como o Express sem gzip: com `content-length`, o Dio
// decodifica o JSON num isolate quando passa de 50 KB.
class _AdapterDeVolume implements HttpClientAdapter {
  _AdapterDeVolume(this.corpo);

  final Uint8List corpo;
  Duration atrasoGet = Duration.zero;
  Completer<void>? segurarGet;
  // GET /balances já respondidos.
  int gets = 0;

  static const _json = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.method == 'GET' && options.path == '/balances') {
      await segurarGet?.future;
      if (atrasoGet > Duration.zero) await Future<void>.delayed(atrasoGet);
      gets++;
      return ResponseBody.fromBytes(
        corpo,
        200,
        headers: {
          ..._json,
          Headers.contentLengthHeader: ['${corpo.length}'],
        },
      );
    }
    return ResponseBody.fromString('{}', 201, headers: _json);
  }

  @override
  void close({bool force = false}) {}
}

final _corpos = <Volume, Uint8List>{};

Uint8List _corpo(Volume volume) => _corpos.putIfAbsent(
  volume,
  () => Uint8List.fromList(
    utf8.encode(jsonEncode(historicoSintetico(volume, hoje: _hoje))),
  ),
);

double _mediana(List<double> v) {
  final s = [...v]..sort();
  return s.length.isOdd
      ? s[s.length ~/ 2]
      : (s[s.length ~/ 2 - 1] + s[s.length ~/ 2]) / 2;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  setUpAll(setUpPtBr);

  final volumes = [
    for (final v in Volume.values)
      if (_volumesPedidos.split(',').contains(v.name)) v,
  ];

  void extra(String chave, Volume volume, Object valor) {
    final dados = (binding.reportData ??= <String, dynamic>{});
    final mapa = (dados[chave] ??= <String, dynamic>{}) as Map<String, dynamic>;
    mapa[volume.name] = valor;
  }

  Future<({Size tela, _AdapterDeVolume adaptador})> abrirHome(
    WidgetTester tester,
    Volume volume, {
    bool segurar = false,
    Duration atraso = Duration.zero,
  }) async {
    final adaptador = _AdapterDeVolume(_corpo(volume))..atrasoGet = atraso;
    if (segurar) adaptador.segurarGet = Completer<void>();
    final dio = Dio(BaseOptions(baseUrl: 'http://perf.local'))
      ..httpClientAdapter = adaptador;
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
          repository: BalanceRepository(HttpClient(dio)),
          clock: () => _hoje,
        ),
      ),
    );
    final tela = tester.view.physicalSize / tester.view.devicePixelRatio;
    return (tela: tela, adaptador: adaptador);
  }

  // Quadros de 16 ms até a condição valer (no máximo 10 s).
  Future<void> ate(WidgetTester tester, bool Function() pronto) async {
    for (var i = 0; i < 625 && !pronto(); i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(pronto(), isTrue, reason: 'a condição não valeu em 10 s');
  }

  Future<void> aguardarResumo(WidgetTester tester) =>
      ate(tester, () => find.byType(BalanceResume).evaluate().isNotEmpty);

  // Depois de cada arremesso ou toque. Sem pumpAndSettle: o AppLoad nunca assenta.
  Future<void> esperar(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 700));

  Future<void> arremessarMeses(
    WidgetTester tester,
    Size tela,
    int vezes,
  ) async {
    final ponto = Offset(tela.width / 2, tela.height * 0.21);
    for (var i = 0; i < vezes; i++) {
      await tester.flingFrom(ponto, const Offset(300, 0), 1500);
      await esperar(tester);
    }
  }

  Future<void> tocarTipo(WidgetTester tester, String rotulo) async {
    await tester.tap(find.widgetWithText(Tab, rotulo));
    await esperar(tester);
  }

  testWidgets('aquecimento', (tester) async {
    final h = await abrirHome(tester, Volume.leve);
    await aguardarResumo(tester);
    await arremessarMeses(tester, h.tela, 3);
    await tocarTipo(tester, 'GASTOS');
    await tocarTipo(tester, 'GANHOS');
  });

  for (final v in volumes) {
    testWidgets('${v.name}: abrir', (tester) async {
      final h = await abrirHome(tester, v, segurar: true);
      await tester.pump(const Duration(milliseconds: 500));
      final relogio = Stopwatch();
      await binding.watchPerformance(() async {
        relogio.start();
        h.adaptador.segurarGet!.complete();
        await aguardarResumo(tester);
        relogio.stop();
        await tester.pump(const Duration(milliseconds: 500));
      }, reportKey: '${v.name}_abrir');
      extra('abrir_ms', v, relogio.elapsedMilliseconds);
    });

    testWidgets('${v.name}: troca de mês', (tester) async {
      final h = await abrirHome(tester, v);
      await aguardarResumo(tester);
      await binding.watchPerformance(
        () => arremessarMeses(tester, h.tela, 21),
        reportKey: '${v.name}_troca_mes_perto',
      );
      await binding.watchPerformance(
        () => arremessarMeses(tester, h.tela, 39),
        reportKey: '${v.name}_troca_mes_longe',
      );
      expect(find.text('NOV/21'), findsWidgets);
    });

    testWidgets('${v.name}: troca GANHOS/GASTOS', (tester) async {
      await abrirHome(tester, v);
      await aguardarResumo(tester);
      await binding.watchPerformance(() async {
        for (var i = 0; i < 3; i++) {
          await tocarTipo(tester, 'GASTOS');
          await tocarTipo(tester, 'GANHOS');
        }
      }, reportKey: '${v.name}_troca_tipo');
    });

    testWidgets('${v.name}: rolar a lista', (tester) async {
      final h = await abrirHome(tester, v);
      await aguardarResumo(tester);
      await tocarTipo(tester, 'GASTOS');
      final ponto = Offset(h.tela.width / 2, h.tela.height * 0.7);
      await binding.watchPerformance(() async {
        for (final dy in [-500.0, -500.0, -500.0, 500.0, 500.0, 500.0]) {
          await tester.flingFrom(ponto, Offset(0, dy), 2000);
          await esperar(tester);
        }
      }, reportKey: '${v.name}_rolar_lista');
    });

    testWidgets('${v.name}: salvar', (tester) async {
      final h = await abrirHome(
        tester,
        v,
        atraso: const Duration(milliseconds: 100),
      );
      await aguardarResumo(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await esperar(tester);
      Finder campo(String nome) => find.byWidgetPredicate(
        (w) => w is FormBuilderTextField && w.name == nome,
      );
      await tester.enterText(campo('name'), 'Perf ${v.name}');
      await tester.enterText(campo('value'), '5000');
      await tester.pump(const Duration(milliseconds: 300));
      await binding.watchPerformance(() async {
        await tester.tap(find.text('Salvar'));
        await ate(
          tester,
          () =>
              h.adaptador.gets == 2 &&
              find.byType(FormBalance).evaluate().isEmpty,
        );
        await esperar(tester);
      }, reportKey: '${v.name}_salvar');
    });

    // Custo da conversão na thread principal: não passa pelo watchPerformance.
    test('${v.name}: conversão do JSON', () {
      final bytes = _corpo(v);
      final decode = <double>[], fromMap = <double>[];
      for (var i = 0; i < 5; i++) {
        final a = Stopwatch()..start();
        final json = jsonDecode(utf8.decode(bytes)) as Map;
        a.stop();
        final b = Stopwatch()..start();
        MonthBalanceModel.fromMap(Map<String, dynamic>.from(json));
        b.stop();
        decode.add(a.elapsedMicroseconds / 1000);
        fromMap.add(b.elapsedMicroseconds / 1000);
      }
      extra('conversao', v, {
        'decode_ms': _mediana(decode),
        'fromMap_ms': _mediana(fromMap),
      });
    });
  }
}
