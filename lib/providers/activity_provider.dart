import 'dart:async';
import 'package:flutter/material.dart';
import '../models/activity_item.dart';
import '../services/activity_service.dart';

class ActivityProvider extends ChangeNotifier {
  final ActivityService _service = ActivityService();

  List<ActivityItem> _activities = [];
  Timer? _pollTimer;

  List<ActivityItem> get activities => _activities;

  void startPolling({int interval = 30}) {
    _load();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(Duration(seconds: interval), (_) => _load());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _load() async {
    try {
      _activities = await _service.getRecent(limit: 8);
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
