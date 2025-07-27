import 'dart:convert';
import 'package:planejamento_financeiro/models/balance.dart';

class GroupBalanceModel {
  final List<BalanceModel> gains;
  final List<BalanceModel> expenses;

  GroupBalanceModel(this.gains, this.expenses);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'gains': gains.map((x) => x.toMap()).toList(),
      'expenses': expenses.map((x) => x.toMap()).toList(),
    };
  }

  factory GroupBalanceModel.fromMap(Map<String, dynamic> map) {
    return GroupBalanceModel(
      List<BalanceModel>.from(
        (map['gains'] as List<dynamic>).map<BalanceModel>(
          (x) => BalanceModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
      List<BalanceModel>.from(
        (map['expenses'] as List<dynamic>).map<BalanceModel>(
          (x) => BalanceModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory GroupBalanceModel.fromJson(String source) =>
      GroupBalanceModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
