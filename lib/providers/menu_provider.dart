import 'package:flutter/material.dart';
import '../models/menu_model.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _service = MenuService();

  List<MenuModel> _menus = [];
  bool _isLoading = false;
  String? _error;

  List<MenuModel> get menus => _menus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMenus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _menus = await _service.getMenus();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMenu(Map<String, dynamic> data) async {
    try {
      final created = await _service.createMenu(data);
      _menus.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMenu(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateMenu(id, data);
      final index = _menus.indexWhere((m) => m.id == id);
      if (index != -1) _menus[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMenu(String id) async {
    try {
      await _service.deleteMenu(id);
      _menus.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleMenu(String id) async {
    try {
      final updated = await _service.toggleMenu(id);
      final index = _menus.indexWhere((m) => m.id == id);
      if (index != -1) _menus[index] = updated;
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
