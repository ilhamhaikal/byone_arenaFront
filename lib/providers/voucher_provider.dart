import 'package:flutter/material.dart';
import '../models/voucher_model.dart';
import '../services/mock_data.dart';

class VoucherProvider extends ChangeNotifier {
  List<VoucherModel> _vouchers = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _validatedVoucher;
  int _nextId = 100;

  List<VoucherModel> get vouchers => _vouchers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get validatedVoucher => _validatedVoucher;

  Future<void> loadVouchers({bool activeOnly = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));
    _vouchers = List.from(
        activeOnly ? MockData.vouchers.where((v) => v.isActive).toList() : MockData.vouchers);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createVoucher(VoucherModel voucher) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final created = VoucherModel(
      id: _nextId++,
      code: voucher.code,
      name: voucher.name,
      discountType: voucher.discountType,
      discountValue: voucher.discountValue,
      minTransaction: voucher.minTransaction,
      maxUsage: voucher.maxUsage,
      usedCount: 0,
      expiredAt: voucher.expiredAt,
      isActive: voucher.isActive,
    );
    _vouchers.insert(0, created);
    notifyListeners();
    return true;
  }

  Future<bool> updateVoucher(int id, VoucherModel voucher) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _vouchers.indexWhere((v) => v.id == id);
    if (index != -1) {
      _vouchers[index] = VoucherModel(
        id: id,
        code: voucher.code,
        name: voucher.name,
        discountType: voucher.discountType,
        discountValue: voucher.discountValue,
        minTransaction: voucher.minTransaction,
        maxUsage: voucher.maxUsage,
        usedCount: _vouchers[index].usedCount,
        expiredAt: voucher.expiredAt,
        isActive: voucher.isActive,
      );
      notifyListeners();
    }
    return true;
  }

  Future<bool> deleteVoucher(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _vouchers.removeWhere((v) => v.id == id);
    notifyListeners();
    return true;
  }

  Future<Map<String, dynamic>?> validateVoucher(
      String code, double amount) async {
    _error = null;
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final voucher = _vouchers.firstWhere(
        (v) => v.code.toLowerCase() == code.toLowerCase() && v.isActive,
      );
      if (amount < (voucher.minTransaction ?? 0)) {
        _error = 'Transaksi minimal Rp ${voucher.minTransaction?.toStringAsFixed(0)}';
        _validatedVoucher = null;
        notifyListeners();
        return null;
      }
      final discount = voucher.discountType == 'percentage'
          ? amount * (voucher.discountValue / 100)
          : voucher.discountValue;
      _validatedVoucher = {
        'voucher': voucher,
        'discount_amount': discount,
        'final_price': amount - discount,
      };
      notifyListeners();
      return _validatedVoucher;
    } catch (_) {
      _error = 'Voucher tidak ditemukan atau tidak aktif';
      _validatedVoucher = null;
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
