import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/data/models/login_response_model.dart';
import '../features/auth/data/models/user_model.dart';

class StorageService {
  final SharedPreferences _prefs;

  static const String _userDataKey = 'userData';
  static const String _tokenKey = 'token';
  static const String _rememberedCredentialsKey = 'rememberedCredentials';

  StorageService(this._prefs);

  // User Data Storage
  Future<void> saveUserData(LoginContentModel loginContent) async {
    await _prefs.setString(_userDataKey, jsonEncode(loginContent.toJson()));
    await _prefs.setString(_tokenKey, loginContent.token);
  }

  LoginContentModel? getUserData() {
    final userDataString = _prefs.getString(_userDataKey);
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

  String? getToken() {
    return _prefs.getString(_tokenKey);
  }

  UserModel? getCurrentUser() {
    final userData = getUserData();
    return userData?.user;
  }

  bool isAuthenticated() {
    final token = getToken();
    final userData = getUserData();
    return token != null && userData != null;
  }

  // Remember Me functionality
  Future<void> saveRememberedCredentials(String email, String password) async {
    final credentials = {'email': email, 'password': password};
    await _prefs.setString(_rememberedCredentialsKey, jsonEncode(credentials));
  }

  Map<String, String>? getRememberedCredentials() {
    final credentialsString = _prefs.getString(_rememberedCredentialsKey);
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

  Future<void> clearRememberedCredentials() async {
    await _prefs.remove(_rememberedCredentialsKey);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.remove(_userDataKey);
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_rememberedCredentialsKey);
  }

  // Logout
  Future<void> logout() async {
    await clearAll();
  }
}
