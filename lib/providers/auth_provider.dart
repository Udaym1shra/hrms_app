import 'package:flutter/foundation.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/auth/data/models/auth_state_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  
  AuthState _state = AuthState();
  
  AuthProvider(this._authService) {
    _checkAuthStatus();
  }

  // Getters
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;
  UserModel? get user => _state.user;
  String? get token => _state.token;

  // Check authentication status on app start
  Future<void> _checkAuthStatus() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      _state = await _authService.checkAuthStatus();
    } catch (e) {
      _state = AuthState(
        error: e.toString(),
        isLoading: false,
      );
    }
    
    notifyListeners();
  }

  // Login method
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      _state = await _authService.login(email, password, rememberMe: rememberMe);
      
      if (_state.isAuthenticated) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _state = AuthState(
        error: e.toString(),
        isLoading: false,
      );
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Logout method
  Future<void> logout() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      await _authService.logout();
      _state = AuthState();
    } catch (e) {
      _state = AuthState(
        error: e.toString(),
        isLoading: false,
      );
    }
    
    notifyListeners();
  }

  // Get remembered credentials
  Map<String, String>? getRememberedCredentials() {
    return _authService.getRememberedCredentials();
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      return await _authService.forgotPassword(email);
    } catch (e) {
      throw Exception('Forgot password failed: $e');
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> data) async {
    try {
      return await _authService.resetPassword(data);
    } catch (e) {
      throw Exception('Reset password failed: $e');
    }
  }

  // Clear error
  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }
}
