import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import '../services/shift_service.dart';

class ShiftProvider extends ChangeNotifier {
  final ShiftService _service = ShiftService();

  List<ShiftModel> _shifts = [];
  bool _isLoading = false;
  String? _error;

  List<ShiftModel> get shifts => _shifts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ShiftModel> get activeShifts => _shifts.where((s) => s.isActive).toList();

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _shifts = await _service.getAll();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadByUser(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _shifts = await _service.getByUser(userId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> create({
    required String userId,
    required String name,
    required int startHour,
    required int endHour,
    bool is24Hour = false,
  }) async {
    try {
      final shift = await _service.create(
        userId: userId,
        name: name,
        startHour: startHour,
        endHour: endHour,
        is24Hour: is24Hour,
      );
      _shifts.insert(0, shift);
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
      final idx = _shifts.indexWhere((s) => s.id == id);
      if (idx != -1) _shifts[idx] = updated;
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
      _shifts.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
