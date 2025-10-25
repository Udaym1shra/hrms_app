import '../../../../core/errors/failures.dart';
import '../../../../core/constants/app_strings.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

// Authentication repository implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await _remoteDataSource.login(request);

      if (response.error) {
        throw AuthFailure(message: response.message);
      }

      if (response.content == null) {
        throw const AuthFailure(message: 'Invalid response from server');
      }

      // Save user data locally
      await _localDataSource.saveUserData(response.content!);

      return response;
    } on Failure {
      rethrow;
    } catch (e) {
      throw AuthFailure(message: 'Login failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      return await _remoteDataSource.forgotPassword(email);
    } on Failure {
      rethrow;
    } catch (e) {
      throw AuthFailure(message: 'Forgot password failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.resetPassword(data);
    } on Failure {
      rethrow;
    } catch (e) {
      throw AuthFailure(message: 'Reset password failed: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await _localDataSource.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      return await _localDataSource.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _localDataSource.getToken();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, String>?> getRememberedCredentials() async {
    try {
      return await _localDataSource.getRememberedCredentials();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveRememberedCredentials(String email, String password) async {
    try {
      await _localDataSource.saveRememberedCredentials(email, password);
    } catch (e) {
      throw StorageFailure(message: 'Failed to save credentials: $e');
    }
  }

  @override
  Future<void> clearRememberedCredentials() async {
    try {
      await _localDataSource.clearRememberedCredentials();
    } catch (e) {
      throw StorageFailure(message: 'Failed to clear credentials: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _localDataSource.logout();
    } catch (e) {
      throw StorageFailure(message: 'Logout failed: $e');
    }
  }
}
