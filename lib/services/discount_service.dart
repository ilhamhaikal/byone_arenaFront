import '../config/api_config.dart';
import '../models/discount_model.dart';
import 'api_service.dart';

class DiscountService {
  final ApiService _api = ApiService();

  Future<List<DiscountModel>> getDiscounts() async {
    final response = await _api.get(ApiConfig.discounts);
    final List data = response['data'] ?? [];
    return data.map((e) => DiscountModel.fromJson(e)).toList();
  }

  Future<List<DiscountModel>> getActiveDiscounts() async {
    final response = await _api.get(ApiConfig.activeDiscounts);
    final List data = response['data'] ?? [];
    return data.map((e) => DiscountModel.fromJson(e)).toList();
  }

  Future<DiscountModel> getDiscountById(String id) async {
    final response = await _api.get('${ApiConfig.discounts}/$id');
    return DiscountModel.fromJson(response['data']);
  }

  Future<DiscountModel> createDiscount(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.discounts, data);
    return DiscountModel.fromJson(response['data']);
  }

  Future<DiscountModel> updateDiscount(
      String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.discounts}/$id', data);
    return DiscountModel.fromJson(response['data']);
  }

  Future<void> deleteDiscount(String id) async {
    await _api.delete('${ApiConfig.discounts}/$id');
  }

  Future<DiscountModel> toggleDiscount(String id) async {
    final response =
        await _api.patch('${ApiConfig.discounts}/$id/toggle', {});
    return DiscountModel.fromJson(response['data']);
  }
}
