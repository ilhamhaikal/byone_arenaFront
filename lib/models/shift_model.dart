import 'user_model.dart';

class ShiftModel {
  final String id;
  final String userId;
  final UserModel? user;
  final String name;
  final int startHour; // 0-23
  final int endHour; // 0-23
  final bool is24Hour;
  final String status; // active, inactive
  final DateTime createdAt;
  final DateTime updatedAt;

  ShiftModel({
    required this.id,
    required this.userId,
    this.user,
    required this.name,
    required this.startHour,
    required this.endHour,
    required this.is24Hour,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      name: json['name'] as String,
      startHour: json['startHour'] as int,
      endHour: json['endHour'] as int,
      is24Hour: json['is24Hour'] as bool? ?? false,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'startHour': startHour,
        'endHour': endHour,
        'is24Hour': is24Hour,
        'status': status,
      };

  bool get isActive => status == 'active';

  String get scheduleLabel {
    if (is24Hour) return '24 Jam';
    final start = startHour.toString().padLeft(2, '0');
    final end = endHour.toString().padLeft(2, '0');
    return '$start:00 - $end:00';
  }
}
