import 'package:flutter/foundation.dart';
import '../models/employee_models.dart';
import '../services/api_service.dart';

class EmployeeProvider with ChangeNotifier {
  final ApiService _apiService;

  Employee? _employee;
  bool _isLoading = false;
  String? _error;

  EmployeeProvider(this._apiService);

  // Expose ApiService for widgets that need it
  ApiService get apiService => _apiService;

  // Getters
  Employee? get employee => _employee;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch employee by ID
  Future<void> fetchEmployeeById(int employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getEmployeeById(employeeId);

      if (response.error) {
        _error = response.message;
      } else {
        _employee = response.content?.result?.data;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch employees list
  Future<List<Employee>> fetchEmployees({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getEmployees(
        limit: limit,
        page: page,
        searchQuery: searchQuery,
        status: status,
        departmentIds: departmentIds,
        order: order,
        tenantIds: tenantIds,
        name: name,
        employeeIds: employeeIds,
        reportingManagerId: reportingManagerId,
        roleId: roleId,
        designationIds: designationIds,
        branchId: branchId,
        isbulk: isbulk,
        employeeType: employeeType,
      );

      if (response.error) {
        _error = response.message;
        return [];
      } else {
        // Assuming the response contains a list of employees
        // You may need to adjust this based on your actual API response structure
        return [];
      }
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear employee data
  void clearEmployee() {
    _employee = null;
    notifyListeners();
  }
}
