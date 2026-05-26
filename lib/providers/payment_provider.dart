import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _error;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _payments = await _service.getAll();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PaymentModel?> getBySession(String sessionId) async {
    try {
      return await _service.getBySession(sessionId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<PaymentModel?> createCash({
    required String sessionId,
    required double cashReceived,
    String? notes,
  }) async {
    try {
      final payment = await _service.createCash(
        sessionId: sessionId,
        cashReceived: cashReceived,
        notes: notes,
      );
      _payments.insert(0, payment);
      notifyListeners();
      return payment;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> refund(String id) async {
    try {
      final updated = await _service.refund(id);
      final idx = _payments.indexWhere((p) => p.id == id);
      if (idx != -1) _payments[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
