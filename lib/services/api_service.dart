import 'dart:convert';
import 'package:http/http.dart' as http;
import '../features/auth/data/models/login_request_model.dart';
import '../features/auth/data/models/login_response_model.dart';
import '../models/employee_models.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'https://hrms.qreams.com/hdlc/dev';
  static const String hrContext = 'hrapi';

  final StorageService _storageService;
  late final http.Client _client;

  ApiService(this._storageService) {
    _client = http.Client();
  }

  // Get headers with authentication
  Map<String, String> _getHeaders() {
    final token = _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Handle unauthorized - clear storage and redirect to login
      _storageService.logout();
      throw Exception('Unauthorized - Please login again');
    } else if (response.statusCode == 400) {
      // Handle bad request - return the response data for detailed error handling
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }

  // Authentication APIs
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final url = Uri.parse('$baseUrl/$hrContext/auth/login');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      final responseData = _handleResponse(response);
      return LoginResponseModel.fromJson(responseData);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final url = Uri.parse('$baseUrl/$hrContext/auth/forgot-password');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Forgot password failed: $e');
    }
  }

  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$baseUrl/$hrContext/auth/reset-password');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Reset password failed: $e');
    }
  }

  // Employee APIs
  Future<EmployeeResponse> getEmployeeById(int employeeId) async {
    try {
      final url = Uri.parse('$baseUrl/$hrContext/employee/$employeeId');
      final response = await _client.get(url, headers: _getHeaders());

      final responseData = _handleResponse(response);
      return EmployeeResponse.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to fetch employee: $e');
    }
  }

  Future<EmployeeResponse> getEmployees({
    int limit = 10,
    int page = 1,
    String? searchQuery,
    String? status,
    String? departmentIds,
    String? order,
    int? tenantIds,
    String? name,
    String? employeeIds,
    String? reportingManagerId,
    int? roleId,
    String? designationIds,
    String? branchId,
    bool? isbulk,
    String? employeeType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/$hrContext/employee').replace(
        queryParameters: {
          'limit': limit.toString(),
          'page': page.toString(),
          if (searchQuery != null) 'search': searchQuery,
          if (departmentIds != null) 'departmentIds': departmentIds,
          if (order != null) 'order': order,
          if (status != null && status != 'all') 'status': status,
          if (tenantIds != null) 'tenantIds': tenantIds.toString(),
          if (reportingManagerId != null)
            'reportingManagerId': reportingManagerId,
          if (roleId != null) 'roleId': roleId.toString(),
          if (designationIds != null) 'designationIds': designationIds,
          if (branchId != null) 'branchId': branchId,
          if (isbulk != null) 'isbulk': isbulk.toString(),
          if (employeeType != null) 'employeeType': employeeType,
        },
      );

      final response = await _client.get(uri, headers: _getHeaders());

      final responseData = _handleResponse(response);
      return EmployeeResponse.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to fetch employees: $e');
    }
  }

  // Geofencing APIs
  Future<Map<String, dynamic>> getGeofencingConfig({
    int? tenantId,
    int? branchId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/$hrContext/geofencing-config').replace(
        queryParameters: {
          if (tenantId != null) 'tenantId': tenantId.toString(),
          if (branchId != null) 'branchId': branchId.toString(),
        },
      );

      final response = await _client.get(uri, headers: _getHeaders());

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch geofencing config: $e');
    }
  }

  Future<Map<String, dynamic>> createEmployeeLocation({
    required int employeeId,
    required double lat,
    required double lon,
    required String date,
    required String time,
    required int tenantId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$hrContext/geofencing-employee-location');
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'employeeId': employeeId,
          'lat': lat,
          'lon': lon,
          'date': date,
          'time': time,
          'tenantId': tenantId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to create employee location: $e');
    }
  }

  // Attendance APIs
  Future<Map<String, dynamic>> punchIn({
    required int employeeId,
    required double lat,
    required double lon,
    required String date,
    required String time,
    required int tenantId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$hrContext/attendance/punch-in');
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'employeeId': employeeId,
          'lat': lat,
          'lon': lon,
          'date': date,
          'time': time,
          'tenantId': tenantId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Punch in failed: $e');
    }
  }

  Future<Map<String, dynamic>> punchOut({
    required int employeeId,
    required double lat,
    required double lon,
    required String date,
    required String time,
    required int tenantId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$hrContext/attendance/punch-out');
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'employeeId': employeeId,
          'lat': lat,
          'lon': lon,
          'date': date,
          'time': time,
          'tenantId': tenantId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Punch out failed: $e');
    }
  }

  // Dashboard APIs
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final url = Uri.parse('$baseUrl/$hrContext/dashboard');
      final response = await _client.get(url, headers: _getHeaders());

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch dashboard data: $e');
    }
  }

  // Dispose client
  void dispose() {
    _client.close();
  }
}
