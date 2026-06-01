import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/secure_storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}

class ApiClient {
  final SecureStorageService _storage;
  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 15);

  ApiClient({SecureStorageService? storage, http.Client? client})
      : _storage = storage ?? SecureStorageService(),
        _client = client ?? http.Client();

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await _storage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String url,
      {Map<String, String>? queryParams, bool withAuth = true}) async {
    try {
      var uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final response = await _client
          .get(uri, headers: await _headers(withAuth: withAuth))
          .timeout(_timeout);
      return await _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException {
      throw ApiException('Connection failed');
    }
  }

  Future<dynamic> post(String url,
      {Map<String, dynamic>? body, bool withAuth = true}) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: await _headers(withAuth: withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return await _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException {
      throw ApiException('Connection failed');
    }
  }

  Future<dynamic> put(String url,
      {Map<String, dynamic>? body, bool withAuth = true}) async {
    try {
      final response = await _client
          .put(
            Uri.parse(url),
            headers: await _headers(withAuth: withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return await _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException {
      throw ApiException('Connection failed');
    }
  }

  Future<dynamic> patch(String url,
      {Map<String, dynamic>? body, bool withAuth = true}) async {
    try {
      final response = await _client
          .patch(
            Uri.parse(url),
            headers: await _headers(withAuth: withAuth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);
      return await _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException {
      throw ApiException('Connection failed');
    }
  }

  Future<dynamic> delete(String url,
      {bool withAuth = true}) async {
    try {
      final response = await _client
          .delete(Uri.parse(url), headers: await _headers(withAuth: withAuth))
          .timeout(_timeout);
      return await _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on http.ClientException {
      throw ApiException('Connection failed');
    }
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data is Map ? (data['message'] as String? ?? 'Request failed') : 'Request failed';
    final code = data is Map ? data['code'] as String? : null;

    if (response.statusCode == 401 && code == 'TOKEN_EXPIRED') {
      await _storage.clearAll();
      throw ApiException('Session expired. Please login again.',
          statusCode: 401, code: 'TOKEN_EXPIRED');
    }

    throw ApiException(message,
        statusCode: response.statusCode, code: code);
  }

  void dispose() {
    _client.close();
  }
}
