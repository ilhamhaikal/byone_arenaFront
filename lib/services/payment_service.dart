import '../config/api_config.dart';
import '../models/payment_model.dart';
import '../models/pending_payments_response.dart';
import '../models/session_payments_summary.dart';
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

  /// Ambil SELURUH payment (base + semua perpanjangan) milik satu sesi,
  /// beserta total yang sudah dibayar & yang masih pending.
  /// Sumber kebenaran tunggal untuk total tagihan sesi — jangan hitung ulang
  /// di frontend (lihat docs/FRONTEND_SESSION_PAYMENT_FIX_GUIDE.md).
  Future<SessionPaymentsSummary> getAllBySession(String sessionId) async {
    final response = await _api.get('${ApiConfig.sessions}/$sessionId/payments');
    return SessionPaymentsSummary.fromJson(response['data'] as Map<String, dynamic>);
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

  /// Konfirmasi pembayaran pending (admin).
  /// Backend tidak memerlukan body — cukup panggil dengan ID.
  Future<PaymentModel> confirm(String id, {double? cashReceived}) async {
    final body = <String, dynamic>{};
    if (cashReceived != null && cashReceived > 0) {
      body['cashReceived'] = cashReceived;
    }
    final response = await _api.post('${ApiConfig.payments}/$id/confirm', body);
    return PaymentModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Ambil semua pembayaran pending.
  Future<PendingPaymentsResponse> getPending() async {
    final response = await _api.get('${ApiConfig.payments}/pending');
    return PendingPaymentsResponse.fromJson(
        response['data'] as Map<String, dynamic>);
  }
}
