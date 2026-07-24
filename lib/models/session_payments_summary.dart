import 'payment_model.dart';

/// Ringkasan seluruh pembayaran milik satu sesi (base + semua perpanjangan).
/// Diambil dari `GET /sessions/{session_id}/payments` — sumber kebenaran
/// tunggal untuk total tagihan sesi, JANGAN dihitung ulang di frontend.
class SessionPaymentsSummary {
  final List<PaymentModel> payments;
  final double totalAmount;
  final double totalPaid;
  final double totalPending;

  SessionPaymentsSummary({
    required this.payments,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalPending,
  });

  factory SessionPaymentsSummary.fromJson(Map<String, dynamic> json) {
    return SessionPaymentsSummary(
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0,
      totalPending: (json['totalPending'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Semua baris payment yang masih berstatus pending (bisa lebih dari satu
  /// jika sesi sudah di-extend beberapa kali tanpa dibayar langsung).
  List<PaymentModel> get pendingPayments =>
      payments.where((p) => p.isPending).toList();

  bool get hasPending => totalPending > 0;
}
