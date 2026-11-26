import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/models/month_balance.dart';
import 'package:planejamento_financeiro/network/http_client.dart';

class BalanceRepository {
  final HttpClient _client;
  final dynamic res =
      '{"JUL/25":{"gains":[{"id":"id1","name":"Salário","value":1500,"date":"2025-07-02T18:03:57.502721","realized":false,"installment":5,"totalInstallments":12,"type":"gains"},{"id":"id2","name":"Venda da bicicleta","value":400,"date":"2025-07-07T18:03:57.502721","realized":true,"installment":1,"totalInstallments":1,"type":"gains"}],"expenses":[{"id":"id3","name":"Apartamento","value":1300,"date":"2025-07-02T18:03:57.502721","realized":true,"installment":1,"totalInstallments":12,"type":"expenses"},{"id":"id4","name":"Condomínio","value":500,"date":"2025-07-10T18:03:57.502721","realized":false,"installment":1,"totalInstallments":1,"type":"expenses"}]}}';
  BalanceRepository(this._client);

  Future<void> createBalance(BalanceModel balance) async {
    await _client.post(ClientRequest(url: "/posts", body: balance.toMap()));
  }

  Future<void> updateBalance(String id, Map<String, dynamic> fields) async {
    await _client.put(ClientRequest(url: "/posts/1", body: fields));
  }

  Future<MonthBalanceModel> getBalances() async {
    // final auth = AuthEntity.fromJson(await LocalStorage.get("auth"));
    // const newData

    await _client.get(ClientRequest(url: "/posts"));
    return MonthBalanceModel.fromJson(res);
  }
}
