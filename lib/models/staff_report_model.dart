class StaffReportPeriod {
  final String startDate, endDate;
  final int totalDays;
  const StaffReportPeriod({
    required this.startDate,
    required this.endDate,
    required this.totalDays,
  });

  factory StaffReportPeriod.fromJson(Map<String, dynamic> j) => StaffReportPeriod(
        startDate: j['startDate'] as String? ?? '',
        endDate: j['endDate'] as String? ?? '',
        totalDays: (j['totalDays'] as num?)?.toInt() ?? 0,
      );
}

class StaffRevenue {
  final double rental, food, dailyRental, membership, game, total;
  final int rentalTrx, foodTrx, dailyRentalTrx, membershipTrx, gameTrx, totalTrx;

  const StaffRevenue({
    this.rental = 0,
    this.food = 0,
    this.dailyRental = 0,
    this.membership = 0,
    this.game = 0,
    this.total = 0,
    this.rentalTrx = 0,
    this.foodTrx = 0,
    this.dailyRentalTrx = 0,
    this.membershipTrx = 0,
    this.gameTrx = 0,
    this.totalTrx = 0,
  });

  factory StaffRevenue.fromJson(Map<String, dynamic> j) => StaffRevenue(
        rental: (j['rental'] as num?)?.toDouble() ?? 0,
        food: (j['food'] as num?)?.toDouble() ?? 0,
        dailyRental: (j['dailyRental'] as num?)?.toDouble() ?? 0,
        membership: (j['membership'] as num?)?.toDouble() ?? 0,
        game: (j['game'] as num?)?.toDouble() ?? 0,
        total: (j['total'] as num?)?.toDouble() ?? 0,
        rentalTrx: (j['rentalTrx'] as num?)?.toInt() ?? 0,
        foodTrx: (j['foodTrx'] as num?)?.toInt() ?? 0,
        dailyRentalTrx: (j['dailyRentalTrx'] as num?)?.toInt() ?? 0,
        membershipTrx: (j['membershipTrx'] as num?)?.toInt() ?? 0,
        gameTrx: (j['gameTrx'] as num?)?.toInt() ?? 0,
        totalTrx: (j['totalTrx'] as num?)?.toInt() ?? 0,
      );
}

class StaffLoginSession {
  final DateTime loginAt;
  final DateTime? logoutAt;
  final int durationMinutes;
  final bool stillLoggedIn;

  const StaffLoginSession({
    required this.loginAt,
    this.logoutAt,
    required this.durationMinutes,
    required this.stillLoggedIn,
  });

  factory StaffLoginSession.fromJson(Map<String, dynamic> j) =>
      StaffLoginSession(
        loginAt: DateTime.tryParse(j['loginAt']?.toString() ?? '') ??
            DateTime.now(),
        logoutAt: j['logoutAt'] != null
            ? DateTime.tryParse(j['logoutAt'].toString())
            : null,
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        stillLoggedIn: j['stillLoggedIn'] as bool? ?? false,
      );
}

class StaffReportDay {
  final String date;
  final List<StaffLoginSession> sessions;
  final StaffRevenue revenue;

  const StaffReportDay({
    required this.date,
    required this.sessions,
    required this.revenue,
  });

  factory StaffReportDay.fromJson(Map<String, dynamic> j) => StaffReportDay(
        date: j['date'] as String? ?? '',
        sessions: (j['sessions'] as List<dynamic>?)
                ?.map((e) =>
                    StaffLoginSession.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        revenue: StaffRevenue.fromJson(
            (j['revenue'] as Map<String, dynamic>?) ?? const {}),
      );
}

class StaffReportUser {
  final String? userId;
  final String username;
  final String fullName;
  final String role;
  final List<StaffReportDay> days;
  final StaffRevenue totals;

  const StaffReportUser({
    this.userId,
    required this.username,
    required this.fullName,
    required this.role,
    required this.days,
    required this.totals,
  });

  factory StaffReportUser.fromJson(Map<String, dynamic> j) => StaffReportUser(
        userId: j['userId']?.toString(),
        username: j['username'] as String? ?? '-',
        fullName: j['fullName'] as String? ?? '-',
        role: j['role'] as String? ?? '-',
        days: (j['days'] as List<dynamic>?)
                ?.map((e) => StaffReportDay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        totals: StaffRevenue.fromJson(
            (j['totals'] as Map<String, dynamic>?) ?? const {}),
      );
}

class StaffReportModel {
  final StaffReportPeriod period;
  final List<StaffReportUser> staff;
  final StaffReportUser? unknown;

  const StaffReportModel({
    required this.period,
    required this.staff,
    this.unknown,
  });

  factory StaffReportModel.fromJson(Map<String, dynamic> j) =>
      StaffReportModel(
        period: StaffReportPeriod.fromJson(
            (j['period'] as Map<String, dynamic>?) ?? const {}),
        staff: (j['staff'] as List<dynamic>?)
                ?.map((e) => StaffReportUser.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        unknown: j['unknown'] != null
            ? StaffReportUser.fromJson(j['unknown'] as Map<String, dynamic>)
            : null,
      );
}
