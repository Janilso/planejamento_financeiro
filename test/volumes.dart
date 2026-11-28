import 'dart:math';

import 'package:planejamento_financeiro/commons/months.dart';

import 'fakes.dart';

// Históricos sintéticos, no formato do GET /balances, para medir desempenho.
enum Volume { leve, pesado, extremo }

const _nomes = [
  'Mercado',
  'Aluguel',
  'Salário',
  'Internet',
  'Farmácia',
  'Combustível',
  'Academia',
  'Streaming',
  'Seguro',
  'Escola',
  'Restaurante',
  'Presente',
  'Manutenção',
  'Freelance',
  'Condomínio',
  'Energia',
  'Água',
  'Telefone',
  'Transporte',
  'Lazer',
  'Roupas',
  'Dentista',
  'Reembolso',
  'Bônus',
  'Venda',
  'Cartão',
  'Viagem',
  'Impostos',
  'Livros',
  'Pet',
];

({int meses, int porMes}) _regras(Volume volume) => switch (volume) {
  Volume.leve => (meses: 12, porMes: 15),
  Volume.pesado => (meses: 60, porMes: 20),
  Volume.extremo => (meses: 120, porMes: 25),
};

const _parcelas = 10;

// Do mês mais antigo até o de `hoje`, com lançamentos novos em cada um. O
// `pesado` tem 150 lançamentos no mês atual. Um em cada cinco é parcelado em
// 10x e as parcelas caem nos meses seguintes, inclusive nos futuros. Datas às
// 15:00Z (12:00 em São Paulo), até o dia 28: nenhum fuso muda o mês do item.
Map<String, dynamic> historicoSintetico(
  Volume volume, {
  required DateTime hoje,
}) {
  final regras = _regras(volume);
  final rnd = Random(42);
  final historico = <String, dynamic>{};

  void adicionar(DateTime mes, Map<String, dynamic> item) {
    final grupo = historico.putIfAbsent(
      monthKey(mes),
      () => {'gains': [], 'expenses': []},
    ) as Map<String, dynamic>;
    (grupo[item['type'] == 'gains' ? 'gains' : 'expenses'] as List).add(item);
  }

  for (var m = regras.meses - 1; m >= 0; m--) {
    final mes = DateTime(hoje.year, hoje.month - m, 1);
    final quantos = (m == 0 && volume == Volume.pesado) ? 150 : regras.porMes;
    for (var i = 0; i < quantos; i++) {
      final tipo = i % 4 == 0 ? 'gains' : 'expenses';
      final nome = '${_nomes[(i + m) % _nomes.length]} $m-$i';
      final id = 'v$m-$i';
      final dia = 1 + i % 28;
      final centavos = 500 + rnd.nextInt(299501);
      final parcelado = i % 5 == 0;
      final total = parcelado ? _parcelas : 1;
      final base = centavos ~/ total;
      for (var p = 1; p <= total; p++) {
        final mesDoItem = DateTime(mes.year, mes.month + p - 1, 1);
        final valor = parcelado
            ? (p == total ? centavos - base * (total - 1) : base)
            : centavos;
        final ordem = mesDoItem.year * 12 + mesDoItem.month;
        final atual = hoje.year * 12 + hoje.month;
        final realizado = ordem < atual || (ordem == atual && i.isEven);
        adicionar(
          mesDoItem,
          balanceJson(
            nome,
            valor / 100,
            tipo,
            id: id,
            date: DateTime.utc(
              mesDoItem.year,
              mesDoItem.month,
              dia,
              15,
            ).toIso8601String(),
            installment: p,
            totalInstallments: total,
            realized: realizado,
            totalValue: centavos / 100,
          ),
        );
      }
    }
  }
  return historico;
}
