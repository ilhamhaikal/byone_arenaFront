import 'payment_model.dart';

class PendingPaymentsResponse {
  final int pendingCount;
  final List<PaymentModel> payments;

  PendingPaymentsResponse({
    required this.pendingCount,
    required this.payments,
  });

  factory PendingPaymentsResponse.fromJson(Map<String, dynamic> json) {
    return PendingPaymentsResponse(
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) =>
                  PaymentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
