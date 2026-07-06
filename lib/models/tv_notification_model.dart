class TvNotificationModel {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final String priority;
  final bool isActive;
  final bool loopEnabled;
  final int loopInterval;
  final bool targetAll;
  final String? targetConsoleType;
  final bool activeSessionsOnly;
  final List<String> targetConsoleIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  TvNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.priority,
    required this.isActive,
    required this.loopEnabled,
    required this.loopInterval,
    required this.targetAll,
    this.targetConsoleType,
    this.activeSessionsOnly = false,
    this.targetConsoleIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory TvNotificationModel.fromJson(Map<String, dynamic> json) {
    return TvNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      imageUrl: json['imageUrl'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      isActive: json['isActive'] as bool? ?? true,
      loopEnabled: json['loopEnabled'] as bool? ?? false,
      loopInterval: (json['loopInterval'] as num?)?.toInt() ?? 30,
      targetAll: json['targetAll'] as bool? ?? true,
      targetConsoleType: json['targetConsoleType'] as String?,
      activeSessionsOnly: json['activeSessionsOnly'] as bool? ?? false,
      targetConsoleIds: (json['targetConsoleIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          (json['consoleIds'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'message': message,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
        'priority': priority,
        'loopEnabled': loopEnabled,
        'loopInterval': loopInterval,
        'targetAll': targetAll,
        'activeSessionsOnly': activeSessionsOnly,
        if (targetConsoleIds.isNotEmpty) 'consoleIds': targetConsoleIds,
        if (targetConsoleType != null && targetConsoleType!.isNotEmpty)
          'targetConsoleType': targetConsoleType,
      };

  String get priorityLabel {
    switch (priority) {
      case 'high':
        return 'Tinggi';
      case 'normal':
        return 'Normal';
      default:
        return 'Rendah';
    }
  }
}
