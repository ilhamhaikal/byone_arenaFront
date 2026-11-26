import 'package:flutter/foundation.dart';

import '../models/promo_bonus_model.dart';
import '../models/session_model.dart';
import '../services/promo_service.dart';

/// Menyimpan aturan bonus waktu yang berlaku hari ini, daftar aturan untuk
/// admin, dan laporan menit gratis.
class PromoProvider extends ChangeNotifier {
  final PromoService _service = PromoService();

  PromoBonusRuleModel? _active;
  PromoBonusRuleModel? _general;
  PromoBonusRuleModel? _member;
  List<PromoBonusRuleModel> _rules = [];
  PromoReportModel? _report;
  String? _error;
  bool _loading = false;
  bool _activeFailed = false;

  PromoBonusRuleModel? get active => _active;
  PromoBonusRuleModel? get general => _general;
  PromoBonusRuleModel? get member => _member;
  List<PromoBonusRuleModel> get rules => _rules;
  PromoReportModel? get report => _report;
  String? get error => _error;
  bool get isLoading => _loading;

  /// Aturan yang sesuai: member valid memakai bonus member, selain itu umum.
  PromoBonusRuleModel? activeFor({required bool isMember}) =>
      isMember ? _member : _general;

  /// True bila permintaan aturan aktif terakhir gagal (jaringan/auth).
  bool get activeFailed => _activeFailed;

  Future<void> loadActive() async {
    var failed = false;
    try {
      _general = await _service.active(audience: 'general');
    } catch (_) {
      failed = true;
    }
    try {
      _member = await _service.active(audience: 'member');
    } catch (_) {
      failed = true;
    }
    // _active tetap menunjuk aturan umum untuk kompatibilitas pemakaian lama.
    _active = _general;
    _activeFailed = failed;
    notifyListeners();
  }

  Future<void> loadRules() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _rules = await _service.list();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadReport(String startDate, String endDate) async {
    try {
      _report = await _service.report(startDate, endDate);
      notifyListeners();
    } catch (_) {
      // laporan bonus bersifat tambahan; kegagalan tidak memblokir laporan utama
    }
  }

  /// Mengembalikan pesan error (null = sukses) dan sesi terbaru.
  Future<(String?, SessionModel?)> applyToSession(String sessionId) async {
    try {
      final s = await _service.applyToSession(sessionId);
      await loadActive();
      return (null, s);
    } catch (e) {
      return (e.toString(), null);
    }
  }

  Future<String?> saveRule(PromoBonusRuleModel rule) async {
    try {
      if (rule.id.isEmpty) {
        await _service.create(rule);
      } else {
        await _service.update(rule);
      }
      await loadRules();
      await loadActive();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteRule(String id) async {
    try {
      await _service.delete(id);
      await loadRules();
      await loadActive();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}