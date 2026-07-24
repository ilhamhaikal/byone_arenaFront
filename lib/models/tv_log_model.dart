/// Konversi string ISO 8601 ke DateTime lokal.
/// Backend menyimpan waktu di zona WIB (UTC+7), jadi cukup .toLocal().
DateTime? _parseToLocal(String? isoString) {
  if (isoString == null || isoString.isEmpty) return null;
  return DateTime.tryParse(isoString)?.toLocal();
}

/// Model for GET /api/v1/consoles/{id}/tv-logs response item.
class TvLogEntry {
  final String id;
  final String consoleId;
  final String? consoleName;
  final String action; // "on", "off", "sleep", "screensaver"
  final bool unauthorized;
  final int? durationMinutes; // null untuk event "on", berisi durasi untuk off/sleep/screensaver
  final String? sessionId;
  final DateTime timestamp;

  TvLogEntry({
    required this.id,
    required this.consoleId,
    this.consoleName,
    required this.action,
    required this.unauthorized,
    this.durationMinutes,
    this.sessionId,
    required this.timestamp,
  });

  factory TvLogEntry.fromJson(Map<String, dynamic> json) {
    // Backend returns: id, event, isAuthorized/is_authorized, durationMinutes, sessionId, createdAt, consoleName
    return TvLogEntry(
      id: (json['id'] as String?) ?? '',
      consoleId: (json['consoleId'] as String?) ?? '',
      consoleName: json['consoleName'] as String?,
      action: (json['event'] as String?) ?? 'unknown',
      unauthorized: !_parseBool(json['isAuthorized'] ?? json['is_authorized'], defaultVal: true),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      sessionId: json['sessionId'] as String?,
      timestamp: _parseToLocal(json['createdAt']?.toString()) ?? DateTime.now(),
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
      case 'sleep': return 'SLEEP';
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
      startTime: _parseToLocal(json['startTime']?.toString()),
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
  final int authorizedMinutes;
  final int unauthorizedMinutes;
  final TvActiveSession? activeSession;

  TvLogResponse({
    required this.logs,
    required this.unauthorizedLogs,
    required this.unauthorizedCount,
    required this.totalOnMinutes,
    required this.authorizedMinutes,
    required this.unauthorizedMinutes,
    this.activeSession,
  });
}
