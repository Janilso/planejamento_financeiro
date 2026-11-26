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
}
