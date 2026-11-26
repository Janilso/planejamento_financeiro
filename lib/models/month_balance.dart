import 'dart:convert';

import 'package:planejamento_financeiro/models/group_balance.dart';

class MonthBalanceModel {
  final Map<String, GroupBalanceModel> months;

  MonthBalanceModel(this.months);

  Map<String, dynamic> toMap() {
    return months.map((key, value) => MapEntry(key, value.toMap()));
  }

  factory MonthBalanceModel.fromMap(Map<String, dynamic> map) {
    return MonthBalanceModel(
      map.map(
        (key, value) => MapEntry(
          key,
          GroupBalanceModel.fromMap(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory MonthBalanceModel.fromJson(String source) =>
      MonthBalanceModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
