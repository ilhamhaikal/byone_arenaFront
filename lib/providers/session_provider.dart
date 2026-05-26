import 'package:flutter/material.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';

class SessionProvider extends ChangeNotifier {
  final SessionService _service = SessionService();

  List<SessionModel> _activeSessions = [];
  List<SessionModel> _allSessions = [];
  bool _isLoading = false;
  String? _error;

  List<SessionModel> get activeSessions => _activeSessions;
  List<SessionModel> get allSessions => _allSessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeCount => _activeSessions.length;

  Future<void> loadActive() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _activeSessions = await _service.getActive();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _allSessions = await _service.getAll();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SessionModel?> start({
    required String consoleId,
    String? customerId,
    String? notes,
  }) async {
    try {
      final session = await _service.start(
        consoleId: consoleId,
        customerId: customerId,
        notes: notes,
      );
      _activeSessions.insert(0, session);
      notifyListeners();
      return session;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<SessionModel?> end(String id) async {
    try {
      final session = await _service.end(id);
      _activeSessions.removeWhere((s) => s.id == id);
      final idx = _allSessions.indexWhere((s) => s.id == id);
      if (idx != -1) _allSessions[idx] = session;
      notifyListeners();
      return session;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<SessionModel?> cancel(String id) async {
    try {
      final session = await _service.cancel(id);
      _activeSessions.removeWhere((s) => s.id == id);
      notifyListeners();
      return session;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
