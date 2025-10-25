import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/login_response_model.dart';

// Authentication local data source
abstract class AuthLocalDataSource {
  Future<void> saveUserData(LoginContentModel loginContent);
  Future<LoginContentModel?> getUserData();
  Future<String?> getToken();
  Future<dynamic?> getCurrentUser();
  Future<bool> isAuthenticated();
  Future<void> saveRememberedCredentials(String email, String password);
  Future<Map<String, String>?> getRememberedCredentials();
  Future<void> clearRememberedCredentials();
  Future<void> clearAll();
  Future<void> logout();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences _prefs;

  AuthLocalDataSourceImpl(this._prefs);

  @override
  Future<void> saveUserData(LoginContentModel loginContent) async {
    await _prefs.setString(
      AppConstants.userDataKey,
      jsonEncode(loginContent.toJson()),
    );
    await _prefs.setString(AppConstants.tokenKey, loginContent.token);
  }

  @override
  Future<LoginContentModel?> getUserData() async {
    final userDataString = _prefs.getString(AppConstants.userDataKey);
    if (userDataString != null) {
      try {
        final userDataJson = jsonDecode(userDataString);
        return LoginContentModel.fromJson(userDataJson);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<String?> getToken() async {
    return _prefs.getString(AppConstants.tokenKey);
  }

  @override
  Future<dynamic?> getCurrentUser() async {
    final userData = await getUserData();
    return userData?.user;
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    final userData = await getUserData();
    return token != null && userData != null;
  }

  @override
  Future<void> saveRememberedCredentials(String email, String password) async {
    final credentials = {'email': email, 'password': password};
    await _prefs.setString(
      AppConstants.rememberedCredentialsKey,
      jsonEncode(credentials),
    );
  }

  @override
  Future<Map<String, String>?> getRememberedCredentials() async {
    final credentialsString = _prefs.getString(
      AppConstants.rememberedCredentialsKey,
    );
    if (credentialsString != null) {
      try {
        final credentialsJson = jsonDecode(credentialsString);
        return Map<String, String>.from(credentialsJson);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> clearRememberedCredentials() async {
    await _prefs.remove(AppConstants.rememberedCredentialsKey);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(AppConstants.userDataKey);
    await _prefs.remove(AppConstants.tokenKey);
    await _prefs.remove(AppConstants.rememberedCredentialsKey);
  }

  @override
  Future<void> logout() async {
    await clearAll();
  }
}
