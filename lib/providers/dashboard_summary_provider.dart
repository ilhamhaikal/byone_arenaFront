import 'package:flutter/material.dart';
import '../models/dashboard_summary_model.dart';
import '../services/dashboard_service.dart';

class DashboardSummaryProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  DashboardSummaryModel? _summary;
  bool _isLoading = false;
  String? _error;

  DashboardSummaryModel? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _summary = await _service.getSummary();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
