import 'package:flutter/material.dart';
import '../models/discount_model.dart';
import '../services/discount_service.dart';

class DiscountProvider extends ChangeNotifier {
  final DiscountService _service = DiscountService();

  List<DiscountModel> _discounts = [];
  bool _isLoading = false;
  String? _error;

  List<DiscountModel> get discounts => _discounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDiscounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _discounts = await _service.getDiscounts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDiscount(Map<String, dynamic> data) async {
    try {
      final created = await _service.createDiscount(data);
      _discounts.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDiscount(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateDiscount(id, data);
      final index = _discounts.indexWhere((d) => d.id == id);
      if (index != -1) _discounts[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDiscount(String id) async {
    try {
      await _service.deleteDiscount(id);
      _discounts.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleDiscount(String id) async {
    try {
      final updated = await _service.toggleDiscount(id);
      final index = _discounts.indexWhere((d) => d.id == id);
      if (index != -1) _discounts[index] = updated;
      notifyListeners();
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
