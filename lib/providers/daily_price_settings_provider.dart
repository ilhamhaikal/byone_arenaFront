import 'package:flutter/material.dart';
import '../models/daily_price_settings_model.dart';
import '../services/daily_price_settings_service.dart';

class DailyPriceSettingsProvider extends ChangeNotifier {
  final DailyPriceSettingsService _service = DailyPriceSettingsService();

  DailyPriceSettingsModel? _settings;
  bool _isLoading = false;
  String? _error;

  DailyPriceSettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get price => _settings?.dailyPrice ?? 0;

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
