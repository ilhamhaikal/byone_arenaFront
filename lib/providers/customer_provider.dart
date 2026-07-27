import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerService _service = CustomerService();

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<CustomerModel> get customers => _filtered;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CustomerModel> get _filtered {
    if (_searchQuery.isEmpty) return _customers;
    final q = _searchQuery.toLowerCase();
    return _customers.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.phone.contains(q) ||
        (c.email?.toLowerCase().contains(q) ?? false)).toList();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _customers = await _service.getAll();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<CustomerModel?> getById(String id) async {
    try {
      return await _service.getById(id);
    } catch (_) {
      return null;
    }
  }

  Future<CustomerModel?> create({
    required String name,
    required String phone,
    String? email,
    bool isMember = false,
    double? membershipPrice,
  }) async {
    try {
      final customer = await _service.create(
        name: name,
        phone: phone,
        email: email,
        isMember: isMember,
        membershipPrice: membershipPrice,
      );
      _customers.insert(0, customer);
      notifyListeners();
      return customer;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> fields) async {
    try {
      final updated = await _service.update(id, fields);
      final idx = _customers.indexWhere((c) => c.id == id);
      if (idx != -1) _customers[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _service.delete(id);
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Jual membership — harga otomatis dari backend
  Future<CustomerModel?> sellMembership(String customerId) async {
    try {
      final updated = await _service.sellMembership(customerId);
      final idx = _customers.indexWhere((c) => c.id == customerId);
      if (idx != -1) _customers[idx] = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // ── Bank Waktu & Poin Loyalitas ──
  Map<String, dynamic>? _loyaltyData;
  bool _loyaltyLoading = false;
  String? _loyaltyError;

  Map<String, dynamic>? get loyaltyData => _loyaltyData;
  bool get loyaltyLoading => _loyaltyLoading;
  String? get loyaltyError => _loyaltyError;

  Future<void> loadLoyalty(String customerId) async {
    _loyaltyLoading = true;
    _loyaltyError = null;
    notifyListeners();
    try {
      _loyaltyData = await _service.getLoyalty(customerId);
    } catch (e) {
      _loyaltyError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loyaltyLoading = false;
      notifyListeners();
    }
  }

  void clearLoyalty() {
    _loyaltyData = null;
    _loyaltyError = null;
    _loyaltyLoading = false;
  }
}
