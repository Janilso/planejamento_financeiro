import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/network/http_client.dart';
import 'package:planejamento_financeiro/repository/balance.dart';

import '../fakes.dart';

void main() {
  late FakeHttpAdapter adapter;
  late BalanceRepository repository;

  setUp(() {
    adapter = FakeHttpAdapter();
    repository = BalanceRepository(
      HttpClient(
        Dio(BaseOptions(baseUrl: 'http://api.test'))
          ..httpClientAdapter = adapter,
      ),
    );
  });

  test('getBalances lê o formato da API', () async {
    adapter.responses.add(
      const FakeResponse(200, {
        'NOV/26': {
          'gains': [
            {
              'id': 'abc',
              'name': 'Salário',
              'value': 1500,
              'realized': true,
              'installment': 1,
              'totalInstallments': 0,
              'type': 'gains',
              'date': '2026-11-15T12:00:00.000Z',
              'totalValue': 1500,
            },
          ],
          'expenses': [],
        },
      }),
    );

    final result = await repository.getBalances();

    expect(adapter.requests.single.path, '/balances');
    final gain = result.months['NOV/26']!.gains.single;
    expect(gain.id, 'abc');
    expect(gain.totalValue, 1500.0);
  });

  test('createBalance envia data ISO e parcela 1', () async {
    adapter.responses.add(const FakeResponse(201, {}));

    await repository.createBalance(
      BalanceModel(
        name: 'Café',
        value: 15,
        type: 'expenses',
        totalInstallments: 1,
        date: DateTime.utc(2026, 11, 15, 12),
      ),
    );

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, '/balances');
    expect(request.data, {
      'name': 'Café',
      'value': 15.0,
      'type': 'expenses',
      'installment': 1,
      'totalInstallments': 1,
      'date': '2026-11-15T12:00:00.000Z',
      'realized': false,
    });
  });

  test('deleteInstallment chama a rota da parcela', () async {
    adapter.responses.add(const FakeResponse(204, ''));

    await repository.deleteInstallment('abc', 2);

    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.path, '/balances/abc/installments/2');
  });

  test('409 vira ApiException com mensagem amigável', () async {
    adapter.responses.add(
      const FakeResponse(409, {'message': 'Chave duplicada'}),
    );

    await expectLater(
      repository.createBalance(
        BalanceModel(name: 'Café', value: 15, type: 'expenses'),
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 409)
            .having(
              (e) => e.message,
              'message',
              'Você já tem um lançamento com esse nome.',
            ),
      ),
    );
  });

  test('erro no getBalances mantém a mensagem da API', () async {
    adapter.responses.add(
      const FakeResponse(400, {'message': 'Algo deu errado'}),
    );

    await expectLater(
      repository.getBalances(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.status, 'status', 400)
            .having((e) => e.message, 'message', 'Algo deu errado'),
      ),
    );
  });

  test('parseBalances lê UTF-8 com acentos', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'NOV/26': {
            'gains': [
              {
                'id': 'a',
                'name': 'Salário à vista',
                'value': 10,
                'realized': true,
                'installment': 1,
                'totalInstallments': 1,
                'type': 'gains',
              },
            ],
            'expenses': [],
          },
        }),
      ),
    );

    final result = parseBalances(bytes);

    expect(result.months['NOV/26']!.gains.single.name, 'Salário à vista');
  });
}
