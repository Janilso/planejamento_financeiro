// Resume as medições de `integration_test/volume_perf_test.dart`: tira a
// mediana das rodadas e aplica os critérios do plano de desempenho.
//
//   dart run tool/perf_resumo.dart [build/perf/volume_*.json ...]
//
// Sem argumentos, usa as 3 medições mais recentes de build/perf.
import 'dart:convert';
import 'dart:io';

const orcamentoQuadroMs = 8.3; // um quadro a 120 Hz
const quadroPontualMs = 16.0; // no máximo um quadro perdido a 60 Hz
const margemVolume = 1.2; // o pesado precisa ser 20% pior que o leve

const _volumes = ['leve', 'pesado', 'extremo'];

enum Veredito { aprovado, reprovado, limite, jaExiste, informativo }

class LinhaResumo {
  const LinhaResumo({
    required this.volume,
    required this.fluxo,
    required this.p99Build,
    required this.p99Raster,
    required this.piorBuild,
    required this.piorRaster,
    required this.veredito,
    this.semControle = false,
  });

  final String volume, fluxo;
  final double p99Build, p99Raster, piorBuild, piorRaster;
  final Veredito veredito;
  // Reprovou, mas não há linha do leve para comparar.
  final bool semControle;
}

// Fluxos com p99 de build e raster no orçamento do quadro e/ou o pior quadro
// no limite pontual. Fluxo fora desta lista é só informativo.
const _criterios = <String, ({bool p99, bool pior})>{
  'abrir': (p99: false, pior: true),
  'troca_mes_perto': (p99: true, pior: true),
  'troca_mes_longe': (p99: true, pior: true),
  'troca_tipo': (p99: true, pior: false),
  'rolar_lista': (p99: true, pior: false),
  'salvar': (p99: false, pior: true),
};

double _mediana(List<double> valores) {
  final v = [...valores]..sort();
  final meio = v.length ~/ 2;
  return v.length.isOdd ? v[meio] : (v[meio - 1] + v[meio]) / 2;
}

double _mediaDe(List<Map<String, dynamic>> rodadas, String chave, String m) =>
    _mediana([
      for (final r in rodadas)
        if (r[chave] != null) (r[chave][m] as num).toDouble(),
    ]);

bool _passa(String fluxo, LinhaResumo l) {
  final c = _criterios[fluxo]!;
  return (!c.p99 ||
          (l.p99Build < orcamentoQuadroMs &&
              l.p99Raster < orcamentoQuadroMs)) &&
      (!c.pior ||
          (l.piorBuild < quadroPontualMs && l.piorRaster < quadroPontualMs));
}

// O número que decide e que se compara com o leve.
double _nota(String fluxo, LinhaResumo l) {
  final c = _criterios[fluxo]!;
  final a = c.p99 ? l.p99Build : l.piorBuild;
  final b = c.p99 ? l.p99Raster : l.piorRaster;
  return a > b ? a : b;
}

List<LinhaResumo> resumir(List<Map<String, dynamic>> rodadas) {
  final chaves = <String>{
    for (final r in rodadas)
      for (final k in r.keys)
        if (_volumes.any(k.startsWith) && k.contains('_')) k,
  }.toList();

  LinhaResumo medir(String chave) {
    final volume = chave.substring(0, chave.indexOf('_'));
    return LinhaResumo(
      volume: volume,
      fluxo: chave.substring(volume.length + 1),
      p99Build: _mediaDe(
        rodadas,
        chave,
        '99th_percentile_frame_build_time_millis',
      ),
      p99Raster: _mediaDe(
        rodadas,
        chave,
        '99th_percentile_frame_rasterizer_time_millis',
      ),
      piorBuild: _mediaDe(rodadas, chave, 'worst_frame_build_time_millis'),
      piorRaster: _mediaDe(
        rodadas,
        chave,
        'worst_frame_rasterizer_time_millis',
      ),
      veredito: Veredito.informativo,
    );
  }

  final medidas = [
    for (final k in chaves)
      if (_volumes.contains(k.substring(0, k.indexOf('_')))) medir(k),
  ];
  LinhaResumo? leveDe(String fluxo) =>
      medidas.where((l) => l.volume == 'leve' && l.fluxo == fluxo).firstOrNull;

  LinhaResumo com(LinhaResumo l, Veredito v, {bool semControle = false}) =>
      LinhaResumo(
        volume: l.volume,
        fluxo: l.fluxo,
        p99Build: l.p99Build,
        p99Raster: l.p99Raster,
        piorBuild: l.piorBuild,
        piorRaster: l.piorRaster,
        veredito: v,
        semControle: semControle,
      );

  return [
    for (final l in medidas)
      if (l.volume == 'leve' || !_criterios.containsKey(l.fluxo))
        com(l, Veredito.informativo)
      else if (_passa(l.fluxo, l))
        com(l, Veredito.aprovado)
      else if (l.volume == 'extremo')
        com(l, Veredito.reprovado)
      else
        _falhaDoPesado(l, leveDe(l.fluxo), com),
  ];
}

LinhaResumo _falhaDoPesado(
  LinhaResumo l,
  LinhaResumo? leve,
  LinhaResumo Function(LinhaResumo, Veredito, {bool semControle}) com,
) {
  if (leve == null) return com(l, Veredito.reprovado, semControle: true);
  if (!_passa(l.fluxo, leve)) return com(l, Veredito.jaExiste);
  final pior = _nota(l.fluxo, l) >= _nota(l.fluxo, leve) * margemVolume;
  return com(l, pior ? Veredito.reprovado : Veredito.limite);
}

String tabelaMarkdown(List<LinhaResumo> linhas) {
  String resultado(LinhaResumo l) => switch (l.veredito) {
    Veredito.aprovado => '✅',
    Veredito.reprovado => l.semControle ? '❌ sem controle' : '❌',
    Veredito.limite => '⚠️ limite',
    Veredito.jaExiste => 'já existe',
    Veredito.informativo => '—',
  };
  String n(double v) => v.toStringAsFixed(2);
  return [
    '| Volume | Fluxo | p99 build | p99 raster | Pior build | Pior raster | Resultado |',
    '|---|---|---|---|---|---|---|',
    for (final l in linhas)
      '| ${l.volume} | ${l.fluxo} | ${n(l.p99Build)} | ${n(l.p99Raster)} '
          '| ${n(l.piorBuild)} | ${n(l.piorRaster)} | ${resultado(l)} |',
  ].join('\n');
}

// Medianas dos números fora dos fluxos (conversao, abrir_ms, ...), como
// `conversao.pesado.fromMap_ms`.
Map<String, double> medianasDosExtras(List<Map<String, dynamic>> rodadas) {
  final valores = <String, List<double>>{};
  void coletar(String caminho, Object? v) {
    if (v is num) {
      valores.putIfAbsent(caminho, () => []).add(v.toDouble());
    } else if (v is Map) {
      v.forEach((k, x) => coletar('$caminho.$k', x));
    }
  }

  for (final r in rodadas) {
    r.forEach((k, v) {
      final ehFluxo = _volumes.any((vol) => k.startsWith('${vol}_'));
      if (!ehFluxo) coletar(k, v);
    });
  }
  return {
    for (final e in valores.entries)
      e.key.replaceFirst(RegExp(r'^\.'), ''): _mediana(e.value),
  };
}

void main(List<String> args) {
  var arquivos = args;
  if (arquivos.isEmpty) {
    final todos =
        Directory('build/perf')
            .listSync()
            .whereType<File>()
            .map((f) => f.path)
            .where((p) => RegExp(r'volume_[^/]*\.json$').hasMatch(p))
            .toList()
          ..sort();
    arquivos = todos.length > 3 ? todos.sublist(todos.length - 3) : todos;
  }
  final rodadas = [
    for (final a in arquivos)
      jsonDecode(File(a).readAsStringSync()) as Map<String, dynamic>,
  ];
  stdout.writeln('Rodadas: ${rodadas.length} (${arquivos.join(', ')})\n');
  stdout.writeln(tabelaMarkdown(resumir(rodadas)));
  stdout.writeln('');
  medianasDosExtras(rodadas)
      .forEach((k, v) => stdout.writeln('$k: ${v.toStringAsFixed(2)}'));
}
