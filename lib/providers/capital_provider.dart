import 'package:flutter/material.dart';
import '../models/capital_model.dart';
import '../services/capital_service.dart';

class CapitalProvider extends ChangeNotifier {
  final CapitalService _svc = CapitalService();
  List<CapitalEntryModel> _entries = [];
  List<MonthlyCapitalModel> _monthly = [];
  bool _isLoading = false;
  String? _error;

  List<CapitalEntryModel> get entries => _entries;
  List<MonthlyCapitalModel> get monthly => _monthly;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadEntries({String? startDate, String? endDate}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _svc.listEntries(startDate: startDate, endDate: endDate);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMonthly() async {
    try {
      _monthly = await _svc.monthly();
      notifyListeners();
    } catch (_) {
      // silent — indikator opsional
    }
  }

  Future<bool> addEntry(Map<String, dynamic> data) async {
    try {
      await _svc.addEntry(data);
      await loadEntries();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    try {
      await _svc.deleteEntry(id);
      await loadEntries();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
