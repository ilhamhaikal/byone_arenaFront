/// Model for GET /api/v1/consoles/{id}/tv-logs response item.
class TvLogEntry {
  final String id;
  final String consoleId;
  final String? consoleName;
  final String action; // "on", "off", "screensaver"
  final bool unauthorized;
  final DateTime timestamp;

  TvLogEntry({
    required this.id,
    required this.consoleId,
    this.consoleName,
    required this.action,
    required this.unauthorized,
    required this.timestamp,
  });

  factory TvLogEntry.fromJson(Map<String, dynamic> json) {
    // Backend returns: id, event, isAuthorized/is_authorized, createdAt, consoleName, durationMinutes, sessionId
    return TvLogEntry(
      id: (json['id'] as String?) ?? '',
      consoleId: (json['consoleId'] as String?) ?? '',
      consoleName: json['consoleName'] as String?,
      action: (json['event'] as String?) ?? 'unknown',
      unauthorized: !_parseBool(json['isAuthorized'] ?? json['is_authorized'], defaultVal: true),
      timestamp: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Parse boolean dari berbagai format: bool, string "true"/"false", int 1/0
  static bool _parseBool(dynamic value, {bool defaultVal = false}) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return defaultVal;
  }

  String get actionLabel {
    switch (action) {
      case 'on': return 'ON';
      case 'off': return 'OFF';
      case 'screensaver': return 'SCREENSAVER';
      default: return action.toUpperCase();
    }
  }
}

/// Info sesi aktif dari response GetTvLogs
class TvActiveSession {
  final String sessionId;
  final DateTime? startTime;
  final int bookedMinutes;
  final double runningMinutes;
  final String status;
  final String? customerName;

  TvActiveSession({
    required this.sessionId,
    this.startTime,
    required this.bookedMinutes,
    required this.runningMinutes,
    required this.status,
    this.customerName,
  });

  factory TvActiveSession.fromJson(Map<String, dynamic> json) {
    return TvActiveSession(
      sessionId: (json['sessionId'] as String?) ?? '',
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString())
          : null,
      bookedMinutes: (json['bookedMinutes'] as num?)?.toInt() ?? 0,
      runningMinutes: (json['runningMinutes'] as num?)?.toDouble() ?? 0,
      status: (json['status'] as String?) ?? '',
      customerName: json['customerName'] as String?,
    );
  }
}

/// Response lengkap dari GetTvLogs
class TvLogResponse {
  final List<TvLogEntry> logs;
  final List<TvLogEntry> unauthorizedLogs;
  final int unauthorizedCount;
  final int totalOnMinutes;
  final TvActiveSession? activeSession;

  TvLogResponse({
    required this.logs,
    required this.unauthorizedLogs,
    required this.unauthorizedCount,
    required this.totalOnMinutes,
    this.activeSession,
  });
}
