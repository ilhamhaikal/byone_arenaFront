import '../config/api_config.dart';
import '../models/console_model.dart';
import '../models/console_overview_model.dart';
import 'api_service.dart';

class ConsoleService {
  final ApiService _api = ApiService();

  Future<List<ConsoleModel>> getAll() async {
    final response = await _api.get(ApiConfig.consoles);
    final list = response['data'] as List<dynamic>;
    return list.map((e) => ConsoleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ConsoleModel>> getAvailable() async {
    final response = await _api.get(ApiConfig.availableConsoles);
    final list = response['data'] as List<dynamic>;
    return list.map((e) => ConsoleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ConsoleOverviewModel>> getOverview() async {
    final response = await _api.get(ApiConfig.consolesOverview);
    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => ConsoleOverviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConsoleModel> getById(String id) async {
    final response = await _api.get('${ApiConfig.consoles}/$id');
    return ConsoleModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ConsoleModel> create({
    required String name,
    required String consoleType,
    required double pricePerHour,
    String? description,
    String? ipAddress,
  }) async {
    final response = await _api.post(ApiConfig.consoles, {
      'name': name,
      'consoleType': consoleType,
      'pricePerHour': pricePerHour,
      if (description != null) 'description': description,
      if (ipAddress != null && ipAddress.isNotEmpty) 'ipAddress': ipAddress,
    });
    return ConsoleModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ConsoleModel> update(String id, Map<String, dynamic> fields) async {
    final response = await _api.put('${ApiConfig.consoles}/$id', fields);
    return ConsoleModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConfig.consoles}/$id');
  }
}
