class VoucherUsageDetail {
  final String voucherCode;
  final String voucherName;
  final int usageCount;
  final double totalDiscount;

  VoucherUsageDetail({
    required this.voucherCode,
    required this.voucherName,
    required this.usageCount,
    required this.totalDiscount,
  });

  factory VoucherUsageDetail.fromJson(Map<String, dynamic> json) {
    return VoucherUsageDetail(
      voucherCode: json['voucherCode'] as String,
      voucherName: json['voucherName'] as String,
      usageCount: (json['usageCount'] as num).toInt(),
      totalDiscount: (json['totalDiscount'] as num).toDouble(),
    );
  }
}

class DashboardSummaryModel {
  final String date;
  final String generatedAt;
  final int totalConsoles;
  final int availableConsoles;
  final int activeSessions;
  final int totalTransactions;
  final double totalRevenue;
  final double totalBaseAmount;
  final double totalDiscount;
  final double totalAutoDiscount;
  final double totalCashReceived;
  final double totalChange;
  final int voucherUsageCount;
  final int dailyRentalCount;
  final double dailyRentalRevenue;
  final int membershipCount;
  final double membershipRevenue;
  final double foodSalesRevenue;
  final int foodOrderCount;
  final int pendingFoodOrders;
  final List<VoucherUsageDetail> voucherDetails;

  DashboardSummaryModel({
    required this.date,
    required this.generatedAt,
    required this.totalConsoles,
    required this.availableConsoles,
    required this.activeSessions,
    required this.totalTransactions,
    required this.totalRevenue,
    required this.totalBaseAmount,
    required this.totalDiscount,
    required this.totalAutoDiscount,
    required this.totalCashReceived,
    required this.totalChange,
    required this.voucherUsageCount,
    this.dailyRentalCount = 0,
    this.dailyRentalRevenue = 0,
    this.membershipCount = 0,
    this.membershipRevenue = 0,
    this.foodSalesRevenue = 0,
    this.foodOrderCount = 0,
    this.pendingFoodOrders = 0,
    required this.voucherDetails,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      date: json['date'] as String? ?? '',
      generatedAt: json['generatedAt'] as String? ?? '',
      totalConsoles: (json['totalConsoles'] as num?)?.toInt() ?? 0,
      availableConsoles: (json['availableConsoles'] as num?)?.toInt() ?? 0,
      activeSessions: (json['activeSessions'] as num?)?.toInt() ?? 0,
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      totalBaseAmount: (json['totalBaseAmount'] as num?)?.toDouble() ?? 0,
      totalDiscount: (json['totalDiscount'] as num?)?.toDouble() ?? 0,
      totalAutoDiscount: (json['totalAutoDiscount'] as num?)?.toDouble() ?? 0,
      totalCashReceived: (json['totalCashReceived'] as num?)?.toDouble() ?? 0,
      totalChange: (json['totalChange'] as num?)?.toDouble() ?? 0,
      voucherUsageCount: (json['voucherUsageCount'] as num?)?.toInt() ?? 0,
      dailyRentalCount: (json['dailyRentalCount'] as num?)?.toInt() ?? 0,
      dailyRentalRevenue: (json['dailyRentalRevenue'] as num?)?.toDouble() ?? 0,
      membershipCount: (json['membershipCount'] as num?)?.toInt() ?? 0,
      membershipRevenue: (json['membershipRevenue'] as num?)?.toDouble() ?? 0,
      foodSalesRevenue: (json['foodSalesRevenue'] as num?)?.toDouble() ?? 0,
      foodOrderCount: (json['foodOrderCount'] as num?)?.toInt() ?? 0,
      pendingFoodOrders: (json['pendingFoodOrders'] as num?)?.toInt() ?? 0,
      voucherDetails: (json['voucherDetails'] as List?)
              ?.map((e) =>
                  VoucherUsageDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
