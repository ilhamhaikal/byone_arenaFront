import 'package:flutter/material.dart';
import '../models/discount_model.dart';
import '../services/mock_data.dart';

class DiscountProvider extends ChangeNotifier {
  List<DiscountModel> _discounts = [];
  bool _isLoading = false;
  String? _error;
  int _nextId = 100;

  List<DiscountModel> get discounts => _discounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDiscounts({bool activeOnly = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _discounts = List.from(
        activeOnly ? MockData.discounts.where((d) => d.isActive).toList() : MockData.discounts);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createDiscount(DiscountModel discount) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final created = DiscountModel(
      id: _nextId++,
      name: discount.name,
      description: discount.description,
      discountType: discount.discountType,
      discountValue: discount.discountValue,
      minTransaction: discount.minTransaction,
      membershipType: discount.membershipType,
      startDate: discount.startDate,
      endDate: discount.endDate,
      isActive: discount.isActive,
    );
    _discounts.insert(0, created);
    notifyListeners();
    return true;
  }

  Future<bool> updateDiscount(int id, DiscountModel discount) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _discounts.indexWhere((d) => d.id == id);
    if (index != -1) {
      _discounts[index] = DiscountModel(
        id: id,
        name: discount.name,
        description: discount.description,
        discountType: discount.discountType,
        discountValue: discount.discountValue,
        minTransaction: discount.minTransaction,
        membershipType: discount.membershipType,
        startDate: discount.startDate,
        endDate: discount.endDate,
        isActive: discount.isActive,
      );
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteDiscount(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _discounts.removeWhere((d) => d.id == id);
    notifyListeners();
    return true;
  }

  Future<bool> toggleDiscount(int id, bool isActive) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _discounts.indexWhere((d) => d.id == id);
    if (index != -1) {
      final d = _discounts[index];
      _discounts[index] = DiscountModel(
        id: d.id,
        name: d.name,
        description: d.description,
        discountType: d.discountType,
        discountValue: d.discountValue,
        minTransaction: d.minTransaction,
        membershipType: d.membershipType,
        startDate: d.startDate,
        endDate: d.endDate,
        isActive: isActive,
      );
      notifyListeners();
    }
    return true;
  }
}
