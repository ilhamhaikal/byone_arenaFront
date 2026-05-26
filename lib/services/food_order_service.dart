import '../config/api_config.dart';
import '../models/food_order_model.dart';
import 'api_service.dart';

class FoodOrderService {
  final ApiService _api = ApiService();

  Future<List<FoodOrderModel>> getFoodOrders() async {
    final response = await _api.get(ApiConfig.foodOrders);
    final List data = response['data'] ?? [];
    return data.map((e) => FoodOrderModel.fromJson(e)).toList();
  }

  Future<List<FoodOrderModel>> getFoodOrdersByStatus(String status) async {
    final response = await _api.get(
      '${ApiConfig.foodOrders}/status',
      {'status': status},
    );
    final List data = response['data'] ?? [];
    return data.map((e) => FoodOrderModel.fromJson(e)).toList();
  }

  Future<List<FoodOrderModel>> getFoodOrdersBySession(
      String sessionId) async {
    final response = await _api
        .get('${ApiConfig.sessions}/$sessionId/food-orders');
    final List data = response['data'] ?? [];
    return data.map((e) => FoodOrderModel.fromJson(e)).toList();
  }

  Future<FoodOrderModel> getFoodOrderById(String id) async {
    final response = await _api.get('${ApiConfig.foodOrders}/$id');
    return FoodOrderModel.fromJson(response['data']);
  }

  Future<FoodOrderModel> createFoodOrder(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.foodOrders, data);
    return FoodOrderModel.fromJson(response['data']);
  }

  Future<FoodOrderModel> updateStatus(
      String id, String status) async {
    final response = await _api.patch(
      '${ApiConfig.foodOrders}/$id/status',
      {'status': status},
    );
    return FoodOrderModel.fromJson(response['data']);
  }

  Future<FoodOrderModel> cancelOrder(String id) async {
    final response =
        await _api.patch('${ApiConfig.foodOrders}/$id/cancel', {});
    return FoodOrderModel.fromJson(response['data']);
  }

  Future<void> deleteOrder(String id) async {
    await _api.delete('${ApiConfig.foodOrders}/$id');
  }
}
