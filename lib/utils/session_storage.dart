import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/auth/data/models/user_model.dart';

class SessionStorage {
  static const String _tokenKey = 'token';
  static const String _userDataKey = 'userData';
  static const String _companyIdKey = 'companyId';

  // Get auth token from storage
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      return token;
    } catch (e) {
      print('Failed to get auth token: $e');
      return null;
    }
  }

  // Get user data from storage
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      
      if (userDataString != null) {
        print('userData from storage: $userDataString');
        return jsonDecode(userDataString);
      }
      return null;
    } catch (e) {
      print('Failed to parse userData from storage: $e');
      return null;
    }
  }

  // Get parsed user object
  static Future<UserModel?> getUser() async {
    try {
      final userData = await getUserData();
      if (userData != null && userData['user'] != null) {
        return UserModel.fromJson(userData['user']);
      }
      return null;
    } catch (e) {
      print('Failed to parse user from storage: $e');
      return null;
    }
  }

  // Get JWT token
  static Future<String?> getJwtToken() async {
    try {
      final userData = await getUserData();
      return userData?['token'];
    } catch (e) {
      print('Failed to get JWT token: $e');
      return null;
    }
  }

  // Get role information
  static Future<RoleModel?> getRole() async {
    try {
      final user = await getUser();
      return user?.role;
    } catch (e) {
      print('Failed to get role: $e');
      return null;
    }
  }

  // Get employee ID
  static Future<int?> getEmployeeId() async {
    try {
      final user = await getUser();
      return user?.employeeId;
    } catch (e) {
      print('Failed to get employee ID: $e');
      return null;
    }
  }

  // Check if user is admin
  static Future<bool> isAdmin() async {
    try {
      final role = await getRole();
      return role?.id == 1;
    } catch (e) {
      print('Failed to check admin status: $e');
      return false;
    }
  }

  // Check if user is super admin
  static Future<bool> isSuperAdmin() async {
    try {
      final role = await getRole();
      return role?.id == 8;
    } catch (e) {
      print('Failed to check super admin status: $e');
      return false;
    }
  }

  // Check if user is HR
  static Future<bool> isHR() async {
    try {
      final role = await getRole();
      return role?.id == 2;
    } catch (e) {
      print('Failed to check HR status: $e');
      return false;
    }
  }

  // Check if user is manager
  static Future<bool> isManager() async {
    try {
      final role = await getRole();
      return role?.id == 3;
    } catch (e) {
      print('Failed to check manager status: $e');
      return false;
    }
  }

  // Get tenant ID
  static Future<int?> getTenantId() async {
    try {
      final user = await getUser();
      return user?.tenantId;
    } catch (e) {
      print('Failed to get tenant ID: $e');
      return null;
    }
  }

  // Get branch ID
  static Future<int?> getBranchId() async {
    try {
      final user = await getUser();
      return user?.branchId;
    } catch (e) {
      print('Failed to get branch ID: $e');
      return null;
    }
  }

  // Get company ID (from tenant if available)
  static Future<int?> getCompanyId() async {
    try {
      final user = await getUser();
      return user?.tenant?.id;
    } catch (e) {
      print('Failed to get company ID: $e');
      return null;
    }
  }

  // Get manager role ID constant
  static int get managerRoleId => 3;

  // Save user data to storage
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(userData));
      
      // Also save token separately for quick access
      if (userData['token'] != null) {
        await prefs.setString(_tokenKey, userData['token']);
      }
    } catch (e) {
      print('Failed to save user data: $e');
    }
  }

  // Clear all session data
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_companyIdKey);
    } catch (e) {
      print('Failed to clear session: $e');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getAuthToken();
      final userData = await getUserData();
      return token != null && userData != null;
    } catch (e) {
      print('Failed to check login status: $e');
      return false;
    }
  }
}

// Extension to provide a hook-like interface similar to React
class SessionStorageHook {
  static Future<SessionStorageData> useSessionStorage() async {
    final userData = await SessionStorage.getUserData();
    
    return SessionStorageData(
      user: userData?['user'] != null ? UserModel.fromJson(userData!['user']) : null,
      jwtToken: userData?['token'],
      role: userData?['user']?['role'] != null ? RoleModel.fromJson(userData!['user']['role']) : null,
      employeeId: userData?['user']?['employeeId'],
      isAdmin: userData?['user']?['role']?['id'] == 1,
      isSuperAdmin: userData?['user']?['role']?['id'] == 8,
      isHR: userData?['user']?['role']?['id'] == 2,
      isManager: userData?['user']?['role']?['id'] == 3,
      tenantId: userData?['user']?['tenantId'],
      branchId: userData?['user']?['branchId'],
      companyId: userData?['user']?['tenant']?['id'],
    );
  }
}

// Extension to provide destructuring-like functionality
extension SessionStorageDestructuring on SessionStorageData {
  // Destructuring methods for common use cases
  ({int? tenantId, bool isAdmin}) get tenantAndAdmin => (tenantId: tenantId, isAdmin: isAdmin);
  
  ({int? employeeId, bool isManager}) get employeeAndManager => (employeeId: employeeId, isManager: isManager);
  
  ({UserModel? user, String? jwtToken}) get userAndToken => (user: user, jwtToken: jwtToken);
  
  ({bool isAdmin, bool isHR, bool isManager}) get roleChecks => (isAdmin: isAdmin, isHR: isHR, isManager: isManager);
  
  ({int? tenantId, int? branchId, int? companyId}) get organizationIds => (tenantId: tenantId, branchId: branchId, companyId: companyId);
}

// Global function for easy access (similar to React hook)
Future<SessionStorageData> useSession() async {
  return await SessionStorageHook.useSessionStorage();
}

// Data class to hold session storage data
class SessionStorageData {
  final UserModel? user;
  final String? jwtToken;
  final RoleModel? role;
  final int? employeeId;
  final bool isAdmin;
  final bool isSuperAdmin;
  final bool isHR;
  final bool isManager;
  final int? tenantId;
  final int? branchId;
  final int? companyId;

  const SessionStorageData({
    this.user,
    this.jwtToken,
    this.role,
    this.employeeId,
    this.isAdmin = false,
    this.isSuperAdmin = false,
    this.isHR = false,
    this.isManager = false,
    this.tenantId,
    this.branchId,
    this.companyId,
  });

  // Manager role ID constant
  int get managerRoleId => 3;
}
