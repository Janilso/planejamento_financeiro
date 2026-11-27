import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:planejamento_financeiro/network/api_config.dart';

class DioFactory {
  static Dio instance() => Dio(
    BaseOptions(
      baseUrl: apiUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {Headers.contentTypeHeader: "application/json"},
    ),
  );
}

class HttpClient {
  final Dio _client;

  HttpClient(this._client);

  Future<ClientResponse> get(ClientRequest request) async {
    try {
      final response = await _client.get(
        request.url,
        queryParameters: request.params,
        options: Options(
          headers: request.headers,
          responseType: request.responseType,
        ),
      );
      return _buildResponse(response);
    } on DioException catch (e) {
      throw _buildException(e);
    }
  }

  Future<ClientResponse> post(ClientRequest request) async {
    try {
      final response = await _client.post(
        request.url,
        data: request.body,
        queryParameters: request.params,
        options: Options(headers: request.headers),
      );
      return _buildResponse(response);
    } on DioException catch (e) {
      throw _buildException(e);
    }
  }

  Future<ClientResponse> put(ClientRequest request) async {
    try {
      final response = await _client.put(
        request.url,
        data: request.body,
        queryParameters: request.params,
        options: Options(headers: request.headers),
      );
      return _buildResponse(response);
    } on DioException catch (e) {
      throw _buildException(e);
    }
  }

  Future<ClientResponse> patch(ClientRequest request) async {
    try {
      final response = await _client.patch(
        request.url,
        data: request.body,
        queryParameters: request.params,
        options: Options(headers: request.headers),
      );
      return _buildResponse(response);
    } on DioException catch (e) {
      throw _buildException(e);
    }
  }

  Future<ClientResponse> delete(ClientRequest request) async {
    try {
      final response = await _client.delete(
        request.url,
        data: request.body,
        queryParameters: request.params,
        options: Options(headers: request.headers),
      );
      return _buildResponse(response);
    } on DioException catch (e) {
      throw _buildException(e);
    }
  }

  // Com ResponseType.bytes o erro também vem em bytes: volta a ser o JSON, para
  // o repositório achar a `message` da API.
  Object? _errorBody(Object? data) {
    if (data is! List<int>) return data;
    try {
      return jsonDecode(utf8.decode(data));
    } catch (_) {
      return data;
    }
  }

  ClientResponse _buildResponse(Response response) {
    return ClientResponse(status: response.statusCode, data: response.data);
  }

  ClientResponse _buildException(DioException exception) {
    return ClientResponse(
      status: exception.response?.statusCode ?? 500,
      data: _errorBody(exception.response?.data),
      message: exception.message,
      error: exception.error,
    );
  }
}

class ClientRequest {
  final String url;
  final Object? body;
  final Map<String, dynamic>? headers;
  final Map<String, dynamic>? params;
  // ResponseType.bytes entrega o corpo cru, para decodificar fora da thread
  // principal (veja parseBalances).
  final ResponseType? responseType;

  ClientRequest({
    required this.url,
    this.body,
    this.headers,
    this.params,
    this.responseType,
  });
}

class ClientResponse {
  final int? status;
  final String? message;
  final dynamic data;
  final dynamic error;

  ClientResponse({
    required this.status,
    required this.data,
    this.message,
    this.error,
  });

  @override
  String toString() {
    return 'status: $status, data: $data, data: $message, data: $error';
  }
}
