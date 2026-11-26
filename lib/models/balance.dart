// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class BalanceModel {
  String? uuid;
  String name;
  double? value;
  bool realized;
  String type;
  int installment;
  int totalInstallments;
  DateTime? date;
  DateTime? createdAt;
  DateTime? updatedAt;
  bool get isInstallmented => totalInstallments > 1;

  BalanceModel({
    this.uuid,
    this.name = "",
    this.value,
    this.realized = false,
    this.type = "",
    this.installment = 1,
    this.totalInstallments = 1,
    this.date,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uuid': uuid,
      'name': name,
      'value': value,
      'realized': realized,
      'type': type,
      'installment': installment,
      'totalInstallments': totalInstallments,
      'date': date?.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory BalanceModel.fromMap(Map<String, dynamic> map) {
    return BalanceModel(
      uuid: map['uuid'] != null ? map['uuid'] as String : null,
      name: map['name'] as String,
      value: map['value'] != null
          ? double.parse(map['value'].toString())
          : null,
      realized: map['realized'] as bool,
      type: map['type'] as String,
      installment: map['installment'] as int,
      totalInstallments: map['totalInstallments'] as int,
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BalanceModel.fromJson(String source) =>
      BalanceModel.fromMap(json.decode(source) as Map<String, dynamic>);

  BalanceModel copyWith({
    String? uuid,
    String? name,
    double? value,
    bool? realized,
    String? type,
    int? installment,
    int? totalInstallments,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BalanceModel(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      value: value ?? this.value,
      realized: realized ?? this.realized,
      type: type ?? this.type,
      installment: installment ?? this.installment,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
