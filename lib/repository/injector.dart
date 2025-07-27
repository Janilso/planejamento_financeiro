import 'package:auto_injector/auto_injector.dart';
import 'package:dio/dio.dart';
import 'package:planejamento_financeiro/network/http_client.dart';
import 'package:planejamento_financeiro/repository/balance.dart';

final appInjector = AutoInjector(
  on: (i) {
    i.add<Dio>(DioFactory.instance);

    i.addSingleton(HttpClient.new);
    i.addSingleton(BalanceRepository.new);

    i.commit();
  },
);
