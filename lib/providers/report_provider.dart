import 'package:flutter/material.dart';
import '../models/report_summary_model.dart';
import '../models/staff_report_model.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _svc = ReportService();
  ReportSummaryModel? _report;
  StaffReportModel? _staffReport;
  bool _isLoading = false;
  bool _isStaffLoading = false;
  String? _error;
  String? _staffError;

  ReportSummaryModel? get report => _report;
  StaffReportModel? get staffReport => _staffReport;
  bool get isLoading => _isLoading;
  bool get isStaffLoading => _isStaffLoading;
  String? get error => _error;
  String? get staffError => _staffError;

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

  Future<void> loadStaffReport({
    required String startDate,
    required String endDate,
    String? userId,
  }) async {
    _isStaffLoading = true;
    _staffError = null;
    notifyListeners();
    try {
      _staffReport = await _svc.getStaffReport(
        startDate: startDate,
        endDate: endDate,
        userId: userId,
      );
    } catch (e) {
      _staffError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isStaffLoading = false;
      notifyListeners();
    }
  }
}
