import 'package:flutter/material.dart';
import '../models/daily_rental_model.dart';
import '../services/daily_rental_service.dart';

class DailyRentalProvider extends ChangeNotifier {
  final DailyRentalService _svc = DailyRentalService();
  List<DailyRentalModel> _rentals = [];
  bool _isLoading = false;
  String? _error;

  List<DailyRentalModel> get rentals => _rentals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _rentals = await _svc.getAll();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DailyRentalModel?> create({
    required String consoleId,
    String? customerId,
    required String startDate,
    required String endDate,
    required double dailyPrice,
    String? notes,
    String? voucherCode,
  }) async {
    try {
      final r = await _svc.create(
        consoleId: consoleId,
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
        dailyPrice: dailyPrice,
        notes: notes,
        voucherCode: voucherCode,
      );
      _rentals.insert(0, r);
      notifyListeners();
      return r;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> returnRental(String id) async {
    try {
      final updated = await _svc.returnRental(id);
      final idx = _rentals.indexWhere((r) => r.id == id);
      if (idx != -1) _rentals[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
