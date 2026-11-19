import 'package:flutter/foundation.dart';

import '../models/license_model.dart';
import '../services/license_service.dart';

class LicenseProvider extends ChangeNotifier {
  final LicenseService _service = LicenseService();

  LicenseStatusModel? _status;
  List<LicenseHistoryModel> _history = [];
  bool _isLoading = false;
  bool _isActivating = false;
  String? _error;

  LicenseStatusModel? get status => _status;
  List<LicenseHistoryModel> get history => _history;
  bool get isLoading => _isLoading;
  bool get isActivating => _isActivating;
  String? get error => _error;

  /// Muat status lisensi. [silent] dipakai polling dashboard agar tidak
  /// menampilkan loading berkedip.
  Future<void> loadStatus({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _status = await _service.getStatus();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    try {
      _history = await _service.getHistory();
      notifyListeners();
    } catch (_) {
      // riwayat bersifat opsional
    }
  }

  /// Aktifkan lisensi. Mengembalikan null bila gagal (lihat [error]).
  Future<LicenseActivateResult?> activate(String licenseKey,
      {bool force = false}) async {
    _isActivating = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.activate(licenseKey, force: force);
      if (result.status != null) _status = result.status;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isActivating = false;
      notifyListeners();
    }
  }
}
