import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> setUpPtBr() async {
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
}
