import '../config/api_config.dart';
import 'api_service.dart';

/// Klien API untuk pairing TV (kode 6 digit) di aplikasi admin.
class DevicePairingService {
  final ApiService _api = ApiService();

  /// Validasi kode pairing dan ambil info perangkat (IP, nama, deviceId)
  /// TANPA mengikatnya ke konsol. Dipakai form Tambah Konsol agar kolom IP
  /// bisa terisi otomatis dari TV.
  Future<Map<String, dynamic>> resolveCode(String code) async {
    final response = await _api.post(ApiConfig.devices + '/resolve-code', {
      'code': code,
    });
    return (response['data'] as Map<String, dynamic>?) ?? const {};
  }

  /// Hubungkan TV (berdasarkan kode yang tampil di layar TV) ke sebuah konsol.
  ///
  /// Melempar [ApiException] bila kode salah/kedaluwarsa atau konsol sudah
  /// terpakai TV lain.
  Future<Map<String, dynamic>> bindByCode({
    required String code,
    required String consoleId,
  }) async {
    final response = await _api.post(ApiConfig.devices + '/bind-by-code', {
      'code': code,
      'consoleId': consoleId,
    });
    return (response['data'] as Map<String, dynamic>?) ?? const {};
  }

  /// Lepaskan TV dari konsol agar bisa dipakai TV lain.
  Future<void> unbindConsole(String consoleId) async {
    await _api.delete('${ApiConfig.devices}/console/$consoleId');
  }
}
