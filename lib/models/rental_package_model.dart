class RentalPackageItemModel {
  final String menuItemId;
  final String menuItemName;
  final int quantity;

  RentalPackageItemModel({
    required this.menuItemId,
    this.menuItemName = '',
    required this.quantity,
  });

  factory RentalPackageItemModel.fromJson(Map<String, dynamic> j) =>
      RentalPackageItemModel(
        menuItemId: j['menuItemId'] as String,
        menuItemName: j['menuItemName'] as String? ?? '',
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'menuItemId': menuItemId,
        'quantity': quantity,
      };
}

class RentalPackageModel {
  final String id;
  final String name;
  final String startTime; // "HH:MM"
  final String endTime; // "HH:MM"
  final double price;
  final int durationMinutes;
  final String? description;
  final bool isActive;
  final List<RentalPackageItemModel> items;

  RentalPackageModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.durationMinutes,
    this.description,
    this.isActive = true,
    this.items = const [],
  });

  factory RentalPackageModel.fromJson(Map<String, dynamic> j) =>
      RentalPackageModel(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        startTime: j['startTime'] as String? ?? '',
        endTime: j['endTime'] as String? ?? '',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        description: j['description'] as String?,
        isActive: j['isActive'] as bool? ?? true,
        items: (j['items'] as List<dynamic>?)
                ?.map((e) =>
                    RentalPackageItemModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
