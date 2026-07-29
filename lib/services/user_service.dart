import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  final ApiService _api = ApiService();

  Future<List<UserModel>> getAll() async {
    final response = await _api.get(ApiConfig.users);
    final list = response['data'] as List<dynamic>;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> create(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.users, data);
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<UserModel> update(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.users}/$id', data);
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConfig.users}/$id');
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _api.patch(ApiConfig.usersChangePassword, {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }
}
