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

  /// Seri 1: pendapatan rental (sewa konsol + rental harian).
  List<double> get rentalValues =>
      _chartData.map((e) => e.rentalRevenue).toList();

  /// Seri 2: penjualan membership.
  List<double> get membershipValues =>
      _chartData.map((e) => e.membershipRevenue).toList();

  /// Seri 3: pendapatan makanan/minuman.
  List<double> get foodValues =>
      _chartData.map((e) => e.foodRevenue).toList();

  /// Nilai maksimum dari semua seri agar garis muat dalam skala sama.
  double get maxRevenue {
    if (_chartData.isEmpty) return 1;
    double m = 0;
    for (final e in _chartData) {
      if (e.rentalRevenue > m) m = e.rentalRevenue;
      if (e.membershipRevenue > m) m = e.membershipRevenue;
      if (e.foodRevenue > m) m = e.foodRevenue;
    }
    return m <= 0 ? 1 : m;
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
