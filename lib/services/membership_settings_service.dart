import 'dart:developer';
import '../config/api_config.dart';
import '../models/membership_settings_model.dart';
import 'api_service.dart';

class MembershipSettingsService {
  final ApiService _api = ApiService();

  Future<MembershipSettingsModel> getPrice() async {
    final response = await _api.get(ApiConfig.membershipSettings);
    log('[MembershipSettings] GET response: $response');
    return _parseResponse(response);
  }

  Future<MembershipSettingsModel> updatePrice(double price) async {
    final response = await _api.put(ApiConfig.membershipSettings, {
      'membershipPrice': price,
    });
    log('[MembershipSettings] PUT response: $response');
    return _parseResponse(response);
  }

  MembershipSettingsModel _parseResponse(Map<String, dynamic> response) {
    // Cari membershipPrice di berbagai kemungkinan lokasi
    dynamic data = response['data'];

    // Case 1: data adalah Map dengan membershipPrice
    if (data is Map<String, dynamic> && data.containsKey('membershipPrice')) {
      return MembershipSettingsModel.fromJson(data);
    }

    // Case 2: response langsung punya membershipPrice
    if (response.containsKey('membershipPrice')) {
      return MembershipSettingsModel.fromJson(response);
    }

    // Case 3: data adalah number (harga langsung)
    if (data is num) {
      return MembershipSettingsModel.fromJson({'membershipPrice': data.toDouble()});
    }

    // Case 4: data adalah Map tanpa membershipPrice — coba cari di dalamnya
    if (data is Map<String, dynamic>) {
      final price = data['price'] ?? data['membership_price'];
      if (price is num) {
        return MembershipSettingsModel.fromJson({'membershipPrice': price.toDouble()});
      }
    }

    // Case 5: response punya 'price' langsung
    final rootPrice = response['price'] ?? response['membership_price'];
    if (rootPrice is num) {
      return MembershipSettingsModel.fromJson({'membershipPrice': rootPrice.toDouble()});
    }

    log('[MembershipSettings] Gagal parse response: $response');
    throw ApiException('Format response tidak dikenali', 500);
  }
}
