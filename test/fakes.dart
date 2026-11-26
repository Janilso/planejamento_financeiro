import 'package:planejamento_financeiro/models/balance.dart';
import 'package:planejamento_financeiro/models/month_balance.dart';
import 'package:planejamento_financeiro/repository/balance.dart';

// Repositório falso: devolve os dados programados e conta as chamadas.
class FakeBalanceRepository implements BalanceRepository {
  FakeBalanceRepository({this.data, this.error});

  Map<String, dynamic>? data;
  Object? error;
  Object? saveError;
  int getCalls = 0;
  int createCalls = 0;
  double? lastCreatedValue;

  @override
  dynamic get res => null;

  @override
  Future<MonthBalanceModel> getBalances() async {
    getCalls++;
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
    if (saveError != null) throw saveError!;
  }
}

Map<String, dynamic> balanceJson(
  String name,
  double value,
  String type, {
  String date = '2026-11-15T12:00:00.000',
}) => {
  'id': 'id-$name',
  'name': name,
  'value': value,
  'realized': true,
  'type': type,
  'installment': 1,
  'totalInstallments': 1,
  'date': date,
};
