import 'package:flutter/material.dart';
import '../models/membership_settings_model.dart';
import '../services/membership_settings_service.dart';

class MembershipSettingsProvider extends ChangeNotifier {
  final MembershipSettingsService _service = MembershipSettingsService();

  MembershipSettingsModel? _settings;
  bool _isLoading = false;
  String? _error;

  MembershipSettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get price => _settings?.membershipPrice ?? 0;

  Future<void> loadPrice() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _settings = await _service.getPrice();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePrice(double price) async {
    try {
      _settings = await _service.updatePrice(price);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
