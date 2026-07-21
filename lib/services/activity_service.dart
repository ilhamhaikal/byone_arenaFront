import '../config/api_config.dart';
import '../models/activity_item.dart';
import 'api_service.dart';

class ActivityService {
  final ApiService _api = ApiService();

  /// GET /api/v1/activities/recent?limit=N
  Future<List<ActivityItem>> getRecent({int limit = 10}) async {
    final response = await _api.get(
      ApiConfig.activitiesRecent,
      {'limit': limit.toString()},
    );
    final data = response['data'];
    if (data is List) {
      return data
          .map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
