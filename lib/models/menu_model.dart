class MenuModel {
  final String id;
  final String name;
  final String? description;
  final String category; // food, drink, snack, other
  final double price;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'price': price,
        if (description != null) 'description': description,
      };

  static const List<String> categories = ['food', 'drink', 'snack', 'other'];

  String get categoryLabel {
    switch (category) {
      case 'food':
        return 'Makanan';
      case 'drink':
        return 'Minuman';
      case 'snack':
        return 'Snack';
      default:
        return 'Lainnya';
    }
  }
}
