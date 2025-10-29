import 'dart:convert';
import 'package:http/http.dart' as http;
import '../features/auth/data/models/login_request_model.dart';
import '../features/auth/data/models/login_response_model.dart';
import '../models/employee_models.dart';
import '../models/attendance_models.dart';
import '../core/network/api_endpoints.dart';
import 'storage_service.dart';
// Centralized endpoints

class ApiService {
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
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.login}');
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
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.forgotPassword}',
      );
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
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.resetPassword}',
      );
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
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.employeeById(employeeId)}',
      );
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
      final uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.employees}')
          .replace(
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
      final uri =
          Uri.parse(
            '${ApiEndpoints.baseUrl}${ApiEndpoints.geofencingConfig}',
          ).replace(
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
    required String date, // YYYY-MM-DD
    required String time, // HH:mm:ss
    required String inOut, // "In" | "Out"
    required int tenantId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.geofencingEmployeeLocation}',
      );
      final payload = {
        'employeeId': employeeId,
        'lat': lat,
        'lon': lon,
        'date': date,
        'time': time,
        'inOut': inOut,
        'tenantId': tenantId,
      };
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to create employee location: $e');
    }
  }

  // Get geofence configuration for employee
  Future<Map<String, dynamic>> getEmployeeGeofenceConfig({
    required int employeeId,
    int? tenantId,
  }) async {
    try {
      final uri =
          Uri.parse(
            '${ApiEndpoints.baseUrl}${ApiEndpoints.geofencingEmployeeLocation}',
          ).replace(
            queryParameters: {
              if (tenantId != null) 'tenantId': tenantId.toString(),
            },
          );

      final response = await _client.get(uri, headers: _getHeaders());

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch employee geofence config: $e');
    }
  }

  // Validate location against geofence
  Future<Map<String, dynamic>> validateLocationAgainstGeofence({
    required int employeeId,
    required double lat,
    required double lon,
    int? tenantId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.geofencingValidate}',
      );
      final response = await _client.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'employeeId': employeeId,
          'lat': lat,
          'lon': lon,
          if (tenantId != null) 'tenantId': tenantId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to validate location against geofence: $e');
    }
  }

  // Get employee location list for a specific date
  Future<Map<String, dynamic>> getEmployeeLocationList({
    required int employeeId,
    required String date,
    int limit = 50,
    int page = 1,
  }) async {
    try {
      final uri =
          Uri.parse(
            '${ApiEndpoints.baseUrl}${ApiEndpoints.geofencingEmployeeLocation}',
          ).replace(
            queryParameters: {
              'employeeId': employeeId.toString(),
              'limit': limit.toString(),
              'page': page.toString(),
              'startDate': date,
              'endDate': date,
            },
          );

      final response = await _client.get(uri, headers: _getHeaders());
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch employee location list: $e');
    }
  }

  // Update geofence configuration
  Future<Map<String, dynamic>> updateGeofenceConfig({
    required int employeeId,
    required double latitude,
    required double longitude,
    required double radius,
    String? name,
    int? tenantId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.geofencingConfig}',
      );
      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'employeeId': employeeId,
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
          if (name != null) 'name': name,
          if (tenantId != null) 'tenantId': tenantId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update geofence config: $e');
    }
  }

  // Attendance APIs
  Future<Map<String, dynamic>> punchIn({
    required int employeeId,
    required double lat,
    required double lon,
    required String dateWithTime,
    String? punchType,
    // required int tenantId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.markAttendance(employeeId)}',
      );
      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'employeeId': employeeId,
          'lat': lat,
          'lon': lon,
          'date': dateWithTime,
          if (punchType != null) 'punchType': punchType,
          // 'tenantId': tenantId,
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
    required String dateWithTime,
    String? punchType,
    // required int tenantId,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.markAttendance(employeeId)}',
      );
      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode({
          'employeeId': employeeId,
          'lat': lat,
          'lon': lon,
          'date': dateWithTime,
          if (punchType != null) 'punchType': punchType,
          // 'tenantId': tenantId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Punch out failed: $e');
    }
  }

  // Attendance APIs - Get attendance by ID
  Future<AttendanceByIdResponse> getAttendanceById(int attendanceId) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.getAttendanceById(attendanceId)}',
      );
      final response = await _client.get(url, headers: _getHeaders());

      final responseData = _handleResponse(response);
      return AttendanceByIdResponse.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to fetch attendance: $e');
    }
  }

  // Get attendance list by attendance ID using the specific URL format
  Future<Map<String, dynamic>> getAttendanceListById(int attendanceId) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.attendance}/get/list/$attendanceId',
      );
      final response = await _client.get(url, headers: _getHeaders());

      final responseData = _handleResponse(response);
      return responseData;
    } catch (e) {
      throw Exception('Failed to fetch attendance list by ID: $e');
    }
  }

  // Get attendance logs by employee ID and date
  Future<Map<String, dynamic>> getAttendanceLogsByEmployeeAndDate({
    required int employeeId,
    required String date,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.attendance}/$employeeId',
      ).replace(queryParameters: {'date': date, 'limit': '10'});
      final response = await _client.get(url, headers: _getHeaders());

      final responseData = _handleResponse(response);
      return responseData;
    } catch (e) {
      throw Exception(
        'Failed to fetch attendance logs by employee and date: $e',
      );
    }
  }

  // Attendance APIs - Get attendance list
  Future<AttendanceResponse> getAttendanceList({
    int? employeeId,
    int? tenantId,
    String? startDate,
    String? endDate,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      Uri uri;

      if (employeeId != null) {
        // Use path parameter when employeeId is provided
        uri =
            Uri.parse(
              '${ApiEndpoints.baseUrl}${ApiEndpoints.attendance}/$employeeId',
            ).replace(
              queryParameters: {
                'limit': limit.toString(),
                'page': page.toString(),
                if (tenantId != null) 'tenantId': tenantId.toString(),
                if (startDate != null) 'startDate': startDate,
                if (endDate != null) 'endDate': endDate,
              },
            );
      } else {
        // Use query parameters when no specific employeeId
        uri = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.attendance}')
            .replace(
              queryParameters: {
                'limit': limit.toString(),
                'page': page.toString(),
                if (tenantId != null) 'tenantId': tenantId.toString(),
                if (startDate != null) 'startDate': startDate,
                if (endDate != null) 'endDate': endDate,
              },
            );
      }

      final response = await _client.get(uri, headers: _getHeaders());

      final responseData = _handleResponse(response);
      return AttendanceResponse.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to fetch attendance list: $e');
    }
  }

  // Attendance APIs - Get today's attendance for employee
  Future<AttendanceResponse> getTodayAttendance(
    int employeeId,
    int tenantId,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.attendance}/$employeeId',
      );

      final response = await _client.get(uri, headers: _getHeaders());

      final responseData = _handleResponse(response);
      return AttendanceResponse.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to fetch today\'s attendance: $e');
    }
  }

  // Attendance APIs - Get employee punching details
  Future<EmployeePunchingDetailsResponse> getEmployeePunchingDetails(
    int employeeId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.getEmployeePunchingDetails(employeeId)}',
      );
      final response = await _client.get(url, headers: _getHeaders());

      final responseData = _handleResponse(response);
      return EmployeePunchingDetailsResponse.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to fetch employee punching details: $e');
    }
  }

  // Attendance APIs - Update attendance
  Future<Map<String, dynamic>> updateAttendance(
    AttendanceUpdatePayload payload,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.attendance}',
      );
      final response = await _client.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(payload.toJson()),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Failed to update attendance: $e');
    }
  }

  // Dashboard APIs
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.dashboard}');
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
