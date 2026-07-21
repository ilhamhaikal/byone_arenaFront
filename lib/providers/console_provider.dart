import 'package:flutter/material.dart';
import '../models/console_model.dart';
import '../models/console_overview_model.dart';
import '../services/console_service.dart';

class ConsoleProvider extends ChangeNotifier {
  final ConsoleService _service = ConsoleService();

  List<ConsoleModel> _consoles = [];
  List<ConsoleModel> _available = [];
  List<ConsoleOverviewModel> _overview = [];
  bool _isLoading = false;
  String? _error;
  String? _tvActionTarget; // id konsol yang sedang di-wake/sleep
  final Map<String, int> _pendingMinutes = {}; // tracking menit pending per session

  List<ConsoleModel> get consoles => _consoles;
  List<ConsoleModel> get available => _available;
  List<ConsoleOverviewModel> get overview => _overview;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get tvActionTarget => _tvActionTarget;
  Map<String, int> get pendingMinutes => _pendingMinutes;

  void setPendingMinutes(String sessionId, int minutes) {
    if (minutes > 0) {
      _pendingMinutes[sessionId] = minutes;
    } else {
      _pendingMinutes.remove(sessionId);
    }
    notifyListeners();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _consoles = await _service.getAll();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAvailable() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _available = await _service.getAvailable();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOverview() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _overview = await _service.getOverview();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String name,
    required String consoleType,
    required double pricePerHour,
    String? description,
    String? ipAddress,
    List<Map<String, dynamic>>? pricingTiers,
    double? dailyPrice,
  }) async {
    try {
      final console = await _service.create(
        name: name,
        consoleType: consoleType,
        pricePerHour: pricePerHour,
        description: description,
        ipAddress: ipAddress,
        pricingTiers: pricingTiers,
        dailyPrice: dailyPrice,
      );
      _consoles.insert(0, console);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> fields) async {
    try {
      final updated = await _service.update(id, fields);
      final idx = _consoles.indexWhere((c) => c.id == id);
      if (idx != -1) _consoles[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _service.delete(id);
      _consoles.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── TV Control ──────────────────────────────────────────────────────────
  Future<bool> wake(String id) async {
    _tvActionTarget = id;
    notifyListeners();
    try {
      await _service.wake(id);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _tvActionTarget = null;
      notifyListeners();
    }
  }

  Future<bool> sleep(String id) async {
    _tvActionTarget = id;
    notifyListeners();
    try {
      await _service.sleep(id);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _tvActionTarget = null;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Optimistic update: hapus sesi aktif dari konsol di overview
  /// tanpa harus menunggu loadOverview() selesai.
  void clearActiveSessionFromOverview(String sessionId) {
    for (final c in _overview) {
      if (c.activeSession?.id == sessionId) {
        // Buat salinan konsol tanpa activeSession & ubah status ke available
        final idx = _overview.indexOf(c);
        if (idx == -1) continue;
        _overview[idx] = ConsoleOverviewModel(
          id: c.id,
          name: c.name,
          consoleType: c.consoleType,
          pricePerHour: c.pricePerHour,
          status: 'available',
          description: c.description,
          ipAddress: c.ipAddress,
          screenStatus: c.screenStatus,
          createdAt: c.createdAt,
          updatedAt: DateTime.now(),
          activeSession: null,
        );
      }
    }
    notifyListeners();
  }
}
