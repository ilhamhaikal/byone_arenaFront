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
    bool isMember = false,
    double? membershipPrice,
  }) async {
    final response = await _api.post(ApiConfig.customers, {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      'isMember': isMember,
      if (membershipPrice != null) 'membershipPrice': membershipPrice,
    });
    final data = response['data'];
    // Response bisa {data: {customer: {...}}} atau {data: {...}}
    if (data is Map<String, dynamic>) {
      if (data.containsKey('customer')) {
        return CustomerModel.fromJson(data['customer'] as Map<String, dynamic>);
      }
      return CustomerModel.fromJson(data);
    }
    throw ApiException('Response data tidak valid', 500);
  }

  Future<CustomerModel> update(String id, Map<String, dynamic> fields) async {
    final response = await _api.put('${ApiConfig.customers}/$id', fields);
    return CustomerModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConfig.customers}/$id');
  }

  /// Jual membership ke customer — harga otomatis dari backend
  Future<CustomerModel> sellMembership(String customerId) async {
    final response = await _api.post(
        '${ApiConfig.customers}/$customerId/membership', {});
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return CustomerModel.fromJson(data);
    }
    // Fallback: get customer by ID untuk dapat data terbaru
    return getById(customerId);
  }

  /// Ambil info bank waktu & poin loyalitas member
  Future<Map<String, dynamic>> getLoyalty(String customerId) async {
    final response = await _api.get('${ApiConfig.customers}/$customerId/loyalty');
    return response['data'] as Map<String, dynamic>;
  }
}
