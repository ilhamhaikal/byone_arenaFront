import 'package:flutter/material.dart';
import '../models/tv_notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _svc = NotificationService();

  List<TvNotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isLoopRunning = false;
  String? _error;

  List<TvNotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoopRunning => _isLoopRunning;
  String? get error => _error;

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _svc.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      final n = await _svc.create(data);
      _notifications.insert(0, n);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    try {
      final n = await _svc.update(id, data);
      final i = _notifications.indexWhere((x) => x.id == id);
      if (i != -1) _notifications[i] = n;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _svc.delete(id);
      _notifications.removeWhere((x) => x.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggle(String id) async {
    try {
      final n = await _svc.toggle(id);
      final i = _notifications.indexWhere((x) => x.id == id);
      if (i != -1) _notifications[i] = n;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> startLoop() async {
    try {
      await _svc.startLoop();
      _isLoopRunning = true;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopLoop() async {
    try {
      await _svc.stopLoop();
      _isLoopRunning = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
