import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/auth/data/models/auth_state_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

// Service providers for dependency injection
// These will be overridden in main.dart with actual instances
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden in main.dart');
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ApiService(storageService);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthService(apiService, storageService);
});

// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState()) {
    _checkAuthStatus();
  }

  // Getters
  bool get isAuthenticated => state.isAuthenticated;
  bool get isLoading => state.isLoading;
  String? get error => state.error;
  UserModel? get user => state.user;
  String? get token => state.token;

  // Check authentication status on app start
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      state = await _authService.checkAuthStatus();
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
    }
  }

  // Login method
  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      state = await _authService.login(email, password, rememberMe: rememberMe);

      if (state.isAuthenticated) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.logout();
      state = AuthState();
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
    }
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
    state = state.copyWith(error: null);
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
