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

class BalanceRepository {
  BalanceRepository(this._client);

  final HttpClient _client;

  Future<MonthBalanceModel> getBalances() async {
    final response = await _call(
      () => _client.get(ClientRequest(url: '/balances')),
    );
    return MonthBalanceModel.fromMap(
      Map<String, dynamic>.from(response.data as Map),
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
