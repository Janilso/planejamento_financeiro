import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planejamento_financeiro/network/http_client.dart';

import '../fakes.dart';

void main() {
  late FakeHttpAdapter adapter;
  late HttpClient client;

  setUp(() {
    adapter = FakeHttpAdapter();
    client = HttpClient(
      Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter,
    );
  });

  test('get repassa headers e params', () async {
    await client.get(
      ClientRequest(url: '/x', headers: {'x-test': '1'}, params: {'a': 1}),
    );

    final request = adapter.requests.single;
    expect(request.headers['x-test'], '1');
    expect(request.uri.query, 'a=1');
  });

  test('patch envia o corpo', () async {
    await client.patch(ClientRequest(url: '/b', body: {'name': 'X'}));

    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.data, {'name': 'X'});
  });

  test('get repassa o responseType', () async {
    adapter.responses.add(const FakeResponse(200, {'a': 1}));

    final response = await client.get(
      ClientRequest(url: '/x', responseType: ResponseType.bytes),
    );

    expect(adapter.requests.single.responseType, ResponseType.bytes);
    expect(response.data, isA<List<int>>());
  });

  test('erro em bytes volta como mapa', () async {
    adapter.responses.add(const FakeResponse(400, {'message': 'Erro X'}));

    await expectLater(
      client.get(ClientRequest(url: '/x', responseType: ResponseType.bytes)),
      throwsA(
        isA<ClientResponse>()
            .having((e) => e.status, 'status', 400)
            .having((e) => e.data['message'], 'message', 'Erro X'),
      ),
    );
  });
}
