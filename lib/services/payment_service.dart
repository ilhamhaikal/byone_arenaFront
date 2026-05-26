import '../config/api_config.dart';
import '../models/payment_model.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _api = ApiService();

  Future<PaymentModel> getById(String id) async {
    final response = await _api.get('${ApiConfig.payments}/$id');
    return PaymentModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<PaymentModel> getBySession(String sessionId) async {
    final response = await _api.get('${ApiConfig.sessions}/$sessionId/payment');
    return PaymentModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// [voucherCode] opsional — kode voucher diskon
  Future<PaymentModel> createCash({
    required String sessionId,
    required double cashReceived,
    String? voucherCode,
    String? notes,
  }) async {
    final response = await _api.post(ApiConfig.payments, {
      'sessionId': sessionId,
      'cashReceived': cashReceived,
      if (voucherCode != null && voucherCode.isNotEmpty) 'voucherCode': voucherCode,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return PaymentModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<PaymentModel> refund(String id) async {
    final response = await _api.patch('${ApiConfig.payments}/$id/refund', {});
    return PaymentModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
