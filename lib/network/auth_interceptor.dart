import 'package:dio/dio.dart';
import 'package:planejamento_financeiro/repository/token_storage.dart';

// Põe o token em toda requisição e, num 401/403, renova o token uma vez e
// repete a requisição. Como é um QueuedInterceptor, os erros são tratados
// um de cada vez: dois 401 simultâneos geram um refresh só.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.dio,
    required this.storage,
    required this.refresh,
    required this.onSessionExpired,
  });

  final Dio dio;
  final TokenStorage storage;
  final Future<bool> Function() refresh;
  final void Function() onSessionExpired;

  static const _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await storage.read();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.token}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final status = err.response?.statusCode;
    if ((status != 401 && status != 403) ||
        options.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    // Outro erro da fila já pode ter renovado o token: aí só repete.
    final current = await storage.read();
    final usedToken = options.headers['Authorization'];
    final alreadyRefreshed =
        current != null && usedToken != 'Bearer ${current.token}';

    if (!alreadyRefreshed && !await refresh()) {
      await storage.clear();
      onSessionExpired();
      return handler.next(err);
    }

    try {
      options.extra[_retriedKey] = true;
      handler.resolve(await dio.fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
