import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<Map<String, dynamic>> get(String path,
      [Map<String, String>? queryParams]) async {
    final headers = await _getHeaders();
    final response = await http.get(
      _buildUri(path, queryParams),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path,
      Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      _buildUri(path),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path,
      Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      _buildUri(path),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(String path,
      [Map<String, dynamic>? body]) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      _buildUri(path),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      _buildUri(path),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }
    final message = (body is Map && body.containsKey('message'))
        ? body['message']
        : 'Terjadi kesalahan server';
    throw ApiException(message, response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
