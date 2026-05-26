class ConsoleModel {
  final String id;
  final String name;
  final String consoleType; // PS3, PS4, PS5, AndroidTV
  final double pricePerHour;
  final String status; // available, in_use, maintenance
  final String? description;
  final String? ipAddress; // wajib untuk AndroidTV
  final DateTime createdAt;
  final DateTime updatedAt;

  ConsoleModel({
    required this.id,
    required this.name,
    required this.consoleType,
    required this.pricePerHour,
    required this.status,
    this.description,
    this.ipAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConsoleModel.fromJson(Map<String, dynamic> json) {
    return ConsoleModel(
      id: json['id'] as String,
      name: json['name'] as String,
      consoleType: json['consoleType'] as String,
      pricePerHour: (json['pricePerHour'] as num).toDouble(),
      status: json['status'] as String,
      description: json['description'] as String?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'consoleType': consoleType,
        'pricePerHour': pricePerHour,
        'status': status,
        if (description != null) 'description': description,
        if (ipAddress != null) 'ipAddress': ipAddress,
      };

  bool get isAvailable => status == 'available';
  bool get isInUse => status == 'in_use';
  bool get isMaintenance => status == 'maintenance';
  bool get isAndroidTV => consoleType == 'AndroidTV';
}
