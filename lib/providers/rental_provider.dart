import 'package:flutter/material.dart';
import '../models/rental_model.dart';
import '../services/mock_data.dart';

class RentalProvider extends ChangeNotifier {
  List<RentalModel> _activeRentals = [];
  List<RentalModel> _allRentals = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _error;
  int _nextId = 100;

  List<RentalModel> get activeRentals => _activeRentals;
  List<RentalModel> get allRentals => _allRentals;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadActiveRentals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _activeRentals = List.from(MockData.activeRentals);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllRentals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _allRentals = List.from(MockData.allRentals);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _stats = Map.from(MockData.dashboardStats);
    notifyListeners();
  }

  Future<RentalModel?> startRental({
    required int consoleNumber,
    required String consoleType,
    int? memberId,
    required double pricePerHour,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final rental = RentalModel(
      id: _nextId++,
      rentalCode: 'R-MOCK${_nextId.toString().padLeft(4, '0')}',
      consoleNumber: consoleNumber,
      consoleType: consoleType,
      memberId: memberId,
      startTime: DateTime.now(),
      pricePerHour: pricePerHour,
      status: 'active',
      notes: notes,
    );
    _activeRentals.insert(0, rental);
    _stats['active_rentals'] = (_stats['active_rentals'] ?? 0) + 1;
    notifyListeners();
    return rental;
  }

  Future<RentalModel?> stopRental(int id, {String? voucherCode}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _activeRentals.indexWhere((r) => r.id == id);
    if (index == -1) return null;
    final r = _activeRentals[index];
    final end = DateTime.now();
    final duration = end.difference(r.startTime).inMinutes;
    final total = (duration / 60) * r.pricePerHour;
    final discount = voucherCode != null ? total * 0.1 : 0.0;
    final stopped = RentalModel(
      id: r.id,
      rentalCode: r.rentalCode,
      consoleNumber: r.consoleNumber,
      consoleType: r.consoleType,
      memberId: r.memberId,
      memberName: r.memberName,
      startTime: r.startTime,
      endTime: end,
      durationMinutes: duration,
      pricePerHour: r.pricePerHour,
      totalPrice: total,
      discountAmount: discount,
      voucherCode: voucherCode,
      finalPrice: total - discount,
      status: 'completed',
      notes: r.notes,
    );
    _activeRentals.removeAt(index);
    _allRentals.insert(0, stopped);
    _stats['active_rentals'] = ((_stats['active_rentals'] ?? 1) - 1).clamp(0, 99);
    _stats['today_revenue'] = (_stats['today_revenue'] ?? 0) + (total - discount);
    notifyListeners();
    return stopped;
  }

  Future<bool> cancelRental(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _activeRentals.removeWhere((r) => r.id == id);
    notifyListeners();
    return true;
  }
}
