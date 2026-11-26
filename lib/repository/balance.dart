import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/models/month_balance.dart';
import 'package:planejamento_financeiro/network/http_client.dart';

class BalanceRepository {
  // Volta a ser usado quando a B11 ligar o repositório à API.
  // ignore: unused_field
  final HttpClient _client;
  final dynamic res =
      '{"JUL/25":{"gains":[{"id":"id1","name":"Salário","value":1500,"date":"2025-07-02T18:03:57.502721","realized":false,"installment":5,"totalInstallments":12,"type":"gains"},{"id":"id2","name":"Venda da bicicleta","value":400,"date":"2025-07-07T18:03:57.502721","realized":true,"installment":1,"totalInstallments":1,"type":"gains"}],"expenses":[{"id":"id3","name":"Apartamento","value":1300,"date":"2025-07-02T18:03:57.502721","realized":true,"installment":1,"totalInstallments":12,"type":"expenses"},{"id":"id4","name":"Condomínio","value":500,"date":"2025-07-10T18:03:57.502721","realized":false,"installment":1,"totalInstallments":1,"type":"expenses"}]}}';
  BalanceRepository(this._client);

  // Ainda mockado: devolve os dados de exemplo sem chamar a rede.
  // A B11 liga este repositório à API.
  Future<void> createBalance(BalanceModel balance) async {}

  Future<void> updateBalance(String id, Map<String, dynamic> fields) async {}

  Future<MonthBalanceModel> getBalances() async {
    return MonthBalanceModel.fromJson(res);
  }
}
