import 'session_model.dart';
import 'voucher_model.dart';

class PaymentModel {
  final String id;
  final String sessionId;
  final SessionModel? session;
  final String? voucherId;
  final VoucherModel? voucher;
  final double amount;
  final double cashReceived;
  final double changeAmount;
  final double discountAmount; // nominal diskon yang diberikan
  final String paymentMethod; // cash
  final String paymentStatus; // pending, paid, refunded
  final String? notes;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.sessionId,
    this.session,
    this.voucherId,
    this.voucher,
    required this.amount,
    required this.cashReceived,
    required this.changeAmount,
    this.discountAmount = 0,
    required this.paymentMethod,
    required this.paymentStatus,
    this.notes,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      session: json['session'] != null
          ? SessionModel.fromJson(json['session'] as Map<String, dynamic>)
          : null,
      voucherId: json['voucherId'] as String?,
      voucher: json['voucher'] != null
          ? VoucherModel.fromJson(json['voucher'] as Map<String, dynamic>)
          : null,
      amount: (json['amount'] as num).toDouble(),
      cashReceived: (json['cashReceived'] as num).toDouble(),
      changeAmount: (json['changeAmount'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String,
      paymentStatus: json['paymentStatus'] as String,
      notes: json['notes'] as String?,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  bool get isPaid => paymentStatus == 'paid';
  bool get isPending => paymentStatus == 'pending';
  bool get isRefunded => paymentStatus == 'refunded';
  bool get hasDiscount => discountAmount > 0;
}
