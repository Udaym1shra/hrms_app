import '../models/auth_models.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService(this._apiService, this._storageService);

  // Login with email and password
  Future<AuthState> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await _apiService.login(request);

      if (response.error) {
        return AuthState(
          error: response.message,
          isLoading: false,
        );
      }

      if (response.content == null) {
        return AuthState(
          error: 'Invalid response from server',
          isLoading: false,
        );
      }

      final loginContent = response.content!;
      final user = loginContent.user;
      final token = loginContent.token;

      // Validate user status
      if (user.workStatus != 'Active') {
        return AuthState(
          error: 'Access denied. Please contact the HR.',
          isLoading: false,
        );
      }

      // Save user data and token
      await _storageService.saveUserData(loginContent);

      // Handle remember me
      if (rememberMe) {
        await _storageService.saveRememberedCredentials(email, password);
      } else {
        await _storageService.clearRememberedCredentials();
      }

      return AuthState(
        isAuthenticated: true,
        user: user,
        token: token,
        isLoading: false,
      );
    } catch (e) {
      return AuthState(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Check if user is already authenticated
  Future<AuthState> checkAuthStatus() async {
    try {
      if (!_storageService.isAuthenticated()) {
        return AuthState(isAuthenticated: false);
      }

      final userData = _storageService.getUserData();
      if (userData == null) {
        await _storageService.logout();
        return AuthState(isAuthenticated: false);
      }

      return AuthState(
        isAuthenticated: true,
        user: userData.user,
        token: userData.token,
      );
    } catch (e) {
      await _storageService.logout();
      return AuthState(
        isAuthenticated: false,
        error: e.toString(),
      );
    }
  }

  // Get remembered credentials
  Map<String, String>? getRememberedCredentials() {
    return _storageService.getRememberedCredentials();
  }

  // Logout
  Future<void> logout() async {
    await _storageService.logout();
  }

  // Get current user
  User? getCurrentUser() {
    return _storageService.getCurrentUser();
  }

  // Get auth token
  String? getToken() {
    return _storageService.getToken();
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      return await _apiService.forgotPassword(email);
    } catch (e) {
      throw Exception('Forgot password failed: $e');
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> data) async {
    try {
      return await _apiService.resetPassword(data);
    } catch (e) {
      throw Exception('Reset password failed: $e');
    }
  }
}
