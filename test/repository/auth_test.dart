import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planejamento_financeiro/network/auth_interceptor.dart';
import 'package:planejamento_financeiro/network/http_client.dart';
import 'package:planejamento_financeiro/repository/auth.dart';
import 'package:planejamento_financeiro/repository/token_storage.dart';

import '../fakes.dart';

void main() {
  late InMemoryTokenStorage storage;
  late FakeHttpAdapter authAdapter;
  late FakeHttpAdapter apiAdapter;
  late AuthRepository auth;
  late Dio api;
  late int expired;

  setUp(() {
    storage = InMemoryTokenStorage();
    authAdapter = FakeHttpAdapter();
    apiAdapter = FakeHttpAdapter();
    auth = AuthRepository(
      HttpClient(
        Dio(BaseOptions(baseUrl: 'http://api.test'))
          ..httpClientAdapter = authAdapter,
      ),
      storage,
    );
    expired = 0;
    api = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = apiAdapter;
    api.interceptors.add(
      AuthInterceptor(
        dio: api,
        storage: storage,
        refresh: auth.refresh,
        onSessionExpired: () => expired++,
      ),
    );
  });

  test('login guarda os tokens', () async {
    authAdapter.responses.add(
      const FakeResponse(200, {'token': 't', 'refreshToken': 'r'}),
    );

    await auth.loginWithGoogleIdToken('id-token-google');

    expect(authAdapter.requests.single.data, {
      'googleToken': 'id-token-google',
    });
    expect(storage.tokens?.token, 't');
    expect(storage.tokens?.refreshToken, 'r');
  });

  test('requisições levam o Bearer', () async {
    storage.tokens = const AuthTokens(token: 't', refreshToken: 'r');

    await api.get('/balances');

    expect(apiAdapter.requests.single.headers['Authorization'], 'Bearer t');
  });

  test('401 renova o token e repete a requisição', () async {
    storage.tokens = const AuthTokens(token: 't', refreshToken: 'r');
    apiAdapter.responses.addAll([
      const FakeResponse(401, {}),
      const FakeResponse(200, {'ok': true}),
    ]);
    authAdapter.responses.add(
      const FakeResponse(200, {'token': 't2', 'refreshToken': 'r2'}),
    );

    final res = await api.get('/balances');

    expect(res.statusCode, 200);
    expect(authAdapter.requests, hasLength(1));
    expect(authAdapter.requests.single.data, {'refreshToken': 'r'});
    expect(apiAdapter.requests.last.headers['Authorization'], 'Bearer t2');
  });

  test('dois 401 simultâneos renovam uma vez só', () async {
    storage.tokens = const AuthTokens(token: 't', refreshToken: 'r');
    apiAdapter.responses.addAll([
      const FakeResponse(401, {}),
      const FakeResponse(401, {}),
      const FakeResponse(200, {}),
      const FakeResponse(200, {}),
    ]);
    authAdapter.responses.add(
      const FakeResponse(200, {'token': 't2', 'refreshToken': 'r2'}),
    );

    final results = await Future.wait([api.get('/a'), api.get('/b')]);

    expect(results.map((r) => r.statusCode), [200, 200]);
    expect(authAdapter.requests, hasLength(1));
  });

  test('refresh que falha encerra a sessão', () async {
    storage.tokens = const AuthTokens(token: 't', refreshToken: 'r');
    apiAdapter.responses.add(const FakeResponse(401, {}));
    authAdapter.responses.add(const FakeResponse(401, {}));

    await expectLater(api.get('/balances'), throwsA(isA<DioException>()));

    expect(storage.tokens, isNull);
    expect(expired, 1);
    expect(apiAdapter.requests, hasLength(1));
  });
}
