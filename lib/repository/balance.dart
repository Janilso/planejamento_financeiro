import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dio/dio.dart' show ResponseType;
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/models/month_balance.dart';
import 'package:planejamento_financeiro/network/http_client.dart';

// Erro da API com uma mensagem que pode ser mostrada para a pessoa.
class ApiException implements Exception {
  const ApiException(this.status, this.message);

  final int status;
  final String message;

  @override
  String toString() => message;
}

// Funções de nível superior de propósito: uma closure criada dentro de um
// método do repositório pode levar o `this` junto (e com ele o Dio), que não
// atravessa o isolate.
MonthBalanceModel parseBalances(Uint8List bytes) => MonthBalanceModel.fromMap(
  Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
);

Future<MonthBalanceModel> parseBalancesInBackground(Uint8List bytes) =>
    Isolate.run(() => parseBalances(bytes));

class BalanceRepository {
  BalanceRepository(this._client);

  final HttpClient _client;

  // Pede o corpo cru e converte (UTF-8, JSON e models) num isolate: com anos de
  // histórico, o `fromMap` passa de 10 ms e travaria a thread principal.
  Future<MonthBalanceModel> getBalances() async {
    final response = await _call(
      () => _client.get(
        ClientRequest(url: '/balances', responseType: ResponseType.bytes),
      ),
    );
    return parseBalancesInBackground(
      Uint8List.fromList(response.data as List<int>),
    );
  }

  Future<void> createBalance(BalanceModel balance) => _call(
    () =>
        _client.post(ClientRequest(url: '/balances', body: balance.toApiMap())),
  );

  Future<void> updateBalance(String id, Map<String, dynamic> fields) => _call(
    () => _client.patch(ClientRequest(url: '/balances/$id', body: fields)),
  );

  Future<void> setInstallmentRealized(
    String id,
    int installment,
    bool realized,
  ) => _call(
    () => _client.patch(
      ClientRequest(
        url: '/balances/$id/installments/$installment',
        body: {'realized': realized},
      ),
    ),
  );

  Future<void> deleteBalance(String id) =>
      _call(() => _client.delete(ClientRequest(url: '/balances/$id')));

  Future<void> deleteInstallment(String id, int installment) => _call(
    () => _client.delete(
      ClientRequest(url: '/balances/$id/installments/$installment'),
    ),
  );

  // O HttpClient lança um ClientResponse quando a API responde com erro.
  Future<ClientResponse> _call(
    Future<ClientResponse> Function() request,
  ) async {
    try {
      return await request();
    } on ClientResponse catch (error) {
      throw ApiException(error.status ?? 500, _messageFor(error));
    }
  }

  String _messageFor(ClientResponse error) {
    if (error.status == 409) return 'Você já tem um lançamento com esse nome.';
    final data = error.data;
    if (data is Map && data['message'] is String) return data['message'];
    return 'Não foi possível falar com o servidor.';
  }
}
