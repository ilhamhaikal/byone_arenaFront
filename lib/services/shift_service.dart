import '../config/api_config.dart';
import '../models/shift_model.dart';
import 'api_service.dart';

class ShiftService {
  final ApiService _api = ApiService();

  Future<List<ShiftModel>> getAll() async {
    final response = await _api.get(ApiConfig.shifts);
    final list = response['data'] as List<dynamic>;
    return list.map((e) => ShiftModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ShiftModel> getById(String id) async {
    final response = await _api.get('${ApiConfig.shifts}/$id');
    return ShiftModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<List<ShiftModel>> getByUser(String userId) async {
    final response = await _api.get('${ApiConfig.shifts}?userId=$userId');
    final list = response['data'] as List<dynamic>;
    return list.map((e) => ShiftModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ShiftModel> create({
    required String userId,
    required String name,
    required int startHour,
    required int endHour,
    bool is24Hour = false,
  }) async {
    final response = await _api.post(ApiConfig.shifts, {
      'userId': userId,
      'name': name,
      'startHour': startHour,
      'endHour': endHour,
      'is24Hour': is24Hour,
    });
    return ShiftModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ShiftModel> update(String id, Map<String, dynamic> fields) async {
    final response = await _api.put('${ApiConfig.shifts}/$id', fields);
    return ShiftModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConfig.shifts}/$id');
  }
}
