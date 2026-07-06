import '../config/api_config.dart';
import '../models/tv_notification_model.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _api = ApiService();

  Future<List<TvNotificationModel>> getAll({bool activeOnly = false}) async {
    final res = await _api.get(
      ApiConfig.notifications,
      activeOnly ? {'active': 'true'} : null,
    );
    final list = res['data'] as List<dynamic>;
    return list.map((e) => TvNotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TvNotificationModel> create(Map<String, dynamic> data) async {
    final res = await _api.post(ApiConfig.notifications, data);
    return TvNotificationModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<TvNotificationModel> update(String id, Map<String, dynamic> data) async {
    final res = await _api.put('${ApiConfig.notifications}/$id', data);
    return TvNotificationModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.delete('${ApiConfig.notifications}/$id');
  }

  Future<TvNotificationModel> toggle(String id) async {
    final res = await _api.patch('${ApiConfig.notifications}/$id/toggle');
    return TvNotificationModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> startLoop() async {
    await _api.post(ApiConfig.notificationsLoopStart, {});
  }

  Future<void> stopLoop() async {
    await _api.post(ApiConfig.notificationsLoopStop, {});
  }
}
