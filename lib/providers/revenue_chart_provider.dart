import 'package:flutter/material.dart';
import '../models/revenue_chart_item.dart';
import '../services/revenue_chart_service.dart';

class RevenueChartProvider extends ChangeNotifier {
  final RevenueChartService _service = RevenueChartService();

  List<RevenueChartItem> _chartData = [];
  bool _isLoading = false;
  String? _error;

  List<RevenueChartItem> get chartData => _chartData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<double> get revenueValues =>
      _chartData.map((e) => e.revenue).toList();

  double get maxRevenue {
    if (_chartData.isEmpty) return 1;
    return _chartData.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);
  }

  Future<void> loadChart({int days = 7}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _chartData = await _service.getChart(days: days);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
