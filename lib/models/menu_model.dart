/// Status kelayakan menu berdasarkan tanggal kadaluarsa.
enum MenuExpiryStatus { none, fresh, nearExpiry, expired }

class MenuModel {
  final String id;
  final String name;
  final String? description;
  final String category; // food, drink, snack, other
  final double price;
  final double stock;
  final double hpp; // harga pokok per pcs
  final bool isAvailable;
  final DateTime? expiresAt; // tanggal kadaluarsa (null = tidak diatur)
  final String? limitingIngredient; // bahan pembatas stok (nilai paling kecil)
  final double limitingIngredientStock; // stok usable bahan pembatas
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    this.stock = 0,
    this.hpp = 0,
    required this.isAvailable,
    this.expiresAt,
    this.limitingIngredient,
    this.limitingIngredientStock = 0,
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
      stock: (json['stock'] as num?)?.toDouble() ?? 0,
      hpp: (json['hpp'] as num?)?.toDouble() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      limitingIngredient: json['limitingIngredient'] as String?,
      limitingIngredientStock:
          (json['limitingIngredientStock'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'hpp': hpp,
        if (description != null) 'description': description,
      };

  static const List<String> categories = ['food', 'drink', 'snack', 'other'];

  /// Batas (hari) sebuah menu dianggap "mau kadaluarsa".
  static const int nearExpiryDays = 3;

  /// Status kelayakan berdasarkan [expiresAt].
  MenuExpiryStatus get expiryStatus {
    final exp = expiresAt;
    if (exp == null) return MenuExpiryStatus.none;
    final now = DateTime.now();
    if (exp.isBefore(now)) return MenuExpiryStatus.expired;
    if (exp.isBefore(now.add(const Duration(days: nearExpiryDays)))) {
      return MenuExpiryStatus.nearExpiry;
    }
    return MenuExpiryStatus.fresh;
  }

  /// Label status kelayakan (untuk tampilan).
  String get expiryLabel {
    switch (expiryStatus) {
      case MenuExpiryStatus.expired:
        return 'Kadaluarsa';
      case MenuExpiryStatus.nearExpiry:
        return 'Mau kadaluarsa';
      case MenuExpiryStatus.fresh:
        return 'Layak';
      case MenuExpiryStatus.none:
        return 'Tanpa tanggal';
    }
  }

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
