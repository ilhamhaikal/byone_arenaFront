class CapitalEntryModel {
  final String id;
  final double amount;
  final DateTime entryDate;
  final String? notes;
  final DateTime createdAt;

  CapitalEntryModel({
    required this.id,
    required this.amount,
    required this.entryDate,
    this.notes,
    required this.createdAt,
  });

  factory CapitalEntryModel.fromJson(Map<String, dynamic> j) => CapitalEntryModel(
        id: j['id'] as String,
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        entryDate:
            DateTime.tryParse(j['entryDate'] as String? ?? '') ?? DateTime.now(),
        notes: j['notes'] as String?,
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class MonthlyCapitalModel {
  final String month;
  final double initialCapital, totalRevenue, foodRevenue, netProfit;
  final double percentChange;
  final String reason;

  MonthlyCapitalModel({
    required this.month,
    required this.initialCapital,
    required this.totalRevenue,
    required this.foodRevenue,
    required this.netProfit,
    required this.percentChange,
    required this.reason,
  });

  factory MonthlyCapitalModel.fromJson(Map<String, dynamic> j) =>
      MonthlyCapitalModel(
        month: j['month'] as String? ?? '',
        initialCapital: (j['initialCapital'] as num?)?.toDouble() ?? 0,
        totalRevenue: (j['totalRevenue'] as num?)?.toDouble() ?? 0,
        foodRevenue: (j['foodRevenue'] as num?)?.toDouble() ?? 0,
        netProfit: (j['netProfit'] as num?)?.toDouble() ?? 0,
        percentChange: (j['percentChange'] as num?)?.toDouble() ?? 0,
        reason: j['reason'] as String? ?? '',
      );
}
