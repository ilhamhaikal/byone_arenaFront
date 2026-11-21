import 'package:flutter/material.dart';
import '../models/tv_notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _svc;

  NotificationProvider({NotificationService? service})
      : _svc = service ?? NotificationService();

  List<TvNotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isLoopRunning = false;
  int _activeLoopCount = 0;
  bool _loopBusy = false;
  bool _disposed = false;
  String? _error;

  /// Dinaikkan setiap kali data berubah lewat create/update/delete/toggle/
  /// show. Snapshot `loadAll` yang dimulai sebelum perubahan tidak boleh
  /// menimpa state terbaru (dulu inilah penyebab notifikasi yang sudah
  /// dinonaktifkan terlihat aktif lagi setelah reload).
  int _mutationSeq = 0;

  /// ID notifikasi yang sedang diproses (toggle/hapus/tampilkan) supaya
  /// tombol tidak bisa ditekan dua kali dan UI bisa menampilkan spinner.
  final Set<String> _pendingIds = {};

  List<TvNotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isLoopRunning => _isLoopRunning;
  int get activeLoopCount => _activeLoopCount;
  bool get loopBusy => _loopBusy;
  String? get error => _error;

  bool isPending(String id) => _pendingIds.contains(id);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Cegah "notifyListeners after dispose" saat request masih berjalan
  /// ketika halaman ditutup/logout.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  /// Minimal satu notifikasi di daftar yang layak ikut loop. Dipakai UI
  /// untuk mengaktifkan tombol Mulai tanpa menunggu status server.
  bool get hasLoopCandidate => _notifications.any(
        (n) => n.isActive && n.autoShow && n.loopEnabled,
      );

  String _message(Object e) {
    final text = e.toString();
    return text
        .replaceFirst('ApiException: ', '')
        .replaceFirst('Exception: ', '')
        .trim();
  }

  void _setError(Object e) {
    _error = _message(e);
  }

  Future<void> loadAll() async {
    final startSeq = _mutationSeq;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final fetched = await _svc.getAll();
      // Jika ada create/update/delete/toggle/show yang selesai selama fetch,
      // snapshot ini sudah basi. Jangan timpa state terbaru.
      if (_mutationSeq == startSeq) {
        _notifications = fetched;
      }
    } catch (e) {
      _setError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    // Status loop diambil terpisah: kegagalan endpoint status tidak boleh
    // membuat daftar notifikasi gagal tampil.
    await refreshLoopStatus();
  }

  /// Sinkronkan status loop dengan server (mis. setelah restart aplikasi,
  /// edit dari perangkat lain, atau loop auto-start di backend).
  Future<void> refreshLoopStatus() async {
    try {
      final status = await _svc.getLoopStatus();
      _isLoopRunning = status.running;
      _activeLoopCount = status.activeLoopNotifications;
      notifyListeners();
    } catch (_) {
      // Status loop opsional; biarkan nilai terakhir agar UI tidak berkedip.
    }
  }

  Future<bool> create(Map<String, dynamic> data) async {
    _error = null;
    try {
      final n = await _svc.create(data);
      _mutationSeq++;
      _notifications.insert(0, n);
      notifyListeners();
      await refreshLoopStatus();
      return true;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    _error = null;
    try {
      final n = await _svc.update(id, data);
      _mutationSeq++;
      final i = _notifications.indexWhere((x) => x.id == id);
      if (i != -1) {
        _notifications[i] = n;
      } else {
        _notifications.insert(0, n);
      }
      notifyListeners();
      await refreshLoopStatus();
      return true;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(String id) async {
    if (_pendingIds.contains(id)) return false;
    _pendingIds.add(id);
    _error = null;
    notifyListeners();
    try {
      await _svc.delete(id);
      _mutationSeq++;
      _notifications.removeWhere((x) => x.id == id);
      _pendingIds.remove(id);
      notifyListeners();
      await refreshLoopStatus();
      return true;
    } catch (e) {
      _pendingIds.remove(id);
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggle(String id) async {
    if (_pendingIds.contains(id)) return false;
    _pendingIds.add(id);
    _error = null;
    notifyListeners();
    try {
      final n = await _svc.toggle(id);
      _mutationSeq++;
      final i = _notifications.indexWhere((x) => x.id == id);
      if (i != -1) _notifications[i] = n;
      _pendingIds.remove(id);
      notifyListeners();
      await refreshLoopStatus();
      return true;
    } catch (e) {
      _pendingIds.remove(id);
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  /// Tampilkan notifikasi manual sekali di TV.
  Future<bool> show(String id) async {
    if (_pendingIds.contains(id)) return false;
    _pendingIds.add(id);
    _error = null;
    notifyListeners();
    try {
      final n = await _svc.show(id);
      _mutationSeq++;
      final i = _notifications.indexWhere((x) => x.id == id);
      if (i != -1) _notifications[i] = n;
      _pendingIds.remove(id);
      notifyListeners();
      // Trigger manual mengubah lastTriggeredAt, bukan status aktif.
      await refreshLoopStatus();
      return true;
    } catch (e) {
      _pendingIds.remove(id);
      _setError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> startLoop() async {
    if (_loopBusy) return false;
    _loopBusy = true;
    _error = null;
    notifyListeners();
    try {
      await _svc.startLoop();
      await refreshLoopStatus();
      return true;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return false;
    } finally {
      _loopBusy = false;
      notifyListeners();
    }
  }

  Future<bool> stopLoop() async {
    if (_loopBusy) return false;
    _loopBusy = true;
    _error = null;
    notifyListeners();
    try {
      await _svc.stopLoop();
      await refreshLoopStatus();
      return true;
    } catch (e) {
      _setError(e);
      notifyListeners();
      return false;
    } finally {
      _loopBusy = false;
      notifyListeners();
    }
  }
}
