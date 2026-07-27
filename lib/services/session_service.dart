import '../config/api_config.dart';
import '../models/session_model.dart';
import 'api_service.dart';

class SessionService {
  final ApiService _api = ApiService();

  Future<List<SessionModel>> getAll() async {
    final response = await _api.get(ApiConfig.sessions);
    final list = response['data'] as List<dynamic>;
    return list.map((e) => SessionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SessionModel>> getActive() async {
    final response = await _api.get(ApiConfig.activeSessions);
    final list = response['data'] as List<dynamic>;
    return list.map((e) => SessionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SessionModel> getById(String id) async {
    final response = await _api.get('${ApiConfig.sessions}/$id');
    return SessionModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<SessionModel> start({
    required String consoleId,
    required int bookedDurationMinutes,
    required double cashReceived,
    String? customerId,
    String? notes,
    String? voucherCode,
    int useTimeBankMinutes = 0,
    int redeemPointUnits = 0,
  }) async {
    final response = await _api.post(ApiConfig.startSession, {
      'consoleId': consoleId,
      'bookedDurationMinutes': bookedDurationMinutes,
      'cashReceived': cashReceived,
      if (customerId != null) 'customerId': customerId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (voucherCode != null && voucherCode.isNotEmpty) 'voucherCode': voucherCode,
      if (useTimeBankMinutes > 0) 'useTimeBankMinutes': useTimeBankMinutes,
      if (redeemPointUnits > 0) 'redeemPointUnits': redeemPointUnits,
    });
    // StartSessionResponse returns { session, payment }
    final data = response['data'] as Map<String, dynamic>;
    return SessionModel.fromJson(data['session'] as Map<String, dynamic>);
  }

  Future<SessionModel> end(String id) async {
    final response = await _api.patch('${ApiConfig.sessions}/$id/end', {});
    return SessionModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<SessionModel> cancel(String id) async {
    final response = await _api.patch('${ApiConfig.sessions}/$id/cancel', {});
    return SessionModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Tambah durasi sewa untuk sesi yang sedang aktif.
  /// Membuat pembayaran baru dengan status pending.
  /// Response bisa mengembalikan SessionModel atau string message.
  Future<SessionModel?> extend({
    required String id,
    required int additionalMinutes,
    required bool payNow,
    double cashReceived = 0,
    String? notes,
    String? voucherCode,
  }) async {
    final body = <String, dynamic>{
      'additionalMinutes': additionalMinutes,
      'payNow': payNow,
    };
    if (payNow) {
      body['cashReceived'] = cashReceived;
    }
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    if (voucherCode != null && voucherCode.isNotEmpty) {
      body['voucherCode'] = voucherCode;
    }
    final response = await _api.post('${ApiConfig.sessions}/$id/extend', body);
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return SessionModel.fromJson(data);
    }
    return getById(id);
  }
}
