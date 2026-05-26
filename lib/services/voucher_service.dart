import '../config/api_config.dart';
import '../models/voucher_model.dart';
import 'api_service.dart';

class VoucherService {
  final ApiService _api = ApiService();

  Future<List<VoucherModel>> getVouchers({bool? activeOnly}) async {
    final params = <String, String>{};
    if (activeOnly == true) params['active'] = 'true';
    final response = await _api.get(ApiConfig.vouchers, params);
    final List data = response['data'] ?? [];
    return data.map((e) => VoucherModel.fromJson(e)).toList();
  }

  Future<VoucherModel> getVoucherById(int id) async {
    final response = await _api.get('${ApiConfig.vouchers}/$id');
    return VoucherModel.fromJson(response['data']);
  }

  Future<VoucherModel> createVoucher(VoucherModel voucher) async {
    final response =
        await _api.post(ApiConfig.vouchers, voucher.toJson());
    return VoucherModel.fromJson(response['data']);
  }

  Future<VoucherModel> updateVoucher(int id, VoucherModel voucher) async {
    final response =
        await _api.put('${ApiConfig.vouchers}/$id', voucher.toJson());
    return VoucherModel.fromJson(response['data']);
  }

  Future<void> deleteVoucher(int id) async {
    await _api.delete('${ApiConfig.vouchers}/$id');
  }

  Future<Map<String, dynamic>> validateVoucher(
      String code, double amount) async {
    final response = await _api.post(ApiConfig.validateVoucher, {
      'code': code,
      'amount': amount,
    });
    return response['data'];
  }
}
