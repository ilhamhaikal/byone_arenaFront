import '../config/api_config.dart';
import '../models/rental_package_model.dart';
import 'api_service.dart';

class RentalPackageService {
  final ApiService _api = ApiService();

  Future<List<RentalPackageModel>> list() async {
    final res = await _api.get(ApiConfig.rentalPackages);
    final List data = res['data'] ?? [];
    return data
        .map((e) => RentalPackageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RentalPackageModel> save(Map<String, dynamic> data) async {
    final res = await _api.post(ApiConfig.rentalPackages, data);
    return RentalPackageModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConfig.rentalPackages}/$id');
  }
}
