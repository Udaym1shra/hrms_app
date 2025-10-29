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
      // Debug fetch
      // ignore: avoid_print
      print('🔄 Fetching employee by id: $employeeId');
      final response = await _apiService.getEmployeeById(employeeId);
      // ignore: avoid_print
      print(
        '📥 Employee API response error=${response.error}, message=${response.message}',
      );

      if (response.error) {
        _error = response.message;
      } else {
        _employee = response.content?.result?.data;
        // ignore: avoid_print
        print(
          '✅ Parsed employee: id=${_employee?.id}, name=${_employee?.fullName}',
        );
      }
    } catch (e) {
      _error = e.toString();
      // ignore: avoid_print
      print('❌ fetchEmployeeById error: $e');
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
        // Extract employees from the response
        final result = response.content?.result;
        if (result?.data != null) {
          // If it's a single employee, return it as a list
          return [result!.data!];
        } else if (result?.pagination != null) {
          // If it's a paginated list, extract the data array
          final data = result!.pagination!['data'];
          if (data is List) {
            return data.map((e) => Employee.fromJson(e)).toList();
          }
        }
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
