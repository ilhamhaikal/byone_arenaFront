import 'dart:convert';

import '../config/api_config.dart';
import '../models/license_model.dart';
import 'api_service.dart';

/// Klien API lisensi (status, aktivasi, riwayat).
class LicenseService {
  final ApiService _api = ApiService();

  Future<LicenseStatusModel> getStatus() async {
    final res = await _api.get('${ApiConfig.license}/status');
    return LicenseStatusModel.fromJson(
        (res['data'] as Map<String, dynamic>?) ?? const {});
  }

  Future<LicenseActivateResult> activate(String licenseKey,
      {bool force = false}) async {
    final res = await _api.post('${ApiConfig.license}/activate', {
      'licenseKey': licenseKey.trim(),
      'force': force,
    });
    return LicenseActivateResult.fromJson(
        (res['data'] as Map<String, dynamic>?) ?? const {});
  }

  /// Membuat kode aktivasi QR di license server vendor.
  Future<OnlineActivationStartModel> startOnlineActivation() async {
    final res = await _api.post('${ApiConfig.license}/online/start', const {});
    return OnlineActivationStartModel.fromJson(
        (res['data'] as Map<String, dynamic>?) ?? const {});
  }

  /// Meminta server billing melakukan polling ke vendor.
  Future<OnlineActivationPollModel> pollOnlineActivation() async {
    final res = await _api.get('${ApiConfig.license}/online/status');
    return OnlineActivationPollModel.fromJson(
        (res['data'] as Map<String, dynamic>?) ?? const {});
  }

  Future<List<LicenseHistoryModel>> getHistory() async {
    final res = await _api.get('${ApiConfig.license}/history');
    final data = res['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(LicenseHistoryModel.fromJson)
        .toList();
  }
}

/// Helper: membaca isi file lisensi dengan aman (UTF-8, buang BOM).
String decodeLicenseFile(List<int> bytes) {
  final text = utf8.decode(bytes, allowMalformed: true);
  return text.replaceFirst('\uFEFF', '').trim();
}
