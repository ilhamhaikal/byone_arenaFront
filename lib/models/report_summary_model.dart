class ReportPeriod {
  final String startDate;
  final String endDate;
  final int totalDays;
  ReportPeriod(
      {required this.startDate,
      required this.endDate,
      required this.totalDays});
  factory ReportPeriod.fromJson(Map<String, dynamic> j) => ReportPeriod(
        startDate: j['startDate'] as String? ?? '',
        endDate: j['endDate'] as String? ?? '',
        totalDays: (j['totalDays'] as num?)?.toInt() ?? 0,
      );
}

class ReportRevenue {
  final double totalRevenue, totalBaseAmount, totalDiscount, totalAutoDiscount,
      voucherDiscount, totalCashReceived, totalChange;
  final double dailyRentalRevenue;
  final int dailyRentalCount;
  final double membershipRevenue;
  final int membershipCount;
  final double foodSalesRevenue;
  final double foodSalesBaseAmount;
  final double foodSalesDiscount;
  final int foodSalesCount;
  ReportRevenue(
      {required this.totalRevenue,
      required this.totalBaseAmount,
      required this.totalDiscount,
      required this.totalAutoDiscount,
      required this.voucherDiscount,
      required this.totalCashReceived,
      required this.totalChange,
      this.dailyRentalRevenue = 0,
      this.dailyRentalCount = 0,
      this.membershipRevenue = 0,
      this.membershipCount = 0,
      this.foodSalesRevenue = 0,
      this.foodSalesBaseAmount = 0,
      this.foodSalesDiscount = 0,
      this.foodSalesCount = 0});
  factory ReportRevenue.fromJson(Map<String, dynamic> j) => ReportRevenue(
        totalRevenue: (j['totalRevenue'] as num?)?.toDouble() ?? 0,
        totalBaseAmount: (j['totalBaseAmount'] as num?)?.toDouble() ?? 0,
        totalDiscount: (j['totalDiscount'] as num?)?.toDouble() ?? 0,
        totalAutoDiscount: (j['totalAutoDiscount'] as num?)?.toDouble() ?? 0,
        voucherDiscount: (j['voucherDiscount'] as num?)?.toDouble() ?? 0,
        totalCashReceived: (j['totalCashReceived'] as num?)?.toDouble() ?? 0,
        totalChange: (j['totalChange'] as num?)?.toDouble() ?? 0,
        dailyRentalRevenue: (j['dailyRentalRevenue'] as num?)?.toDouble() ?? 0,
        dailyRentalCount: (j['dailyRentalCount'] as num?)?.toInt() ?? 0,
        membershipRevenue: (j['membershipRevenue'] as num?)?.toDouble() ?? 0,
        membershipCount: (j['membershipCount'] as num?)?.toInt() ?? 0,
        foodSalesRevenue: (j['foodSalesRevenue'] as num?)?.toDouble() ?? 0,
        foodSalesBaseAmount: (j['foodSalesBaseAmount'] as num?)?.toDouble() ?? 0,
        foodSalesDiscount: (j['foodSalesDiscount'] as num?)?.toDouble() ?? 0,
        foodSalesCount: (j['foodSalesCount'] as num?)?.toInt() ?? 0,
      );
}

class ReportFoodItem {
  final String itemName;
  final String category;
  final int quantitySold;
  final double revenue;
  ReportFoodItem({
    required this.itemName,
    required this.category,
    required this.quantitySold,
    required this.revenue,
  });
  factory ReportFoodItem.fromJson(Map<String, dynamic> j) => ReportFoodItem(
        itemName: j['itemName'] as String? ?? '',
        category: j['category'] as String? ?? '',
        quantitySold: (j['quantitySold'] as num?)?.toInt() ?? 0,
        revenue: (j['revenue'] as num?)?.toDouble() ?? 0,
      );
}

class ReportFoodSales {
  final double totalRevenue;
  final double baseAmount;
  final double discountAmount;
  final int totalOrders;
  final double averageOrderValue;
  final List<ReportFoodItem> topItems;
  ReportFoodSales({
    required this.totalRevenue,
    this.baseAmount = 0,
    this.discountAmount = 0,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.topItems,
  });
  factory ReportFoodSales.fromJson(Map<String, dynamic> j) => ReportFoodSales(
        totalRevenue: (j['totalRevenue'] as num?)?.toDouble() ?? 0,
        baseAmount: (j['baseAmount'] as num?)?.toDouble() ?? 0,
        discountAmount: (j['discountAmount'] as num?)?.toDouble() ?? 0,
        totalOrders: (j['totalOrders'] as num?)?.toInt() ?? 0,
        averageOrderValue: (j['averageOrderValue'] as num?)?.toDouble() ?? 0,
        topItems: (j['topItems'] as List<dynamic>?)
                ?.map((e) =>
                    ReportFoodItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class ReportSessions {
  final int totalSessions, totalPlayMinutes, averageMinutes;
  final double totalPlayHours;
  ReportSessions(
      {required this.totalSessions,
      required this.totalPlayMinutes,
      required this.averageMinutes,
      required this.totalPlayHours});
  factory ReportSessions.fromJson(Map<String, dynamic> j) => ReportSessions(
        totalSessions: (j['totalSessions'] as num?)?.toInt() ?? 0,
        totalPlayMinutes: (j['totalPlayMinutes'] as num?)?.toInt() ?? 0,
        averageMinutes: (j['averageMinutes'] as num?)?.toInt() ?? 0,
        totalPlayHours: (j['totalPlayHours'] as num?)?.toDouble() ?? 0,
      );
}

class ReportTransactions {
  final int totalTransactions, voucherTransactions;
  final double averagePerDay;
  ReportTransactions(
      {required this.totalTransactions,
      required this.voucherTransactions,
      required this.averagePerDay});
  factory ReportTransactions.fromJson(Map<String, dynamic> j) =>
      ReportTransactions(
        totalTransactions: (j['totalTransactions'] as num?)?.toInt() ?? 0,
        voucherTransactions:
            (j['voucherTransactions'] as num?)?.toInt() ?? 0,
        averagePerDay: (j['averagePerDay'] as num?)?.toDouble() ?? 0,
      );
}

class ReportConsoleUsage {
  final String consoleName, consoleType;
  final int totalSessions, totalMinutes;
  ReportConsoleUsage(
      {required this.consoleName,
      required this.consoleType,
      required this.totalSessions,
      required this.totalMinutes});
  factory ReportConsoleUsage.fromJson(Map<String, dynamic> j) =>
      ReportConsoleUsage(
        consoleName: j['consoleName'] as String? ?? '',
        consoleType: j['consoleType'] as String? ?? '',
        totalSessions: (j['totalSessions'] as num?)?.toInt() ?? 0,
        totalMinutes: (j['totalMinutes'] as num?)?.toInt() ?? 0,
      );
}

class ReportDailyItem {
  final String date;
  final int sessions, transactions, playMinutes;
  final double revenue;
  final double rentalRevenue;
  final int dailyRentals;
  final double membershipRevenue;
  final int memberships;
  final double foodRevenue;
  final int foodOrders;
  ReportDailyItem(
      {required this.date,
      required this.sessions,
      required this.transactions,
      required this.playMinutes,
      required this.revenue,
      this.rentalRevenue = 0,
      this.dailyRentals = 0,
      this.membershipRevenue = 0,
      this.memberships = 0,
      this.foodRevenue = 0,
      this.foodOrders = 0});
  factory ReportDailyItem.fromJson(Map<String, dynamic> j) => ReportDailyItem(
        date: j['date'] as String? ?? '',
        sessions: (j['sessions'] as num?)?.toInt() ?? 0,
        transactions: (j['transactions'] as num?)?.toInt() ?? 0,
        playMinutes: (j['playMinutes'] as num?)?.toInt() ?? 0,
        revenue: (j['revenue'] as num?)?.toDouble() ?? 0,
        rentalRevenue: (j['rentalRevenue'] as num?)?.toDouble() ?? 0,
        dailyRentals: (j['dailyRentals'] as num?)?.toInt() ?? 0,
        membershipRevenue: (j['membershipRevenue'] as num?)?.toDouble() ?? 0,
        memberships: (j['memberships'] as num?)?.toInt() ?? 0,
        foodRevenue: (j['foodRevenue'] as num?)?.toDouble() ?? 0,
        foodOrders: (j['foodOrders'] as num?)?.toInt() ?? 0,
      );
}

class ReportVoucherUsage {
  final String voucherCode, voucherName, discountType;
  final int usageCount;
  final double totalDiscount;
  ReportVoucherUsage(
      {required this.voucherCode,
      required this.voucherName,
      required this.discountType,
      required this.usageCount,
      required this.totalDiscount});
  factory ReportVoucherUsage.fromJson(Map<String, dynamic> j) =>
      ReportVoucherUsage(
        voucherCode: j['voucherCode'] as String? ?? '',
        voucherName: j['voucherName'] as String? ?? '',
        discountType: j['discountType'] as String? ?? '',
        usageCount: (j['usageCount'] as num?)?.toInt() ?? 0,
        totalDiscount: (j['totalDiscount'] as num?)?.toDouble() ?? 0,
      );
}

class ReportSummaryModel {
  final String generatedAt;
  final ReportPeriod period;
  final ReportRevenue revenue;
  final ReportSessions sessions;
  final ReportTransactions transactions;
  final List<ReportDailyItem> dailyBreakdown;
  final List<ReportConsoleUsage> consoles;
  final List<ReportVoucherUsage> vouchers;
  final ReportFoodSales? foodSales;
  final List<dynamic> activeDiscountRules;

  ReportSummaryModel({
    required this.generatedAt,
    required this.period,
    required this.revenue,
    required this.sessions,
    required this.transactions,
    required this.dailyBreakdown,
    required this.consoles,
    required this.vouchers,
    this.foodSales,
    required this.activeDiscountRules,
  });

  factory ReportSummaryModel.fromJson(Map<String, dynamic> j) {
    return ReportSummaryModel(
      generatedAt: j['generatedAt'] as String? ?? '',
      period: ReportPeriod.fromJson(
          (j['period'] as Map<String, dynamic>?) ?? {}),
      revenue: ReportRevenue.fromJson(
          (j['revenue'] as Map<String, dynamic>?) ?? {}),
      sessions: ReportSessions.fromJson(
          (j['sessions'] as Map<String, dynamic>?) ?? {}),
      transactions: ReportTransactions.fromJson(
          (j['transactions'] as Map<String, dynamic>?) ?? {}),
      dailyBreakdown: (j['dailyBreakdown'] as List<dynamic>?)
              ?.map((e) =>
                  ReportDailyItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      consoles: (j['consoles'] as List<dynamic>?)
              ?.map((e) =>
                  ReportConsoleUsage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      vouchers: (j['vouchers'] as List<dynamic>?)
              ?.map((e) =>
                  ReportVoucherUsage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      foodSales: j['foodSales'] != null
          ? ReportFoodSales.fromJson(j['foodSales'] as Map<String, dynamic>)
          : null,
      activeDiscountRules: (j['activeDiscountRules'] as List<dynamic>?) ?? [],
    );
  }
}
