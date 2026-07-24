import 'dart:async';
import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../models/pending_payments_response.dart';
import '../models/session_payments_summary.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  PaymentModel? _current;
  bool _isLoading = false;
  String? _error;

  // ── Pending payments (dashboard banner) ──
  List<PaymentModel> _pendingPayments = [];
  int _pendingCount = 0;
  Timer? _pendingPollTimer;

  PaymentModel? get current => _current;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PaymentModel> get pendingPayments => _pendingPayments;
  int get pendingCount => _pendingCount;
  bool get hasPendingPayments => _pendingCount > 0;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Pending payments polling ────────────────────────────────────────────
  void startPendingPolling({int interval = 10}) {
    _loadPendingPayments();
    _pendingPollTimer?.cancel();
    _pendingPollTimer =
        Timer.periodic(Duration(seconds: interval), (_) => _loadPendingPayments());
  }

  void stopPendingPolling() {
    _pendingPollTimer?.cancel();
    _pendingPollTimer = null;
  }

  Future<void> _loadPendingPayments() async {
    try {
      final response = await _service.getPending();
      _pendingPayments = response.payments;
      _pendingCount = response.pendingCount;
      notifyListeners();
    } catch (e) {
      debugPrint('PendingPayments error: $e');
    }
  }

  /// Optimistic: hapus pembayaran dari list segera + refresh dari server.
  void removePendingOptimistic(String paymentId) {
    _pendingPayments.removeWhere((p) => p.id == paymentId);
    _pendingCount = _pendingPayments.length;
    notifyListeners();
    // Refresh dari server untuk sinkronisasi
    _loadPendingPayments();
  }

  @override
  void dispose() {
    stopPendingPolling();
    super.dispose();
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

  /// Ambil ringkasan SELURUH payment sebuah sesi (base + semua perpanjangan).
  /// Gunakan ini (bukan [getBySession]) saat mengakhiri sesi, supaya total
  /// tagihan/pending yang ditampilkan benar walau sesi sudah di-extend > 1×.
  Future<SessionPaymentsSummary?> getAllBySession(String sessionId) async {
    _error = null;
    try {
      return await _service.getAllBySession(sessionId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
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

  /// Konfirmasi pembayaran pending (admin input cash — opsional).
  Future<PaymentModel?> confirmPayment({
    required String paymentId,
    double? cashReceived,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final payment = await _service.confirm(paymentId, cashReceived: cashReceived);
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
}
