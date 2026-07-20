import '../config/api_config.dart';
import '../models/daily_rental_model.dart';
import 'api_service.dart';

class DailyRentalService {
  final ApiService _api = ApiService();

  Future<List<DailyRentalModel>> getAll() async {
    final response = await _api.get(ApiConfig.dailyRentals);
    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => DailyRentalModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DailyRentalModel> create({
    required String consoleId,
    String? customerId,
    required String startDate,
    required String endDate,
    required double dailyPrice,
    String? notes,
    String? voucherCode,
  }) async {
    final response = await _api.post(ApiConfig.dailyRentals, {
      'consoleId': consoleId,
      if (customerId != null) 'customerId': customerId,
      'startDate': startDate,
      'endDate': endDate,
      if (dailyPrice > 0) 'dailyPrice': dailyPrice,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (voucherCode != null && voucherCode.isNotEmpty)
        'voucherCode': voucherCode,
    });
    return DailyRentalModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<DailyRentalModel> returnRental(String id) async {
    final response =
        await _api.post('${ApiConfig.dailyRentals}/$id/return', {});
    return DailyRentalModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
