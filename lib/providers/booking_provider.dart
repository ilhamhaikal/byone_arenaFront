import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _svc = BookingService();
  List<BookingModel> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAll({String? date}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _svc.getAll(date: date);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BookingModel?> create({
    required String consoleId,
    String? customerId,
    required String bookingDate,
    required int startHour,
    required int startMinute,
    required int durationMinutes,
    String? notes,
  }) async {
    try {
      final b = await _svc.create(
        consoleId: consoleId,
        customerId: customerId,
        bookingDate: bookingDate,
        startHour: startHour,
        startMinute: startMinute,
        durationMinutes: durationMinutes,
        notes: notes,
      );
      _bookings.insert(0, b);
      notifyListeners();
      return b;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> confirm(String id) => _updateStatus(id, 'confirmed');
  Future<bool> cancel(String id) => _updateStatus(id, 'cancelled');
  Future<bool> complete(String id) => _updateStatus(id, 'completed');

  Future<bool> _updateStatus(String id, String status) async {
    try {
      final updated = await _svc.updateStatus(id, status);
      final idx = _bookings.indexWhere((b) => b.id == id);
      if (idx != -1) _bookings[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
