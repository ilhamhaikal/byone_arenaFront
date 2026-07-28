/// Model for GET /api/v1/activities/recent response item.
class ActivityItem {
  final String type;
  final String title;
  final String detail;
  final String action;
  final String? amount;
  final DateTime timestamp;

  ActivityItem({
    required this.type,
    required this.title,
    required this.detail,
    required this.action,
    this.amount,
    required this.timestamp,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      detail: (json['detail'] as String?) ?? '',
      action: (json['action'] as String?) ?? '',
      amount: json['amount'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

