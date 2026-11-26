import 'dart:math';

import 'package:intl/intl.dart';

// Meses sempre no dia 1: manter o dia de hoje (ex.: 31) faz o DateTime
// pular para o mês seguinte e repetir ou sumir meses nas abas.

List<DateTime> monthsBefore(DateTime month, int count) => [
  for (var i = count; i >= 1; i--) DateTime(month.year, month.month - i, 1),
];

List<DateTime> monthsAfter(DateTime month, int count) => [
  for (var i = 1; i <= count; i++) DateTime(month.year, month.month + i, 1),
];

List<DateTime> monthsAround(
  DateTime center, {
  int before = 12,
  int after = 12,
}) => [
  ...monthsBefore(center, before),
  DateTime(center.year, center.month, 1),
  ...monthsAfter(center, after),
];

// Data de um lançamento novo no mês da aba: hoje, se for o mês atual;
// senão, o dia de hoje limitado ao último dia daquele mês.
DateTime dateForNewBalance(DateTime month, DateTime today) {
  if (month.year == today.year && month.month == today.month) return today;
  final lastDay = DateTime(month.year, month.month + 1, 0).day;
  return DateTime(month.year, month.month, min(today.day, lastDay));
}

// Chave do mês igual à da API: "MAI/26".
String monthKey(DateTime month) => DateFormat(
  'MMM/yy',
  'pt_BR',
).format(month).toUpperCase().replaceAll('.', '');
