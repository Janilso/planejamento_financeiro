import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/widgets/logo_animado.dart';

void main() {
  Future<void> montar(
    WidgetTester tester, {
    bool semAnimacao = false,
    bool entrada = true,
    bool balancar = false,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: semAnimacao),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: LogoAnimado(entrada: entrada, balancar: balancar),
        ),
      ),
    ),
  );

  // A caixa de 168x117 do logo (o LogoAnimado em si ocupa a largura toda).
  Finder caixaFinder() => find
      .descendant(of: find.byType(LogoAnimado), matching: find.byType(SizedBox))
      .first;
  Rect caixa(WidgetTester tester) => tester.getRect(caixaFinder());

  Rect parte(WidgetTester tester, String nome) => tester.getRect(
    find.byWidgetPredicate(
      (w) =>
          w is SvgPicture &&
          (w.bytesLoader as SvgAssetLoader).assetName ==
              'assets/images/logo/$nome.svg',
    ),
  );

  // O SVG (169x118) mantém a proporção dentro de 168x117: até 0,5 dp de folga.
  void noLugar(Rect rect, Rect logo, String nome) {
    expect(rect.left, closeTo(logo.left, 0.5), reason: nome);
    expect(rect.top, closeTo(logo.top, 0.5), reason: nome);
    expect(rect.right, closeTo(logo.right, 0.5), reason: nome);
    expect(rect.bottom, closeTo(logo.bottom, 0.5), reason: nome);
  }

  // Fração visível de uma linha do texto: a parte dentro da faixa recortada.
  double textoVisivel(WidgetTester tester, String nome) {
    final rect = parte(tester, nome);
    final logo = caixa(tester);
    return rect.top - logo.top;
  }

  testWidgets('desenha o logo com as cinco partes, do tamanho de antes', (
    tester,
  ) async {
    await montar(tester);
    expect(
      tester.getSize(
        find
            .descendant(
              of: find.byType(LogoAnimado),
              matching: find.byType(SizedBox),
            )
            .first,
      ),
      const Size(168, 117),
    );
    expect(find.byType(SvgPicture), findsNWidgets(5));
  });

  testWidgets('no começo as folhas estão fora do lugar e o texto escondido', (
    tester,
  ) async {
    await montar(tester);
    final logo = caixa(tester);

    for (final folha in ['folha-1', 'folha-2', 'folha-3']) {
      expect(parte(tester, folha).right, lessThanOrEqualTo(logo.left));
    }
    // O texto começa deslocado para baixo da própria faixa.
    expect(textoVisivel(tester, 'texto-1'), greaterThan(0));
    expect(textoVisivel(tester, 'texto-2'), greaterThan(0));
  });

  testWidgets('depois de 1,5 s todas as partes estão no lugar', (tester) async {
    await montar(tester);
    await tester.pump(const Duration(milliseconds: 1500));
    final logo = caixa(tester);

    for (final nome in [
      'folha-1',
      'folha-2',
      'folha-3',
      'texto-1',
      'texto-2',
    ]) {
      noLugar(parte(tester, nome), logo, nome);
    }
  });

  testWidgets('com animações desligadas no sistema, já começa parado', (
    tester,
  ) async {
    await montar(tester, semAnimacao: true);
    await tester.pump();
    final logo = caixa(tester);

    for (final nome in [
      'folha-1',
      'folha-2',
      'folha-3',
      'texto-1',
      'texto-2',
    ]) {
      noLugar(parte(tester, nome), logo, nome);
    }
  });

  testWidgets('as faixas do texto cobrem as letras inteiras', (tester) async {
    await montar(tester);
    await tester.pump(const Duration(milliseconds: 1500));
    final faixas = tester
        .renderObjectList<RenderClipRect>(find.byType(ClipRect))
        .map((r) => r.clipper!.getClip(r.size))
        .toList();
    // Altura das letras no SVG (viewBox de 118): PLANEJAMENTO de 85,25 a 99,5 e
    // FINANCEIRO de 106,25 a 117,75; o logo tem 117 dp de altura.
    double dp(double y) => y * 117 / 118;
    expect(faixas, hasLength(2));
    expect(faixas[0].top, lessThanOrEqualTo(dp(85.25)));
    expect(faixas[0].bottom, greaterThanOrEqualTo(dp(99.5)));
    expect(faixas[1].top, lessThanOrEqualTo(dp(106.25)));
    expect(faixas[1].bottom, greaterThanOrEqualTo(dp(117.75)));
  });

  testWidgets('fica no centro dentro da ListView da splash', (tester) async {
    // Na splash o logo fica numa ListView, que força a largura da tela inteira.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Center(
            child: SizedBox(
              width: 360,
              child: ListView(
                shrinkWrap: true,
                children: const [LogoAnimado()],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));

    final centroDaTela = tester.getCenter(find.byType(ListView)).dx;
    final folha = tester.getRect(
      find.byWidgetPredicate(
        (w) =>
            w is SvgPicture &&
            (w.bytesLoader as SvgAssetLoader).assetName ==
                'assets/images/logo/folha-1.svg',
      ),
    );
    expect(folha.center.dx, closeTo(centroDaTela, 0.5));
  });

  group('balanço das folhas (login)', () {
    const folhas = ['folha-1', 'folha-2', 'folha-3'];

    // Deslocamento horizontal de cada folha em relação ao lugar final.
    List<double> desvios(WidgetTester tester) => [
      for (final f in folhas) parte(tester, f).left - caixa(tester).left,
    ];

    testWidgets('sem entrada, o logo já começa montado', (tester) async {
      await montar(tester, entrada: false);
      for (final nome in [...folhas, 'texto-1', 'texto-2']) {
        noLugar(parte(tester, nome), caixa(tester), nome);
      }
    });

    testWidgets('depois da entrada, as folhas balançam até 3 dp sem parar', (
      tester,
    ) async {
      await montar(tester, balancar: true);
      await tester.pump(const Duration(milliseconds: 1500));

      var maior = 0.0;
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        for (final d in desvios(tester)) {
          expect(d.abs(), lessThanOrEqualTo(3.01));
          if (d.abs() > maior) maior = d.abs();
        }
        // O texto não balança.
        noLugar(parte(tester, 'texto-1'), caixa(tester), 'texto-1');
      }
      expect(maior, greaterThan(1.5), reason: 'as folhas não se mexeram');
      // Continua mexendo depois de 6 s.
      final antes = desvios(tester);
      await tester.pump(const Duration(milliseconds: 500));
      expect(desvios(tester), isNot(antes));
    });

    testWidgets('as folhas não balançam juntas', (tester) async {
      await montar(tester, entrada: false, balancar: true);
      await tester.pump(const Duration(milliseconds: 300));
      final d = desvios(tester);
      expect(d.toSet(), hasLength(3));
    });

    testWidgets('com animações desligadas, não balança', (tester) async {
      await montar(tester, semAnimacao: true, balancar: true);
      await tester.pump(const Duration(seconds: 3));
      for (final d in desvios(tester)) {
        expect(d.abs(), lessThan(0.5));
      }
    });
  });
}
