class RentalModel {
  final int id;
  final String rentalCode;
  final int consoleNumber;
  final String consoleType; // 'PS4', 'PS5'
  final int? memberId;
  final String? memberName;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final double pricePerHour;
  final double? totalPrice;
  final double? discountAmount;
  final String? voucherCode;
  final double? finalPrice;
  final String status; // 'active', 'completed', 'cancelled'
  final String? notes;

  RentalModel({
    required this.id,
    required this.rentalCode,
    required this.consoleNumber,
    required this.consoleType,
    this.memberId,
    this.memberName,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.pricePerHour,
    this.totalPrice,
    this.discountAmount,
    this.voucherCode,
    this.finalPrice,
    required this.status,
    this.notes,
  });

  factory RentalModel.fromJson(Map<String, dynamic> json) {
    return RentalModel(
      id: json['id'],
      rentalCode: json['rental_code'],
      consoleNumber: json['console_number'],
      consoleType: json['console_type'],
      memberId: json['member_id'],
      memberName: json['member_name'],
      startTime: DateTime.parse(json['start_time']),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      durationMinutes: json['duration_minutes'],
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      totalPrice: json['total_price'] != null
          ? (json['total_price'] as num).toDouble()
          : null,
      discountAmount: json['discount_amount'] != null
          ? (json['discount_amount'] as num).toDouble()
          : null,
      voucherCode: json['voucher_code'],
      finalPrice: json['final_price'] != null
          ? (json['final_price'] as num).toDouble()
          : null,
      status: json['status'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'console_number': consoleNumber,
        'console_type': consoleType,
        'member_id': memberId,
        'price_per_hour': pricePerHour,
        'notes': notes,
      };

  Duration get elapsed => DateTime.now().difference(startTime);

  bool get isActive => status == 'active';
}
