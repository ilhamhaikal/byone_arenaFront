import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  Future<void> checkAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Validasi token ke server: token kedaluwarsa / akun dinonaktifkan harus
    // langsung memaksa login ulang, bukan menampilkan error berulang.
    try {
      _user = await _authService.me();
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _authService.logout();
        _user = null;
        _status = AuthStatus.unauthenticated;
      } else {
        // Server sedang tidak terjangkau: pertahankan sesi lokal.
        _status = AuthStatus.authenticated;
      }
    } catch (_) {
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final (user, _) = await _authService.login(username, password);
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
