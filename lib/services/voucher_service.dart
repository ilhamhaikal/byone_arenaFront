import '../config/api_config.dart';
import '../models/voucher_model.dart';
import 'api_service.dart';

class VoucherService {
  final ApiService _api = ApiService();

  Future<List<VoucherModel>> getVouchers() async {
    final response = await _api.get(ApiConfig.vouchers);
    final List data = response['data'] ?? [];
    return data.map((e) => VoucherModel.fromJson(e)).toList();
  }

  Future<VoucherModel> getVoucherById(String id) async {
    final response = await _api.get('${ApiConfig.vouchers}/$id');
    return VoucherModel.fromJson(response['data']);
  }

  /// Cek voucher berdasarkan kode (GET /vouchers/code/{code})
  Future<VoucherModel> getVoucherByCode(String code) async {
    final response = await _api.get('${ApiConfig.voucherByCode}/$code');
    return VoucherModel.fromJson(response['data']);
  }

  Future<VoucherModel> createVoucher(Map<String, dynamic> data) async {
    final response = await _api.post(ApiConfig.vouchers, data);
    return VoucherModel.fromJson(response['data']);
  }

  Future<VoucherModel> updateVoucher(String id, Map<String, dynamic> data) async {
    final response = await _api.put('${ApiConfig.vouchers}/$id', data);
    return VoucherModel.fromJson(response['data']);
  }

  Future<void> deleteVoucher(String id) async {
    await _api.delete('${ApiConfig.vouchers}/$id');
  }

  /// Toggle aktif/nonaktif voucher (PATCH /vouchers/{id}/toggle)
  Future<VoucherModel> toggleVoucher(String id) async {
    final response = await _api.patch('${ApiConfig.vouchers}/$id/toggle');
    return VoucherModel.fromJson(response['data']);
  }
}
