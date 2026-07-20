import 'dart:developer';
import '../config/api_config.dart';
import '../models/daily_price_settings_model.dart';
import 'api_service.dart';

class DailyPriceSettingsService {
  final ApiService _api = ApiService();

  Future<DailyPriceSettingsModel> getPrice() async {
    final response = await _api.get(ApiConfig.dailyPriceSettings);
    log('[DailyPriceSettings] GET: $response');
    return _parseResponse(response);
  }

  Future<DailyPriceSettingsModel> updatePrice(double price) async {
    final response = await _api.put(ApiConfig.dailyPriceSettings, {
      'dailyPrice': price,
    });
    log('[DailyPriceSettings] PUT: $response');
    return _parseResponse(response);
  }

  DailyPriceSettingsModel _parseResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic> && data.containsKey('dailyPrice')) {
      return DailyPriceSettingsModel.fromJson(data);
    }
    if (response.containsKey('dailyPrice')) {
      return DailyPriceSettingsModel.fromJson(response);
    }
    if (data is num) {
      return DailyPriceSettingsModel.fromJson({'dailyPrice': data.toDouble()});
    }
    throw ApiException('Format response daily-price tidak dikenali', 500);
  }
}
