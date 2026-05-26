import '../config/api_config.dart';
import '../models/discount_model.dart';
import 'api_service.dart';

class DiscountService {
  final ApiService _api = ApiService();

  Future<List<DiscountModel>> getDiscounts({bool? activeOnly}) async {
    final params = <String, String>{};
    if (activeOnly == true) params['active'] = 'true';
    final response = await _api.get(ApiConfig.discounts, params);
    final List data = response['data'] ?? [];
    return data.map((e) => DiscountModel.fromJson(e)).toList();
  }

  Future<DiscountModel> getDiscountById(int id) async {
    final response = await _api.get('${ApiConfig.discounts}/$id');
    return DiscountModel.fromJson(response['data']);
  }

  Future<DiscountModel> createDiscount(DiscountModel discount) async {
    final response =
        await _api.post(ApiConfig.discounts, discount.toJson());
    return DiscountModel.fromJson(response['data']);
  }

  Future<DiscountModel> updateDiscount(int id, DiscountModel discount) async {
    final response =
        await _api.put('${ApiConfig.discounts}/$id', discount.toJson());
    return DiscountModel.fromJson(response['data']);
  }

  Future<void> deleteDiscount(int id) async {
    await _api.delete('${ApiConfig.discounts}/$id');
  }

  Future<void> toggleDiscount(int id, bool isActive) async {
    await _api.put(
        '${ApiConfig.discounts}/$id/toggle', {'is_active': isActive});
  }
}
