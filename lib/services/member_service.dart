import '../config/api_config.dart';
import '../models/member_model.dart';
import 'api_service.dart';

class MemberService {
  final ApiService _api = ApiService();

  Future<List<MemberModel>> getMembers({String? search, String? type}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (type != null && type.isNotEmpty) params['type'] = type;

    final response = await _api.get(ApiConfig.members, params);
    final List data = response['data'] ?? [];
    return data.map((e) => MemberModel.fromJson(e)).toList();
  }

  Future<MemberModel> getMemberById(int id) async {
    final response = await _api.get('${ApiConfig.members}/$id');
    return MemberModel.fromJson(response['data']);
  }

  Future<MemberModel> getMemberByCode(String code) async {
    final response =
        await _api.get('${ApiConfig.members}/code/$code');
    return MemberModel.fromJson(response['data']);
  }

  Future<MemberModel> createMember(MemberModel member) async {
    final response =
        await _api.post(ApiConfig.members, member.toJson());
    return MemberModel.fromJson(response['data']);
  }

  Future<MemberModel> updateMember(int id, MemberModel member) async {
    final response =
        await _api.put('${ApiConfig.members}/$id', member.toJson());
    return MemberModel.fromJson(response['data']);
  }

  Future<void> deleteMember(int id) async {
    await _api.delete('${ApiConfig.members}/$id');
  }

  Future<void> addPoints(int id, int points) async {
    await _api.post('${ApiConfig.members}/$id/points', {'points': points});
  }
}
