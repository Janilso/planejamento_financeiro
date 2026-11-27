import 'package:flutter_test/flutter_test.dart';

import '../../tool/perf_resumo.dart';

// Um fluxo no formato do FrameTimingSummarizer.
Map<String, dynamic> fluxo({
  double p99Build = 1,
  double p99Raster = 1,
  double piorBuild = 1,
  double piorRaster = 1,
}) => {
  '99th_percentile_frame_build_time_millis': p99Build,
  '99th_percentile_frame_rasterizer_time_millis': p99Raster,
  'worst_frame_build_time_millis': piorBuild,
  'worst_frame_rasterizer_time_millis': piorRaster,
};

LinhaResumo achar(List<LinhaResumo> linhas, String volume, String nome) =>
    linhas.singleWhere((l) => l.volume == volume && l.fluxo == nome);

void main() {
  test('mediana de três rodadas', () {
    final linhas = resumir([
      for (final p99 in [7.0, 9.0, 8.0])
        {
          'pesado_rolar_lista': fluxo(p99Build: p99),
          'leve_rolar_lista': fluxo(p99Build: 6),
        },
    ]);

    final l = achar(linhas, 'pesado', 'rolar_lista');
    expect(l.p99Build, 8);
    expect(l.veredito, Veredito.aprovado);
  });

  test('reprova quando passa do orçamento e fica 20% pior que o leve', () {
    final linhas = resumir([
      {
        'pesado_troca_tipo': fluxo(p99Build: 10),
        'leve_troca_tipo': fluxo(p99Build: 7),
      },
    ]);

    final l = achar(linhas, 'pesado', 'troca_tipo');
    expect(l.veredito, Veredito.reprovado);
    expect(l.semControle, isFalse);
  });

  test('limite quando passa do orçamento perto do leve', () {
    final linhas = resumir([
      {
        'pesado_troca_tipo': fluxo(p99Build: 8.6),
        'leve_troca_tipo': fluxo(p99Build: 7.9),
      },
    ]);

    expect(achar(linhas, 'pesado', 'troca_tipo').veredito, Veredito.limite);
  });

  test('já existe quando o leve também reprova', () {
    final linhas = resumir([
      {
        'pesado_troca_tipo': fluxo(p99Build: 10),
        'leve_troca_tipo': fluxo(p99Build: 9),
      },
    ]);

    expect(achar(linhas, 'pesado', 'troca_tipo').veredito, Veredito.jaExiste);
  });

  test('pontual usa o pior quadro', () {
    final linhas = resumir([
      {
        'pesado_salvar': fluxo(p99Build: 3, piorBuild: 17),
        'leve_salvar': fluxo(piorBuild: 9),
      },
    ]);

    expect(achar(linhas, 'pesado', 'salvar').veredito, Veredito.reprovado);
  });

  test('extremo usa só o critério absoluto', () {
    final reprova = resumir([
      {
        'extremo_abrir': fluxo(piorBuild: 17),
        'leve_abrir': fluxo(piorBuild: 18),
      },
    ]);
    final passa = resumir([
      {
        'extremo_abrir': fluxo(piorBuild: 12),
        'leve_abrir': fluxo(piorBuild: 18),
      },
    ]);

    expect(achar(reprova, 'extremo', 'abrir').veredito, Veredito.reprovado);
    expect(achar(passa, 'extremo', 'abrir').veredito, Veredito.aprovado);
  });

  test('leve é informativo', () {
    final linhas = resumir([
      {'leve_troca_tipo': fluxo(p99Build: 20)},
    ]);

    expect(achar(linhas, 'leve', 'troca_tipo').veredito, Veredito.informativo);
  });

  test('ignora os extras', () {
    final linhas = resumir([
      {
        'conversao': {
          'pesado': {'decode_ms': 3.0, 'fromMap_ms': 4.0},
        },
        'abrir_ms': {'pesado': 120},
        'meses_com_loader': {'pesado': 2},
        'pesado_rolar_lista': fluxo(),
      },
    ]);

    expect(linhas, hasLength(1));
    expect(linhas.single.fluxo, 'rolar_lista');
  });

  test('sem leve, a reprovação fica sem controle', () {
    final linhas = resumir([
      {'pesado_troca_tipo': fluxo(p99Build: 10)},
    ]);

    final l = achar(linhas, 'pesado', 'troca_tipo');
    expect(l.veredito, Veredito.reprovado);
    expect(l.semControle, isTrue);
  });

  test('fluxo desconhecido é informativo', () {
    final linhas = resumir([
      {'pesado_troca_mes_rede': fluxo(p99Build: 50)},
    ]);

    expect(
      achar(linhas, 'pesado', 'troca_mes_rede').veredito,
      Veredito.informativo,
    );
  });

  test('medianas dos extras', () {
    final medianas = medianasDosExtras([
      for (final f in [4.0, 6.0, 5.0])
        {
          'conversao': {
            'pesado': {'fromMap_ms': f},
          },
          'abrir_ms': {'pesado': f * 10},
        },
    ]);

    expect(medianas['conversao.pesado.fromMap_ms'], 5);
    expect(medianas['abrir_ms.pesado'], 50);
  });

  test('tabela em markdown', () {
    final tabela = tabelaMarkdown(
      resumir([
        {'pesado_rolar_lista': fluxo()},
      ]),
    );

    expect(
      tabela,
      contains(
        '| Volume | Fluxo | p99 build | p99 raster | Pior build | Pior raster | Resultado |',
      ),
    );
    expect(tabela, contains('✅'));
  });
}
