import 'package:flutter/material.dart';
import '../models/console_model.dart';
import '../services/console_service.dart';

class ConsoleProvider extends ChangeNotifier {
  final ConsoleService _service = ConsoleService();

  List<ConsoleModel> _consoles = [];
  List<ConsoleModel> _available = [];
  bool _isLoading = false;
  String? _error;

  List<ConsoleModel> get consoles => _consoles;
  List<ConsoleModel> get available => _available;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  Future<bool> create({
    required String name,
    required String consoleType,
    required double pricePerHour,
    String? description,
  }) async {
    try {
      final console = await _service.create(
        name: name,
        consoleType: consoleType,
        pricePerHour: pricePerHour,
        description: description,
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
}
