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
  }) async {
    final response = await _api.post(ApiConfig.startSession, {
      'consoleId': consoleId,
      'bookedDurationMinutes': bookedDurationMinutes,
      'cashReceived': cashReceived,
      if (customerId != null) 'customerId': customerId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (voucherCode != null && voucherCode.isNotEmpty) 'voucherCode': voucherCode,
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
}
