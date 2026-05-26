/// Model untuk response GET /api/v1/consoles/overview
/// Berisi data konsol + sesi aktif (jika ada)

class ActiveSessionInfo {
  final String id;
  final DateTime startTime;
  final int bookedDurationMinutes; // menit yang dipesan (min: 60)
  final DateTime? endScheduledAt; // startTime + bookedDurationMinutes
  final int remainingMinutes; // -1 = open-ended
  final String? customerId;
  final String? customerName;
  final String? notes;

  ActiveSessionInfo({
    required this.id,
    required this.startTime,
    required this.bookedDurationMinutes,
    this.endScheduledAt,
    required this.remainingMinutes,
    this.customerId,
    this.customerName,
    this.notes,
  });

  factory ActiveSessionInfo.fromJson(Map<String, dynamic> json) {
    return ActiveSessionInfo(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      bookedDurationMinutes: (json['bookedDurationMinutes'] as int?) ?? 60,
      endScheduledAt: json['endScheduledAt'] != null
          ? DateTime.parse(json['endScheduledAt'] as String)
          : null,
      remainingMinutes: (json['remainingMinutes'] as int?) ?? -1,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// Durasi bermain sejak startTime
  Duration get elapsed => DateTime.now().difference(startTime);

  /// Sisa waktu dari endScheduledAt. Null jika open-ended.
  Duration? get remaining {
    if (endScheduledAt == null) return null;
    final r = endScheduledAt!.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  /// True jika sudah melewati waktu yang dipesan
  bool get isOvertime =>
      endScheduledAt != null && DateTime.now().isAfter(endScheduledAt!);

  /// Progress 0.0–1.0 (bisa lebih jika overtime)
  double get progress {
    if (bookedDurationMinutes <= 0) return 0;
    return elapsed.inSeconds / (bookedDurationMinutes * 60);
  }
}

class ConsoleOverviewModel {
  final String id;
  final String name;
  final String consoleType; // PS3, PS4, PS5, AndroidTV
  final double pricePerHour;
  final String status; // available, in_use, maintenance
  final String? description;
  final String? ipAddress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ActiveSessionInfo? activeSession;

  ConsoleOverviewModel({
    required this.id,
    required this.name,
    required this.consoleType,
    required this.pricePerHour,
    required this.status,
    this.description,
    this.ipAddress,
    required this.createdAt,
    required this.updatedAt,
    this.activeSession,
  });

  factory ConsoleOverviewModel.fromJson(Map<String, dynamic> json) {
    return ConsoleOverviewModel(
      id: json['id'] as String,
      name: json['name'] as String,
      consoleType: (json['consoleType'] as String?) ?? 'PS4',
      pricePerHour: (json['pricePerHour'] as num).toDouble(),
      status: (json['status'] as String?) ?? 'available',
      description: json['description'] as String?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      activeSession: json['activeSession'] != null
          ? ActiveSessionInfo.fromJson(
              json['activeSession'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isAvailable => status == 'available';
  bool get isInUse => status == 'in_use';
  bool get isMaintenance => status == 'maintenance';
  bool get isAndroidTV => consoleType == 'AndroidTV';
}
