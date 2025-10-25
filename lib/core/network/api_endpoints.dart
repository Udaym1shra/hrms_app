import '../constants/app_constants.dart';

// API endpoints configuration
class ApiEndpoints {
  // Base URLs
  static const String baseUrl = AppConstants.baseUrl;
  static const String hrContext = AppConstants.hrContext;
  
  // Authentication endpoints
  static const String login = '/$hrContext/auth/login';
  static const String forgotPassword = '/$hrContext/auth/forgot-password';
  static const String resetPassword = '/$hrContext/auth/reset-password';
  static const String resetOldPassword = '/$hrContext/auth/reset-password-with-old-password';
  
  // Employee endpoints
  static const String employees = '/$hrContext/employee';
  static String employeeById(int id) => '/$hrContext/employee/$id';
  static const String employeeBulkUpload = '/$hrContext/employee/bulk-upload';
  
  // Department endpoints
  static const String departments = '/$hrContext/department';
  
  // Designation endpoints
  static const String designations = '/$hrContext/designation';
  
  // Company endpoints
  static const String companies = '/$hrContext/company';
  
  // Branch endpoints
  static const String branches = '/$hrContext/branch';
  
  // Attendance endpoints
  static const String attendance = '/$hrContext/attendance';
  static String markAttendance(int employeeId) => '/$hrContext/attendance/mark-attendance/$employeeId';
  static String getAttendanceById(int attendanceId) => '/$hrContext/attendance/get/list/$attendanceId';
  static String getEmployeePunchingDetails(int employeeId) => '/$hrContext/attendance/employee/$employeeId';
  static const String punchIn = '/$hrContext/attendance/punch-in'; // Legacy - use markAttendance instead
  static const String punchOut = '/$hrContext/attendance/punch-out'; // Legacy - use markAttendance instead
  
  // Leave endpoints
  static const String leaves = '/$hrContext/leaves';
  static const String leaveBalance = '/$hrContext/leaves/getallleavebalance';
  static const String leaveBalanceById = '/$hrContext/leaves/getleavebalance';
  static const String updateLeaveBalance = '/$hrContext/leaves/updateleavebalance';
  static const String deleteLeaveBalance = '/$hrContext/leaves/deleteleavebalance';
  
  // Geofencing endpoints
  static const String geofencingConfig = '/$hrContext/geofencing-config';
  static const String geofencingEmployeeLocation = '/$hrContext/geofencing-employee-location';
  
  // Dashboard endpoints
  static const String dashboard = '/$hrContext/dashboard';
  static const String clientStatistics = '/$hrContext/dashboard/client-statistics';
  static const String clientGraphs = '/$hrContext/dashboard/client-statistics/graphs';
  static const String vendorStatistics = '/$hrContext/dashboard/vendor/vendor-statistics';
  static const String vendorGraphs = '/$hrContext/dashboard/vendor/vendor-statistics/graphs';
  static const String employeeStatistics = '/$hrContext/dashboard/employee-statistics';
  
  // Master data endpoints
  static const String masters = '/$hrContext/master';
  static const String masterTypes = '/$hrContext/master-type';
  static const String masterDataSettings = '/$hrContext/master-data';
  
  // Holiday endpoints
  static const String holidays = '/$hrContext/holidays';
  static const String holidayTypes = '/$hrContext/holiday-type';
  
  // Asset endpoints
  static const String assets = '/$hrContext/assets';
  
  // Project endpoints
  static const String projects = '/$hrContext/project';
  
  // Timesheet endpoints
  static const String timesheets = '/$hrContext/timesheet';
  
  // Overtime endpoints
  static const String overtime = '/$hrContext/overtime';
  
  // Leave policy endpoints
  static const String leavePolicies = '/$hrContext/leaves-policy';
  
  // Shift schedule endpoints
  static const String shiftSchedules = '/$hrContext/shift';
  
  // Vendor endpoints
  static const String vendors = '/$hrContext/vendor';
  static const String vendorCreate = '/$hrContext/vendor/create';
  static const String vendorUpdate = '/$hrContext/vendor/update';
  static const String vendorBulkUpload = '/$hrContext/vendor/bulk-upload';
  
  // Client endpoints
  static const String clients = '/$hrContext/client';
  static const String clientCreate = '/$hrContext/client/with-attachments';
  static const String clientUpdate = '/$hrContext/client/with-attachments';
  static const String clientImport = '/$hrContext/client/import-clients';
  
  // Assignment endpoints
  static const String assignments = '/$hrContext/assign';
  static const String assignmentGet = '/$hrContext/assign/get';
  static const String assignmentUpdate = '/$hrContext/assign';
  
  // Invoice endpoints
  static const String invoices = '/$hrContext/invoice';
  static const String invoiceGet = '/$hrContext/invoice/get';
  static const String invoiceUpdate = '/$hrContext/invoice';
  static const String invoiceNextNumber = '/$hrContext/invoice/next-number';
  
  // Salary endpoints
  static const String salaryStructure = '/$hrContext/salary-structure';
  static const String salaryStructureBulkUpload = '/$hrContext/salary-structure/bulk/upload';
  static const String salaryStructureTransactions = '/$hrContext/salary-structure';
  static const String salaryStructureTransactionById = '/$hrContext/salary-structure/transactions';
  static const String salaryStructureBulkStatusUpdate = '/$hrContext/salary-structure/transactions/status/bulk';
  static const String salaryStructureUpdateTransaction = '/$hrContext/salary-structure/transactions';
  
  // Payroll endpoints
  static const String payroll = '/$hrContext/payroll';
  static const String payrollGenerate = '/$hrContext/payroll';
  static const String payrollGetById = '/$hrContext/payroll/get';
  static const String payrollBulkUpdate = '/$hrContext/payroll/bulk-update';
  
  // Audit log endpoints
  static const String auditLogs = '/$hrContext/audit-logger';
  
  // Subscription module endpoints
  static const String subscriptionModules = '/$hrContext/subscription-module';
  static const String subscriptionModuleGetById = '/$hrContext/subscription-module';
  static const String subscriptionModuleCreate = '/$hrContext/subscription-module';
  static const String subscriptionModuleUpdate = '/$hrContext/subscription-module';
  static const String subscriptionModuleDelete = '/$hrContext/subscription-module';
  
  // Currency endpoints
  static const String currencies = '/$hrContext/currency';
  
  // Tenant subscription endpoints
  static const String tenantSubscriptions = '/$hrContext/tenant-subscription';
  static const String tenantSubscriptionCreate = '/$hrContext/tenant-subscription';
  static const String tenantSubscriptionUpdate = '/$hrContext/tenant-subscription';
  
  // Payment tracking endpoints
  static const String paymentTracking = '/$hrContext/payment-tracking';
  static const String paymentTrackingCreate = '/$hrContext/payment-tracking';
  static const String paymentTrackingGetById = '/$hrContext/payment-tracking/invoice';
  static const String paymentTrackingUpdate = '/$hrContext/payment-tracking';
  static const String paymentTrackingReceipt = '/$hrContext/payment-tracking/receipt';
  static const String paymentTrackingDelete = '/$hrContext/payment-tracking';
  
  // Vendor payment tracking endpoints
  static const String vendorPaymentTracking = '/$hrContext/vendor-payment-tracking';
  
  // Vendor invoice endpoints
  static const String vendorInvoices = '/$hrContext/vendor-invoice';
  
  // Miscellaneous endpoints
  static const String miscellaneous = '/$hrContext/miscellaneous';
  
  // Code master endpoints
  static const String codeMaster = '/$hrContext/code-master';
}
