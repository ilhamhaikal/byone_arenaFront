import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';

  /// Batas waktu setiap request. Tanpa ini UI bisa menggantung selamanya
  /// ketika server mati atau kabel LAN terputus.
  static const Duration _timeout = Duration(seconds: 15);

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

  /// Menjalankan request dengan timeout dan menerjemahkan kegagalan jaringan
  /// menjadi ApiException yang bisa ditampilkan ke pengguna.
  Future<http.Response> _guard(Future<http.Response> Function() send) async {
    try {
      return await send().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(
          'Server tidak merespons (${_timeout.inSeconds} detik). Periksa jaringan.', 0);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server. Periksa kabel/WiFi.', 0);
    } on http.ClientException catch (e) {
      throw ApiException('Koneksi ke server gagal: ${e.message}', 0);
    }
  }

  Future<Map<String, dynamic>> get(String path,
      [Map<String, String>? queryParams]) async {
    final headers = await _getHeaders();
    final response = await _guard(
        () => http.get(_buildUri(path, queryParams), headers: headers));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path,
      Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await _guard(() => http.post(
          _buildUri(path),
          headers: headers,
          body: jsonEncode(body),
        ));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path,
      Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await _guard(() => http.put(
          _buildUri(path),
          headers: headers,
          body: jsonEncode(body),
        ));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(String path,
      [Map<String, dynamic>? body]) async {
    final headers = await _getHeaders();
    final response = await _guard(() => http.patch(
          _buildUri(path),
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final headers = await _getHeaders();
    final response =
        await _guard(() => http.delete(_buildUri(path), headers: headers));
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    // Respons bisa kosong (204) atau bukan JSON (mis. halaman error proxy).
    // Jangan sampai FormatException menutupi pesan error yang sebenarnya.
    final raw = utf8.decode(response.bodyBytes).trim();
    Map<String, dynamic>? body;
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {
        body = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body ?? <String, dynamic>{'success': true};
    }

    // Token tidak valid/kedaluwarsa: hapus agar aplikasi meminta login ulang.
    if (response.statusCode == 401) {
      // ignore: unawaited_futures
      clearToken();
    }

    final message = body?['message']?.toString() ??
        _fallbackMessage(response.statusCode);
    throw ApiException(message, response.statusCode);
  }

  String _fallbackMessage(int status) {
    switch (status) {
      case 401:
        return 'Sesi berakhir, silakan login ulang.';
      case 403:
        return 'Anda tidak memiliki akses untuk tindakan ini.';
      case 404:
        return 'Data tidak ditemukan.';
      case 429:
        return 'Terlalu banyak percobaan. Coba lagi sebentar.';
      default:
        if (status >= 500) {
          return 'Server bermasalah (kode $status). Coba lagi.';
        }
        return 'Terjadi kesalahan (kode $status).';
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  /// True bila sesi tidak valid / belum login.
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}