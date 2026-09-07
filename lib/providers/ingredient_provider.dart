import 'package:flutter/material.dart';
import '../models/ingredient_model.dart';
import '../services/ingredient_service.dart';

class IngredientProvider extends ChangeNotifier {
  final IngredientService _service = IngredientService();

  List<IngredientModel> _ingredients = [];
  bool _isLoading = false;
  String? _error;
  List<ExpiredStockItemModel> _expiredIngredients = [];

  List<IngredientModel> get ingredients => _ingredients;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ExpiredStockItemModel> get expiredIngredients => _expiredIngredients;
  int get expiredTotalCount => _expiredIngredients.length;

  Future<void> loadIngredients() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _ingredients = await _service.getIngredients();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExpired({int days = 3}) async {
    try {
      final data = await _service.getExpired(days: days);
      _expiredIngredients = (data['ingredients'] as List<dynamic>? ?? [])
          .map((e) => ExpiredStockItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {
      // silent — indikator opsional
    }
  }

  Future<bool> createIngredient(Map<String, dynamic> data) async {
    try {
      final created = await _service.createIngredient(data);
      _ingredients.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateIngredient(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateIngredient(id, data);
      final index = _ingredients.indexWhere((i) => i.id == id);
      if (index != -1) _ingredients[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteIngredient(String id) async {
    try {
      await _service.deleteIngredient(id);
      _ingredients.removeWhere((i) => i.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addStock(String id, Map<String, dynamic> data) async {
    try {
      await _service.addStock(id, data);
      await loadIngredients();
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
