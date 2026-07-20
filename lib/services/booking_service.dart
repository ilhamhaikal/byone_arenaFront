import '../config/api_config.dart';
import '../models/booking_model.dart';
import 'api_service.dart';

class BookingService {
  final ApiService _api = ApiService();

  Future<List<BookingModel>> getAll({String? date}) async {
    final params = <String, String>{};
    if (date != null && date.isNotEmpty) params['date'] = date;
    final response = await _api.get(ApiConfig.bookings, params);
    final list = response['data'] as List<dynamic>;
    return list
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> create({
    required String consoleId,
    String? customerId,
    required String bookingDate,
    required int startHour,
    required int startMinute,
    required int durationMinutes,
    String? notes,
  }) async {
    final response = await _api.post(ApiConfig.bookings, {
      'consoleId': consoleId,
      if (customerId != null) 'customerId': customerId,
      'bookingDate': bookingDate,
      'startHour': startHour,
      'startMinute': startMinute,
      'durationMinutes': durationMinutes,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return BookingModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Update status: confirmed, cancelled, completed
  Future<BookingModel> updateStatus(String id, String status) async {
    final response = await _api.patch(
      '${ApiConfig.bookings}/$id/status?status=$status',
      {},
    );
    return BookingModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
