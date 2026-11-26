import 'package:flutter/painting.dart';
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
