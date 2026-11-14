import '../config/api_config.dart';
import '../models/promo_bonus_model.dart';
import '../models/session_model.dart';
import 'api_service.dart';

class PromoService {
  final ApiService _api = ApiService();

  Future<PromoBonusRuleModel?> active() async {
    final r = await _api.get(ApiConfig.promoActive);
    final data = r['data'];
    if (data == null) return null;
    return PromoBonusRuleModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PromoBonusRuleModel>> list() async {
    final r = await _api.get(ApiConfig.promoBonuses);
    final data = (r['data'] as List?) ?? [];
    return data
        .map((e) => PromoBonusRuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PromoBonusRuleModel> create(PromoBonusRuleModel rule) async {
    final r = await _api.post(ApiConfig.promoBonuses, rule.toBody());
    return PromoBonusRuleModel.fromJson(r['data'] as Map<String, dynamic>);
  }

  Future<PromoBonusRuleModel> update(PromoBonusRuleModel rule) async {
    final r = await _api.put('${ApiConfig.promoBonuses}/${rule.id}', rule.toBody());
    return PromoBonusRuleModel.fromJson(r['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConfig.promoBonuses}/$id');
  }

  /// Terapkan bonus ke sesi aktif. Mengembalikan sesi terbaru.
  Future<SessionModel> applyToSession(String sessionId) async {
    final r = await _api.post('${ApiConfig.sessions}/$sessionId/promo-bonus', {});
    return SessionModel.fromJson(r['data'] as Map<String, dynamic>);
  }

  Future<PromoReportModel> report(String startDate, String endDate) async {
    final r = await _api.get(ApiConfig.promoReport, {
      'startDate': startDate,
      'endDate': endDate,
    });
    return PromoReportModel.fromJson(r['data'] as Map<String, dynamic>);
  }
}