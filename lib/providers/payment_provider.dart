import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  PaymentModel? _current;
  bool _isLoading = false;
  String? _error;

  PaymentModel? get current => _current;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<PaymentModel?> getBySession(String sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _current = await _service.getBySession(sessionId);
      return _current;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PaymentModel?> getById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _current = await _service.getById(id);
      return _current;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// [voucherCode] opsional — kode voucher diskon
  Future<PaymentModel?> createCash({
    required String sessionId,
    required double cashReceived,
    String? voucherCode,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final payment = await _service.createCash(
        sessionId: sessionId,
        cashReceived: cashReceived,
        voucherCode: voucherCode,
        notes: notes,
      );
      _current = payment;
      notifyListeners();
      return payment;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refund(String id) async {
    _error = null;
    try {
      final updated = await _service.refund(id);
      if (_current?.id == id) _current = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
