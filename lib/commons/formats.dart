import 'package:intl/intl.dart';

class AppFormats {
  static String dateToFormat(DateTime date, [String format = 'MMMM yyyy']) {
    return DateFormat(format).format(date);
  }

  static String valueToMoney(double? value) {
    return value != null ? NumberFormat.simpleCurrency().format(value) : "";
  }

  static String onlyNumberFromString([String value = '']) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  // "R$ 1.234,56" -> 1234.56: mantém só dígitos e a vírgula decimal, que vira ponto.
  static double stringMoneyToDouble([String value = '']) {
    return double.parse(
      value.replaceAll(RegExp(r'[^0-9,]'), '').replaceAll(',', '.'),
    );
  }
}
