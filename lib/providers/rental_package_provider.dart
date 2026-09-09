import 'package:flutter/material.dart';
import '../models/rental_package_model.dart';
import '../services/rental_package_service.dart';

class RentalPackageProvider extends ChangeNotifier {
  final RentalPackageService _svc = RentalPackageService();
  List<RentalPackageModel> _packages = [];
  bool _isLoading = false;
  String? _error;

  List<RentalPackageModel> get packages => _packages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _packages = await _svc.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> save(Map<String, dynamic> data) async {
    try {
      await _svc.save(data);
      await load();
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
      await load();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
