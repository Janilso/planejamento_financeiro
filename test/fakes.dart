import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/models/month_balance.dart';
import 'package:planejamento_financeiro/repository/balance.dart';
import 'package:planejamento_financeiro/repository/token_storage.dart';

// Repositório falso: devolve os dados programados e conta as chamadas.
class FakeBalanceRepository implements BalanceRepository {
  FakeBalanceRepository({this.data, this.error});

  Map<String, dynamic>? data;
  Object? error;
  Object? saveError;
  int getCalls = 0;
  // Com segurarBuscas, cada getBalances() fica pendente até o teste completar
  // o Completer correspondente: simula respostas que chegam fora de ordem.
  bool segurarBuscas = false;
  final List<Completer<MonthBalanceModel>> buscasPendentes = [];
  int createCalls = 0;
  double? lastCreatedValue;

  @override
  Future<MonthBalanceModel> getBalances() async {
    getCalls++;
    if (segurarBuscas) {
      final pendente = Completer<MonthBalanceModel>();
      buscasPendentes.add(pendente);
      return pendente.future;
    }
    if (error != null) throw error!;
    return MonthBalanceModel.fromMap(data ?? {});
  }

  @override
  Future<void> createBalance(BalanceModel balance) async {
    createCalls++;
    lastCreatedValue = balance.value;
    if (saveError != null) throw saveError!;
  }

  @override
  Future<void> updateBalance(String id, Map<String, dynamic> fields) async {
    calls.add('update $id $fields');
    if (saveError != null) throw saveError!;
  }

  final List<String> calls = [];

  @override
  Future<void> setInstallmentRealized(
    String id,
    int installment,
    bool realized,
  ) async {
    calls.add('realized $id $installment $realized');
    if (saveError != null) throw saveError!;
  }

  @override
  Future<void> deleteBalance(String id) async {
    calls.add('deleteBalance $id');
    if (saveError != null) throw saveError!;
  }

  @override
  Future<void> deleteInstallment(String id, int installment) async {
    calls.add('deleteInstallment $id $installment');
    if (saveError != null) throw saveError!;
  }
}

Map<String, dynamic> balanceJson(
  String name,
  double value,
  String type, {
  String date = '2026-11-15T12:00:00.000',
  String? id,
  int installment = 1,
  int totalInstallments = 1,
  bool realized = true,
  double? totalValue,
}) => {
  'id': id ?? 'id-$name',
  'name': name,
  'value': value,
  'realized': realized,
  'type': type,
  'installment': installment,
  'totalInstallments': totalInstallments,
  'date': date,
  'totalValue': ?totalValue,
};

// Adaptador falso do Dio: registra as requisições e devolve respostas programadas.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter([List<FakeResponse>? responses])
    : responses = responses ?? [];

  final List<FakeResponse> responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final next = responses.isNotEmpty
        ? responses.removeAt(0)
        : const FakeResponse(200, {});
    return ResponseBody.fromString(
      jsonEncode(next.body),
      next.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeResponse {
  const FakeResponse(this.status, this.body);
  final int status;
  final Object body;
}

// Armazenamento de tokens em memória (o seguro depende do Android).
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this.tokens]);

  AuthTokens? tokens;

  @override
  Future<AuthTokens?> read() async => tokens;

  @override
  Future<void> save(AuthTokens tokens) async => this.tokens = tokens;

  @override
  Future<void> clear() async => tokens = null;
}
