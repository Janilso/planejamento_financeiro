import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:planejamento_financeiro/commons/months.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('monthsAfter a partir de 31/01 não pula nem repete meses', () {
    expect(monthsAfter(DateTime(2026, 1, 31), 3), [
      DateTime(2026, 2, 1),
      DateTime(2026, 3, 1),
      DateTime(2026, 4, 1),
    ]);
  });

  test('monthsBefore a partir de 31/03 volta mês a mês', () {
    expect(monthsBefore(DateTime(2026, 3, 31), 2), [
      DateTime(2026, 1, 1),
      DateTime(2026, 2, 1),
    ]);
  });

  test('monthsAround gera 25 meses distintos em volta do atual', () {
    final months = monthsAround(DateTime(2026, 11, 25));

    expect(months, hasLength(25));
    expect(months.toSet(), hasLength(25));
    expect(months.first, DateTime(2025, 11, 1));
    expect(months[12], DateTime(2026, 11, 1));
    expect(months.last, DateTime(2027, 11, 1));
  });

  test('dateForNewBalance não passa do último dia do mês', () {
    expect(
      dateForNewBalance(DateTime(2026, 2, 1), DateTime(2026, 1, 31)),
      DateTime(2026, 2, 28),
    );
  });

  test('dateForNewBalance no mês atual usa a data de hoje', () {
    final today = DateTime(2026, 11, 25, 14, 30);

    expect(dateForNewBalance(DateTime(2026, 11, 1), today), today);
  });

  test('monthKey usa MMM/yy em maiúsculas e sem ponto', () {
    expect(monthKey(DateTime(2026, 5, 1)), 'MAI/26');
    expect(monthKey(DateTime(2026, 2, 1)), 'FEV/26');
  });
}
