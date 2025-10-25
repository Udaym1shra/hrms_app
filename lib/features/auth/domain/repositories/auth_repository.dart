import '../../data/models/login_request_model.dart';
import '../../data/models/login_response_model.dart';
import '../../data/models/user_model.dart';

// Authentication repository interface
abstract class AuthRepository {
  Future<LoginResponseModel> login(LoginRequestModel request);
  Future<Map<String, dynamic>> forgotPassword(String email);
  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> data);
  Future<bool> isAuthenticated();
  Future<UserModel?> getCurrentUser();
  Future<String?> getToken();
  Future<Map<String, String>?> getRememberedCredentials();
  Future<void> saveRememberedCredentials(String email, String password);
  Future<void> clearRememberedCredentials();
  Future<void> logout();
}
