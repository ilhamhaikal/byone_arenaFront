class IngredientModel {
  final String id;
  final String name;
  final String unit;
  final double stock;
  final DateTime? nearestExpiry; // kadaluarsa terdekat batch stok usable

  IngredientModel({
    required this.id,
    required this.name,
    this.unit = 'pcs',
    this.stock = 0,
    this.nearestExpiry,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String? ?? 'pcs',
      stock: (json['stock'] as num?)?.toDouble() ?? 0,
      nearestExpiry: json['nearestExpiry'] != null
          ? DateTime.tryParse(json['nearestExpiry'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
      };
}

/// Satu batch penambahan stok (log + kadaluarsa). Dipakai untuk bahan & menu.
class StockBatchModel {
  final String id;
  final double quantity;
  final double remaining;
  final DateTime expiresAt;
  final DateTime addedAt;
  final String? notes;

  StockBatchModel({
    required this.id,
    required this.quantity,
    required this.remaining,
    required this.expiresAt,
    required this.addedAt,
    this.notes,
  });

  bool get isExpired => remaining > 0 && expiresAt.isBefore(DateTime.now());
  bool get isConsumed => remaining <= 0;

  /// Status batch: Terpakai (habis) / Kadaluarsa / Aktif.
  String get statusLabel {
    if (isConsumed) return 'Terpakai';
    if (isExpired) return 'Kadaluarsa';
    return 'Aktif';
  }

  factory StockBatchModel.fromJson(Map<String, dynamic> json) {
    return StockBatchModel(
      id: json['id'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      addedAt: DateTime.parse(json['addedAt'] as String),
      notes: json['notes'] as String?,
    );
  }
}

/// Satu baris resep (menu->bahan atau bahan->bahan).
class RecipeItemModel {
  final String ingredientId;
  final String? ingredientName;
  final double quantity;

  RecipeItemModel({
    required this.ingredientId,
    this.ingredientName,
    required this.quantity,
  });

  factory RecipeItemModel.fromJson(Map<String, dynamic> json) {
    final ing = json['ingredient'];
    final comp = json['componentIngredient'];
    return RecipeItemModel(
      ingredientId:
          (json['ingredientId'] ?? json['componentIngredientId']) as String,
      ingredientName: (ing?['name'] ?? comp?['name']) as String?,
      quantity: (json['quantity'] as num).toDouble(),
    );
  }
}

/// Item kadaluarsa/hampir kadaluarsa.
class ExpiredStockItemModel {
  final String id;
  final String name;
  final String unit;
  final double expiredQty;
  final double usableStock;
  final String nearestExpiry;

  ExpiredStockItemModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.expiredQty,
    required this.usableStock,
    required this.nearestExpiry,
  });

  factory ExpiredStockItemModel.fromJson(Map<String, dynamic> json) =>
      ExpiredStockItemModel(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        expiredQty: (json['expiredQty'] as num?)?.toDouble() ?? 0,
        usableStock: (json['usableStock'] as num?)?.toDouble() ?? 0,
        nearestExpiry: json['nearestExpiry'] as String? ?? '',
      );
}

/// Satu baris log penambahan stok (bahan atau menu).
class StockLogEntryModel {
  final String type; // "ingredient" | "menu"
  final String itemName;
  final String unit;
  final double quantity;
  final double remaining;
  final String expiresAt;
  final String addedAt;
  final String notes;

  StockLogEntryModel({
    required this.type,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.remaining,
    required this.expiresAt,
    required this.addedAt,
    required this.notes,
  });

  bool get isIngredient => type == 'ingredient';

  factory StockLogEntryModel.fromJson(Map<String, dynamic> json) =>
      StockLogEntryModel(
        type: json['type'] as String? ?? 'menu',
        itemName: json['itemName'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        remaining: (json['remaining'] as num?)?.toDouble() ?? 0,
        expiresAt: json['expiresAt'] as String? ?? '',
        addedAt: json['addedAt'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );
}
