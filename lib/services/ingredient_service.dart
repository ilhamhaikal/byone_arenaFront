import '../config/api_config.dart';
import '../models/ingredient_model.dart';
import 'api_service.dart';

class IngredientService {
  final ApiService _api = ApiService();

  Future<List<IngredientModel>> getIngredients() async {
    final response = await _api.get(ApiConfig.ingredients);
    final List data = response['data'] ?? [];
    return data.map((e) => IngredientModel.fromJson(e)).toList();
  }

  Future<IngredientModel> createIngredient(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.ingredients, data);
    return IngredientModel.fromJson(response['data']);
  }

  Future<IngredientModel> updateIngredient(
      String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.ingredients}/$id', data);
    return IngredientModel.fromJson(response['data']);
  }

  Future<void> deleteIngredient(String id) async {
    await _api.delete('${ApiConfig.ingredients}/$id');
  }

  Future<StockBatchModel> addStock(
      String id, Map<String, dynamic> data) async {
    final response =
        await _api.post('${ApiConfig.ingredients}/$id/stock', data);
    return StockBatchModel.fromJson(response['data']);
  }

  Future<List<StockBatchModel>> listBatches(String id) async {
    final response = await _api.get('${ApiConfig.ingredients}/$id/stock');
    final List data = response['data'] ?? [];
    return data.map((e) => StockBatchModel.fromJson(e)).toList();
  }

  Future<void> setComponents(String id, List<Map<String, dynamic>> items) async {
    await _api.put('${ApiConfig.ingredients}/$id/components', {'items': items});
  }

  Future<List<RecipeItemModel>> listComponents(String id) async {
    final response =
        await _api.get('${ApiConfig.ingredients}/$id/components');
    final List data = response['data'] ?? [];
    return data.map((e) => RecipeItemModel.fromJson(e)).toList();
  }

  Future<void> setMenuIngredients(
      String menuId, List<Map<String, dynamic>> items) async {
    await _api.put('${ApiConfig.menus}/$menuId/ingredients', {'items': items});
  }

  Future<List<RecipeItemModel>> listMenuIngredients(String menuId) async {
    final response = await _api.get('${ApiConfig.menus}/$menuId/ingredients');
    final List data = response['data'] ?? [];
    return data.map((e) => RecipeItemModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getExpired({int days = 3}) async {
    final response =
        await _api.get('${ApiConfig.ingredients}/expired?days=$days');
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  Future<List<StockLogEntryModel>> getStockLog({
    String? startDate,
    String? endDate,
  }) async {
    final qs = <String>[
      if (startDate != null) 'startDate=$startDate',
      if (endDate != null) 'endDate=$endDate',
    ].join('&');
    final response = await _api
        .get('${ApiConfig.ingredients}/stock-log${qs.isNotEmpty ? '?$qs' : ''}');
    final List data = response['data'] ?? [];
    return data.map((e) => StockLogEntryModel.fromJson(e)).toList();
  }
}
