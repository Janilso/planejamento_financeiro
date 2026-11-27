import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:planejamento_financeiro/commons/months.dart';

import 'helpers.dart';
import 'volumes.dart';

void main() {
  setUpAll(setUpPtBr);

  final hoje = DateTime(2026, 11, 25);

  Iterable<Map<String, dynamic>> itens(Map<String, dynamic> historico) sync* {
    for (final mes in historico.values) {
      for (final lista in [mes['gains'], mes['expenses']]) {
        for (final item in lista as List) {
          yield item as Map<String, dynamic>;
        }
      }
    }
  }

  test('conta de itens de cada volume', () {
    expect(itens(historicoSintetico(Volume.leve, hoje: hoje)), hasLength(504));
    expect(
      itens(historicoSintetico(Volume.pesado, hoje: hoje)),
      hasLength(3724),
    );
    expect(
      itens(historicoSintetico(Volume.extremo, hoje: hoje)),
      hasLength(8400),
    );
  });

  test('pesado vai de DEZ/21 a AGO/27 e tem o mês cheio', () {
    final h = historicoSintetico(Volume.pesado, hoje: hoje);

    expect(h.keys, containsAll(['DEZ/21', 'NOV/26', 'AGO/27']));
    expect(h.keys, isNot(contains('NOV/21')));
    expect(h.keys, isNot(contains('SET/27')));
    final nov = h['NOV/26'] as Map<String, dynamic>;
    expect(
      (nov['gains'] as List).length + (nov['expenses'] as List).length,
      greaterThanOrEqualTo(150),
    );
  });

  test('ids únicos por parcela e nomes até 30 caracteres', () {
    final todos = itens(historicoSintetico(Volume.pesado, hoje: hoje)).toList();

    expect(
      todos.map((i) => '${i['id']}-${i['installment']}').toSet(),
      hasLength(todos.length),
    );
    expect(todos.every((i) => (i['name'] as String).length <= 30), isTrue);
  });

  test('datas às 15:00Z, até o dia 28 e no mês da chave', () {
    final h = historicoSintetico(Volume.pesado, hoje: hoje);

    for (final entrada in h.entries) {
      final mes = entrada.value as Map<String, dynamic>;
      for (final lista in [mes['gains'], mes['expenses']]) {
        for (final item in lista as List) {
          final d = DateTime.parse(item['date'] as String);
          expect(d.isUtc, isTrue);
          expect(d.hour, 15);
          expect(d.day, lessThanOrEqualTo(28));
          expect(monthKey(DateTime(d.year, d.month)), entrada.key);
        }
      }
    }
  });

  test('é determinístico', () {
    expect(
      jsonEncode(historicoSintetico(Volume.leve, hoje: hoje)),
      jsonEncode(historicoSintetico(Volume.leve, hoje: hoje)),
    );
  });
}
