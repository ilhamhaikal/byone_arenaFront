/// Model untuk entity.Booking — reservasi konsol di masa depan
class BookingModel {
  final String id;
  final String consoleId;
  final String? customerId;
  final String bookingDate; // YYYY-MM-DD
  final int startHour; // 0-23
  final int startMinute; // 0-59
  final int durationMinutes;
  final String status; // pending, confirmed, cancelled, completed
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relasi (nullable, dari join)
  final String? consoleName;
  final String? consoleType;
  final String? customerName;

  BookingModel({
    required this.id,
    required this.consoleId,
    this.customerId,
    required this.bookingDate,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.consoleName,
    this.consoleType,
    this.customerName,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      consoleId: json['consoleId'] as String,
      customerId: json['customerId'] as String?,
      bookingDate: json['bookingDate'] as String? ?? '',
      startHour: (json['startHour'] as num?)?.toInt() ?? 0,
      startMinute: (json['startMinute'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      // Relasi dari join
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

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'cancelled':
        return 'Dibatalkan';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  String get timeSlot {
    final h = startHour.toString().padLeft(2, '0');
    final m = startMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get durationLabel {
    if (durationMinutes < 60) return '$durationMinutes mnt';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m > 0 ? '$h jam $m mnt' : '$h jam';
  }
}
