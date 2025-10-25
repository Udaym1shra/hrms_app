import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../errors/failures.dart';
import 'api_endpoints.dart';

// HTTP API client
class ApiClient {
  static const String baseUrl = AppConstants.baseUrl;
  late final http.Client _client;
  String? _authToken;

  ApiClient() {
    _client = http.Client();
  }

  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  // Get headers with authentication
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }

  // Handle API response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw const AuthFailure(message: 'Unauthorized - Please login again');
    } else if (response.statusCode == 400) {
      // Handle bad request - return the response data for detailed error handling
      return jsonDecode(response.body);
    } else if (response.statusCode >= 500) {
      throw const ServerFailure(message: 'Server error. Please try again later.');
    } else {
      throw NetworkFailure(
        message: 'HTTP ${response.statusCode}: ${response.body}',
        code: response.statusCode,
      );
    }
  }

  // GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters,
      );

      final response = await _client.get(
        uri,
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(message: 'Network error: $e');
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters,
      );

      final response = await _client.post(
        uri,
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(message: 'Network error: $e');
    }
  }

  // PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters,
      );

      final response = await _client.put(
        uri,
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(message: 'Network error: $e');
    }
  }

  // DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters,
      );

      final response = await _client.delete(
        uri,
        headers: _getHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(message: 'Network error: $e');
    }
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters,
      );

      final response = await _client.patch(
        uri,
        headers: _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure(message: 'Network error: $e');
    }
  }

  // Dispose client
  void dispose() {
    _client.close();
  }
}
