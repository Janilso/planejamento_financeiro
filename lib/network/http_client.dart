import 'dart:async';

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
        options: Options(headers: request.headers),
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

  ClientResponse _buildResponse(Response response) {
    return ClientResponse(status: response.statusCode, data: response.data);
  }

  ClientResponse _buildException(DioException exception) {
    return ClientResponse(
      status: exception.response?.statusCode ?? 500,
      data: exception.response?.data,
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

  ClientRequest({required this.url, this.body, this.headers, this.params});
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
