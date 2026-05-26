import 'package:flutter/material.dart';
import '../models/food_order_model.dart';
import '../services/food_order_service.dart';

class FoodOrderProvider extends ChangeNotifier {
  final FoodOrderService _service = FoodOrderService();

  List<FoodOrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<FoodOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<FoodOrderModel> get activeOrders => _orders
      .where((o) => o.status == 'pending' || o.status == 'preparing')
      .toList();

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _service.getFoodOrders();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder(Map<String, dynamic> data) async {
    try {
      final created = await _service.createFoodOrder(data);
      _orders.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      final updated = await _service.updateStatus(id, status);
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) _orders[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelOrder(String id) async {
    try {
      final updated = await _service.cancelOrder(id);
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) _orders[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrder(String id) async {
    try {
      await _service.deleteOrder(id);
      _orders.removeWhere((o) => o.id == id);
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
