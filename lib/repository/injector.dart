import 'package:auto_injector/auto_injector.dart';
import 'package:dio/dio.dart';
import 'package:planejamento_financeiro/network/auth_interceptor.dart';
import 'package:planejamento_financeiro/network/http_client.dart';
import 'package:planejamento_financeiro/network/session_events.dart';
import 'package:planejamento_financeiro/repository/auth.dart';
import 'package:planejamento_financeiro/repository/balance.dart';
import 'package:planejamento_financeiro/repository/token_storage.dart';

final appInjector = AutoInjector(
  on: (i) {
    final TokenStorage tokenStorage = SecureTokenStorage();

    // As rotas /auth usam um Dio sem o interceptor, para o refresh não
    // disparar outro refresh.
    final authRepository = AuthRepository(
      HttpClient(DioFactory.instance()),
      tokenStorage,
    );

    final apiDio = DioFactory.instance();
    apiDio.interceptors.add(
      AuthInterceptor(
        dio: apiDio,
        storage: tokenStorage,
        refresh: authRepository.refresh,
        onSessionExpired: () => onSessionExpiredHandler?.call(),
      ),
    );

    i.addInstance<TokenStorage>(tokenStorage);
    i.addInstance<AuthRepository>(authRepository);
    i.addInstance<Dio>(apiDio);
    i.addSingleton(HttpClient.new);
    i.addSingleton(BalanceRepository.new);

    i.commit();
  },
);
