import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> setUpPtBr() async {
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
}

// Razão de contraste do WCAG entre duas cores opacas.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final claro = la > lb ? la : lb;
  final escuro = la > lb ? lb : la;
  return (claro + 0.05) / (escuro + 0.05);
}

// A posição de rolagem do PageView de um TabBarView (o Scrollable mais externo).
ScrollPosition tabViewPosition(WidgetTester tester, Finder tabBarView) {
  final scrollable = find
      .descendant(of: tabBarView, matching: find.byType(Scrollable))
      .first;
  return tester.state<ScrollableState>(scrollable).position;
}

// Avança 8 ms por quadro e devolve o maior `pixels` visto enquanto a página
// assenta: se passar do destino, a mola quicou.
Future<double> maxPixelsWhileSettling(
  WidgetTester tester,
  ScrollPosition position, {
  int frames = 200,
}) async {
  var maximo = position.pixels;
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 8));
    if (position.pixels > maximo) maximo = position.pixels;
  }
  return maximo;
}
