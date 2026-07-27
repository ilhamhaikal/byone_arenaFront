import 'console_model.dart';
import 'customer_model.dart';

class SessionModel {
  final String id;
  final String consoleId;
  final ConsoleModel? console;
  final String? customerId;
  final CustomerModel? customer;
  final String status; // active, completed, cancelled
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final int? bookedDurationMinutes; // durasi yang dipesan di awal
  final DateTime? endScheduledAt; // waktu selesai yang direncanakan
  final double? totalPrice;
  final String? notes;
  // Bank Waktu & Poin Loyalitas
  final int paidDurationMinutes; // durasi yang benar-benar DIBAYAR (menit)
  final int timeBankMinutesUsed; // menit bonus dari saldo bank waktu
  final int bonusMinutesFromPoints; // menit bonus dari penukaran poin
  final int pointsRedeemed; // poin yang ditukar pada sesi ini
  final int pointsEarned; // poin yang didapat dari sesi ini
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SessionModel({
    required this.id,
    required this.consoleId,
    this.console,
    this.customerId,
    this.customer,
    required this.status,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    this.bookedDurationMinutes,
    this.endScheduledAt,
    this.totalPrice,
    this.notes,
    this.paidDurationMinutes = 0,
    this.timeBankMinutesUsed = 0,
    this.bonusMinutesFromPoints = 0,
    this.pointsRedeemed = 0,
    this.pointsEarned = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: (json['id'] as String?) ?? '',
      consoleId: (json['consoleId'] as String?) ?? '',
      console: json['console'] != null
          ? ConsoleModel.fromJson(json['console'] as Map<String, dynamic>)
          : null,
      customerId: json['customerId'] as String?,
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      status: (json['status'] as String?) ?? 'active',
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime:
          json['endTime'] != null ? DateTime.tryParse(json['endTime'].toString()) : null,
      durationMinutes: json['durationMinutes'] as int?,
      bookedDurationMinutes: json['bookedDurationMinutes'] as int?,
      endScheduledAt: json['endScheduledAt'] != null
          ? DateTime.tryParse(json['endScheduledAt'].toString())
          : null,
      totalPrice: json['totalPrice'] != null
          ? (json['totalPrice'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      paidDurationMinutes: (json['paidDurationMinutes'] as int?) ?? 0,
      timeBankMinutesUsed: (json['timeBankMinutesUsed'] as int?) ?? 0,
      bonusMinutesFromPoints: (json['bonusMinutesFromPoints'] as int?) ?? 0,
      pointsRedeemed: (json['pointsRedeemed'] as int?) ?? 0,
      pointsEarned: (json['pointsEarned'] as int?) ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'consoleId': consoleId,
        'status': status,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationMinutes': durationMinutes,
        'totalPrice': totalPrice,
        'notes': notes,
      };

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  Duration get elapsed => DateTime.now().difference(startTime);

  // Convenience getters untuk UI
  String get consoleType => console?.consoleType ?? '';
  String get consoleName => console?.name ?? '';
  double get pricePerHour => console?.pricePerHour ?? 0;
  String? get customerName => customer?.name;
}
