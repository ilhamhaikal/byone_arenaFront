import 'package:flutter/material.dart';
import '../models/voucher_model.dart';
import '../services/voucher_service.dart';

class VoucherProvider extends ChangeNotifier {
  final VoucherService _service = VoucherService();

  List<VoucherModel> _vouchers = [];
  bool _isLoading = false;
  String? _error;
  VoucherModel? _validatedVoucher;

  List<VoucherModel> get vouchers => _vouchers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  VoucherModel? get validatedVoucher => _validatedVoucher;

  Future<void> loadVouchers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _vouchers = await _service.getVouchers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createVoucher(Map<String, dynamic> data) async {
    _error = null;
    try {
      final created = await _service.createVoucher(data);
      _vouchers.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVoucher(String id, Map<String, dynamic> data) async {
    _error = null;
    try {
      final updated = await _service.updateVoucher(id, data);
      final index = _vouchers.indexWhere((v) => v.id == id);
      if (index != -1) _vouchers[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVoucher(String id) async {
    _error = null;
    try {
      await _service.deleteVoucher(id);
      _vouchers.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleVoucher(String id) async {
    _error = null;
    try {
      final updated = await _service.toggleVoucher(id);
      final index = _vouchers.indexWhere((v) => v.id == id);
      if (index != -1) _vouchers[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cek voucher berdasarkan kode, simpan hasilnya di [validatedVoucher]
  Future<VoucherModel?> validateVoucherByCode(String code) async {
    _error = null;
    _validatedVoucher = null;
    notifyListeners();
    try {
      final voucher = await _service.getVoucherByCode(code);
      _validatedVoucher = voucher;
      notifyListeners();
      return voucher;
    } catch (e) {
      _error = 'Voucher tidak ditemukan atau tidak aktif';
      notifyListeners();
      return null;
    }
  }

  void clearValidation() {
    _validatedVoucher = null;
    _error = null;
    notifyListeners();
  }
}

