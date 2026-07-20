import 'pricing_tier_model.dart';

class ConsoleModel {
  final String id;
  final String name;
  final String consoleType; // PS3, PS4, PS5, AndroidTV
  final double pricePerHour;
  final String status; // available, in_use, maintenance
  final String? description;
  final String? ipAddress;
  final String? macAddress;
  final int? adbPort;
  final String screenStatus; // on, off, screensaver
  final List<PricingTierEntry> pricingTiers; // tarif bertingkat
  final double dailyPrice; // harga sewa harian
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
    this.macAddress,
    this.adbPort,
    this.screenStatus = 'off',
    this.pricingTiers = const [],
    this.dailyPrice = 0,
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
      macAddress: json['macAddress'] as String?,
      adbPort: (json['adbPort'] as num?)?.toInt(),
      screenStatus: json['screenStatus'] as String? ?? 'off',
      pricingTiers: (json['pricingTiers'] as List<dynamic>?)
              ?.map((e) =>
                  PricingTierEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dailyPrice: (json['dailyPrice'] as num?)?.toDouble() ?? 0,
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
        if (macAddress != null) 'macAddress': macAddress,
        if (adbPort != null) 'adbPort': adbPort,
        'screenStatus': screenStatus,
      };

  bool get isAvailable => status == 'available';
  bool get isInUse => status == 'in_use';
  bool get isMaintenance => status == 'maintenance';
  bool get isAndroidTV => consoleType == 'AndroidTV';
  bool get isScreenOn => screenStatus == 'on';
  bool get isScreenOff => screenStatus == 'off';
  bool get isScreenSaver => screenStatus == 'screensaver';
}
