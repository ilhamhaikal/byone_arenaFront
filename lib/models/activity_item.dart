/// Model for GET /api/v1/activities/recent response item.
class ActivityItem {
  final String type;
  final String title;
  final String detail;
  final String action;
  final DateTime timestamp;

  ActivityItem({
    required this.type,
    required this.title,
    required this.detail,
    required this.action,
    required this.timestamp,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      detail: (json['detail'] as String?) ?? '',
      action: (json['action'] as String?) ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

