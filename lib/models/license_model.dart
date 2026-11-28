import 'package:intl/intl.dart';

/// Status lisensi server (hasil GET /license/status).
class LicenseStatusModel {
  final String state; // active, expiring, grace, expired, trial, none, invalid
  final String plan;
  final String customer;
  final String licenseId;
  final int maxUnits; // 0 = unlimited
  final int unitsUsed;
  final DateTime? expiresAt;
  final int daysLeft;
  final int graceDays;
  final String instanceId;
  final int trialDaysLeft;
  final bool canStartBusiness;
  final bool canBindUnit;
  final bool expiringSoon;
  final String message;
  final List<String> warnings;

  LicenseStatusModel({
    required this.state,
    this.plan = '',
    this.customer = '',
    this.licenseId = '',
    this.maxUnits = 0,
    this.unitsUsed = 0,
    this.expiresAt,
    this.daysLeft = 0,
    this.graceDays = 0,
    this.instanceId = '',
    this.trialDaysLeft = 0,
    this.canStartBusiness = false,
    this.canBindUnit = false,
    this.expiringSoon = false,
    this.message = '',
    this.warnings = const [],
  });

  factory LicenseStatusModel.fromJson(Map<String, dynamic> j) {
    return LicenseStatusModel(
      state: (j['state'] as String?) ?? 'none',
      plan: (j['plan'] as String?) ?? '',
      customer: (j['customer'] as String?) ?? '',
      licenseId: (j['licenseId'] as String?) ?? '',
      maxUnits: (j['maxUnits'] as num?)?.toInt() ?? 0,
      unitsUsed: (j['unitsUsed'] as num?)?.toInt() ?? 0,
      expiresAt: j['expiresAt'] != null
          ? DateTime.tryParse(j['expiresAt'].toString())
          : null,
      daysLeft: (j['daysLeft'] as num?)?.toInt() ?? 0,
      graceDays: (j['graceDays'] as num?)?.toInt() ?? 0,
      instanceId: (j['instanceId'] as String?) ?? '',
      trialDaysLeft: (j['trialDaysLeft'] as num?)?.toInt() ?? 0,
      canStartBusiness: j['canStartBusiness'] == true,
      canBindUnit: j['canBindUnit'] == true,
      expiringSoon: j['expiringSoon'] == true,
      message: (j['message'] as String?) ?? '',
      warnings: (j['warnings'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  bool get isUnlimited => maxUnits == 0;

  double get unitRatio =>
      isUnlimited || maxUnits <= 0 ? 0 : (unitsUsed / maxUnits).clamp(0.0, 1.0);

  /// ≥ 80% unit terpakai.
  bool get nearUnitLimit =>
      !isUnlimited && maxUnits > 0 && unitsUsed >= (maxUnits * 0.8).ceil();

  bool get isTrial => state == 'trial';
  bool get isExpired => state == 'expired';
  bool get isBlocked => !canStartBusiness;

  /// Perlu ditampilkan di banner dashboard.
  bool get needsAttention =>
      const {
        'expiring',
        'grace',
        'expired',
        'invalid',
        'none',
        'suspended',
        'revoked',
        'inactive',
      }.contains(state) ||
      nearUnitLimit;

  String get stateLabel {
    switch (state) {
      case 'active':
        return 'Aktif';
      case 'expiring':
        return 'Akan Berakhir';
      case 'grace':
        return 'Masa Tenggang';
      case 'expired':
        return 'Berakhir';
      case 'trial':
        return 'Uji Coba';
      case 'invalid':
        return 'Tidak Valid';
      case 'suspended':
        return 'Ditangguhkan';
      case 'revoked':
        return 'Dicabut';
      case 'inactive':
        return 'Aktivasi Tidak Aktif';
      case 'none':
      default:
        return 'Belum Ada Lisensi';
    }
  }

  String get expiresLabel => expiresAt == null
      ? '-'
      : DateFormat('dd MMM yyyy', 'id').format(expiresAt!.toLocal());

  String get unitsLabel => isUnlimited
      ? '$unitsUsed unit (tanpa batas)'
      : '$unitsUsed / $maxUnits unit';

  /// Sisa hari efektif (trial atau lisensi).
  int get effectiveDaysLeft => state == 'trial' ? trialDaysLeft : daysLeft;
}

/// Kode aktivasi QR dari license server vendor.
class OnlineActivationStartModel {
  final String code;
  final String instanceId;
  final DateTime? expiresAt;
  final int pollAfterSeconds;

  OnlineActivationStartModel({
    required this.code,
    this.instanceId = '',
    this.expiresAt,
    this.pollAfterSeconds = 5,
  });

  factory OnlineActivationStartModel.fromJson(Map<String, dynamic> j) {
    return OnlineActivationStartModel(
      code: (j['code'] as String?) ?? '',
      instanceId: (j['instanceId'] as String?) ?? '',
      expiresAt: j['expiresAt'] != null
          ? DateTime.tryParse(j['expiresAt'].toString())
          : null,
      pollAfterSeconds:
          ((j['pollAfterSeconds'] as num?)?.toInt() ?? 5).clamp(2, 30).toInt(),
    );
  }
}

/// Hasil polling aktivasi online.
class OnlineActivationPollModel {
  final String state; // waiting, activated, rejected, expired, error
  final bool valid;
  final String message;
  final LicenseStatusModel? status;
  final List<String> warnings;

  OnlineActivationPollModel({
    required this.state,
    this.valid = false,
    this.message = '',
    this.status,
    this.warnings = const [],
  });

  factory OnlineActivationPollModel.fromJson(Map<String, dynamic> j) {
    return OnlineActivationPollModel(
      state: (j['state'] as String?) ?? 'waiting',
      valid: j['valid'] == true,
      message: (j['message'] as String?) ?? '',
      status: j['status'] is Map<String, dynamic>
          ? LicenseStatusModel.fromJson(j['status'] as Map<String, dynamic>)
          : null,
      warnings: (j['warnings'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

/// Satu baris riwayat lisensi (GET /license/history).
class LicenseHistoryModel {
  final String id;
  final String licenseId;
  final String customer;
  final String plan;
  final int maxUnits;
  final DateTime? expiresAt;
  final DateTime? activatedAt;
  final bool isActive;

  LicenseHistoryModel({
    required this.id,
    required this.licenseId,
    required this.customer,
    required this.plan,
    required this.maxUnits,
    this.expiresAt,
    this.activatedAt,
    this.isActive = false,
  });

  factory LicenseHistoryModel.fromJson(Map<String, dynamic> j) {
    return LicenseHistoryModel(
      id: (j['id'] as String?) ?? '',
      licenseId: (j['licenseId'] as String?) ?? '',
      customer: (j['customer'] as String?) ?? '',
      plan: (j['plan'] as String?) ?? '',
      maxUnits: (j['maxUnits'] as num?)?.toInt() ?? 0,
      expiresAt: j['expiresAt'] != null
          ? DateTime.tryParse(j['expiresAt'].toString())
          : null,
      activatedAt: j['activatedAt'] != null
          ? DateTime.tryParse(j['activatedAt'].toString())
          : null,
      isActive: j['isActive'] == true,
    );
  }

  String get unitsLabel => maxUnits == 0 ? 'unlimited' : '$maxUnits unit';
  String get expiresLabel => expiresAt == null
      ? '-'
      : DateFormat('dd MMM yyyy', 'id').format(expiresAt!.toLocal());
  String get activatedLabel => activatedAt == null
      ? '-'
      : DateFormat('dd MMM yyyy HH:mm', 'id').format(activatedAt!.toLocal());
}

/// Hasil POST /license/activate.
class LicenseActivateResult {
  final bool activated;
  final bool requiresConfirmation;
  final List<String> warnings;
  final LicenseStatusModel? status;

  LicenseActivateResult({
    required this.activated,
    required this.requiresConfirmation,
    this.warnings = const [],
    this.status,
  });

  factory LicenseActivateResult.fromJson(Map<String, dynamic> j) {
    return LicenseActivateResult(
      activated: j['activated'] == true,
      requiresConfirmation: j['requiresConfirmation'] == true,
      warnings: (j['warnings'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      status: j['status'] is Map<String, dynamic>
          ? LicenseStatusModel.fromJson(j['status'] as Map<String, dynamic>)
          : null,
    );
  }
}
