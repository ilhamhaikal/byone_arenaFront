import '../config/api_config.dart';
import '../models/rental_model.dart';
import 'api_service.dart';

class RentalService {
  final ApiService _api = ApiService();

  Future<List<RentalModel>> getRentals({String? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    final response = await _api.get(ApiConfig.rentals, params);
    final List data = response['data'] ?? [];
    return data.map((e) => RentalModel.fromJson(e)).toList();
  }

  Future<List<RentalModel>> getActiveRentals() => getRentals(status: 'active');

  Future<RentalModel> getRentalById(int id) async {
    final response = await _api.get('${ApiConfig.rentals}/$id');
    return RentalModel.fromJson(response['data']);
  }

  Future<RentalModel> startRental({
    required int consoleNumber,
    required String consoleType,
    int? memberId,
    required double pricePerHour,
    String? notes,
  }) async {
    final response = await _api.post(ApiConfig.rentals, {
      'console_number': consoleNumber,
      'console_type': consoleType,
      'member_id': memberId,
      'price_per_hour': pricePerHour,
      'notes': notes,
    });
    return RentalModel.fromJson(response['data']);
  }

  Future<RentalModel> stopRental(int id, {String? voucherCode}) async {
    final body = <String, dynamic>{};
    if (voucherCode != null && voucherCode.isNotEmpty) {
      body['voucher_code'] = voucherCode;
    }
    final response =
        await _api.post('${ApiConfig.rentals}/$id/stop', body);
    return RentalModel.fromJson(response['data']);
  }

  Future<void> cancelRental(int id) async {
    await _api.post('${ApiConfig.rentals}/$id/cancel', {});
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _api.get('${ApiConfig.rentals}/stats/today');
    return response['data'];
  }
}
