import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  /// Login → returns (UserModel, token)
  Future<(UserModel, String)> login(String username, String password) async {
    final response = await _api.post(ApiConfig.login, {
      'username': username,
      'password': password,
    });
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _api.saveToken(token);
    return (user, token);
  }

  /// Register pengguna baru
  Future<UserModel> register({
    required String username,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final response = await _api.post(ApiConfig.register, {
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role,
    });
    return UserModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _api.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null;
  }
}
