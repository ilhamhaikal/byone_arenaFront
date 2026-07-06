import 'package:flutter/material.dart';
import '../models/report_summary_model.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _svc = ReportService();
  ReportSummaryModel? _report;
  bool _isLoading = false;
  String? _error;

  ReportSummaryModel? get report => _report;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReport({
    required String startDate,
    required String endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _report = await _svc.getSummary(startDate: startDate, endDate: endDate);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
