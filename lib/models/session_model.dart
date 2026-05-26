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
  final double? totalPrice;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    this.totalPrice,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      consoleId: json['consoleId'] as String,
      console: json['console'] != null
          ? ConsoleModel.fromJson(json['console'] as Map<String, dynamic>)
          : null,
      customerId: json['customerId'] as String?,
      customer: json['customer'] != null
          ? CustomerModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime:
          json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      durationMinutes: json['durationMinutes'] as int?,
      totalPrice: json['totalPrice'] != null
          ? (json['totalPrice'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
