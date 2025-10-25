// App-wide constants
class AppConstants {
  // API Configuration
  static const String baseUrl = 'https://hrms.qreams.com/hdlc/dev';
  static const String hrContext = 'hrapi';
  
  // Storage Keys
  static const String userDataKey = 'userData';
  static const String tokenKey = 'token';
  static const String rememberedCredentialsKey = 'rememberedCredentials';
  
  // App Information
  static const String appName = 'HRMS Mobile';
  static const String appVersion = '1.0.0';
  
  // Default Values
  static const int defaultPageSize = 10;
  static const int defaultRadius = 100; // meters for geofencing
  
  // Role IDs
  static const int superAdminRoleId = 1;
  static const int adminRoleId = 2;
  static const int hrRoleId = 3;
  static const int managerRoleId = 4;
  static const int employeeRoleId = 5;
  
  // Work Status
  static const String activeStatus = 'Active';
  static const String inactiveStatus = 'Inactive';
  static const String pendingStatus = 'Pending';
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
}
