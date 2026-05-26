import '../config/api_config.dart';
import '../models/menu_model.dart';
import 'api_service.dart';

class MenuService {
  final ApiService _api = ApiService();

  Future<List<MenuModel>> getMenus() async {
    final response = await _api.get(ApiConfig.menus);
    final List data = response['data'] ?? [];
    return data.map((e) => MenuModel.fromJson(e)).toList();
  }

  Future<List<MenuModel>> getAvailableMenus() async {
    final response = await _api.get(ApiConfig.availableMenus);
    final List data = response['data'] ?? [];
    return data.map((e) => MenuModel.fromJson(e)).toList();
  }

  Future<List<MenuModel>> getMenusByCategory(String category) async {
    final response = await _api.get('${ApiConfig.menus}/category/$category');
    final List data = response['data'] ?? [];
    return data.map((e) => MenuModel.fromJson(e)).toList();
  }

  Future<MenuModel> getMenuById(String id) async {
    final response = await _api.get('${ApiConfig.menus}/$id');
    return MenuModel.fromJson(response['data']);
  }

  Future<MenuModel> createMenu(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.menus, data);
    return MenuModel.fromJson(response['data']);
  }

  Future<MenuModel> updateMenu(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.menus}/$id', data);
    return MenuModel.fromJson(response['data']);
  }

  Future<void> deleteMenu(String id) async {
    await _api.delete('${ApiConfig.menus}/$id');
  }

  Future<MenuModel> toggleMenu(String id) async {
    final response = await _api.patch('${ApiConfig.menus}/$id/toggle', {});
    return MenuModel.fromJson(response['data']);
  }
}
