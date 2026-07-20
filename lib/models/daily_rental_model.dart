/// Model untuk entity.DailyRental — rental harian (console dibawa pulang)
class DailyRentalModel {
  final String id;
  final String consoleId;
  final String? customerId;
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final int totalDays;
  final double dailyPrice;
  final double depositAmount;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final int freeDaysUsed;
  final String? voucherCode;
  final String? voucherName;
  final String status; // active, returned, overdue
  final String? notes;
  final String? returnedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relasi
  final String? consoleName;
  final String? consoleType;
  final String? customerName;

  DailyRentalModel({
    required this.id,
    required this.consoleId,
    this.customerId,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.dailyPrice,
    required this.depositAmount,
    required this.totalAmount,
    this.discountAmount = 0,
    this.finalAmount = 0,
    this.freeDaysUsed = 0,
    this.voucherCode,
    this.voucherName,
    required this.status,
    this.notes,
    this.returnedAt,
    required this.createdAt,
    required this.updatedAt,
    this.consoleName,
    this.consoleType,
    this.customerName,
  });

  factory DailyRentalModel.fromJson(Map<String, dynamic> json) {
    return DailyRentalModel(
      id: json['id'] as String,
      consoleId: json['consoleId'] as String,
      customerId: json['customerId'] as String?,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      totalDays: (json['totalDays'] as num?)?.toInt() ?? 0,
      dailyPrice: (json['dailyPrice'] as num?)?.toDouble() ?? 0,
      depositAmount: (json['depositAmount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0,
      freeDaysUsed: (json['freeDaysUsed'] as num?)?.toInt() ?? 0,
      voucherCode: json['voucherCode'] as String?,
      voucherName: json['voucherName'] as String?,
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String?,
      returnedAt: json['returnedAt'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      consoleName: json['console'] != null
          ? (json['console'] as Map<String, dynamic>)['name'] as String?
          : null,
      consoleType: json['console'] != null
          ? (json['console'] as Map<String, dynamic>)['consoleType'] as String?
          : null,
      customerName: json['customer'] != null
          ? (json['customer'] as Map<String, dynamic>)['name'] as String?
          : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isReturned => status == 'returned';
  bool get isOverdue => status == 'overdue';

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'returned':
        return 'Dikembalikan';
      case 'overdue':
        return 'Terlambat';
      default:
        return status;
    }
  }

  bool get isLate {
    if (!isActive) return false;
    if (endDate.isEmpty) return false;
    return DateTime.now().isAfter(DateTime.parse(endDate));
  }
}
