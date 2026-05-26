import 'session_model.dart';

class PaymentModel {
  final String id;
  final String sessionId;
  final SessionModel? session;
  final double amount;
  final double cashReceived;
  final double changeAmount;
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
    required this.amount,
    required this.cashReceived,
    required this.changeAmount,
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
      amount: (json['amount'] as num).toDouble(),
      cashReceived: (json['cashReceived'] as num).toDouble(),
      changeAmount: (json['changeAmount'] as num).toDouble(),
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
}
