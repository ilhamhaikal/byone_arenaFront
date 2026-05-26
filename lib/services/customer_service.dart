import '../config/api_config.dart';
import '../models/customer_model.dart';
import 'api_service.dart';

class CustomerService {
  final ApiService _api = ApiService();

  Future<List<CustomerModel>> getAll() async {
    final response = await _api.get(ApiConfig.customers);
    final list = response['data'] as List<dynamic>;
    return list.map((e) => CustomerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CustomerModel> getById(String id) async {
    final response = await _api.get('${ApiConfig.customers}/$id');
    return CustomerModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<CustomerModel> create({
    required String name,
    required String phone,
    String? email,
  }) async {
    final response = await _api.post(ApiConfig.customers, {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
    });
    return CustomerModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<CustomerModel> update(String id, Map<String, dynamic> fields) async {
    final response = await _api.put('${ApiConfig.customers}/$id', fields);
    return CustomerModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConfig.customers}/$id');
  }
}
