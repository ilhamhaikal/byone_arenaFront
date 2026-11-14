import 'package:flutter/foundation.dart';

import '../models/promo_bonus_model.dart';
import '../models/session_model.dart';
import '../services/promo_service.dart';

/// Menyimpan aturan bonus waktu yang berlaku hari ini, daftar aturan untuk
/// admin, dan laporan menit gratis.
class PromoProvider extends ChangeNotifier {
  final PromoService _service = PromoService();

  PromoBonusRuleModel? _active;
  List<PromoBonusRuleModel> _rules = [];
  PromoReportModel? _report;
  String? _error;
  bool _loading = false;

  PromoBonusRuleModel? get active => _active;
  List<PromoBonusRuleModel> get rules => _rules;
  PromoReportModel? get report => _report;
  String? get error => _error;
  bool get isLoading => _loading;

  Future<void> loadActive() async {
    try {
      _active = await _service.active();
    } catch (_) {
      // Gangguan jaringan sesaat tidak boleh menghapus aturan yang sudah ada.
    }
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