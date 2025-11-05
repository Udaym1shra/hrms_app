import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee_models.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// Employee State
class EmployeeState {
  final Employee? employee;
  final bool isLoading;
  final String? error;

  EmployeeState({this.employee, this.isLoading = false, this.error});

  EmployeeState copyWith({Employee? employee, bool? isLoading, String? error}) {
    return EmployeeState(
      employee: employee ?? this.employee,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Employee State Notifier
class EmployeeNotifier extends StateNotifier<EmployeeState> {
  final ApiService _apiService;

  EmployeeNotifier(this._apiService) : super(EmployeeState());

  // Expose ApiService for widgets that need it
  ApiService get apiService => _apiService;

  // Getters
  Employee? get employee => state.employee;
  bool get isLoading => state.isLoading;
  String? get error => state.error;

  // Fetch employee by ID
  Future<void> fetchEmployeeById(int employeeId) async {
    state = state.copyWith(isLoading: true, error: null);

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
        state = state.copyWith(error: response.message, isLoading: false);
      } else {
        final employee = response.content?.result?.data;
        // ignore: avoid_print
        print(
          '✅ Parsed employee: id=${employee?.id}, name=${employee?.fullName}',
        );
        state = state.copyWith(employee: employee, isLoading: false);
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ fetchEmployeeById error: $e');
      state = state.copyWith(error: e.toString(), isLoading: false);
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
    state = state.copyWith(isLoading: true, error: null);

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
        state = state.copyWith(error: response.message, isLoading: false);
        return [];
      } else {
        // Extract employees from the response
        final result = response.content?.result;
        List<Employee> employees = [];

        if (result?.data != null) {
          // If it's a single employee, return it as a list
          employees = [result!.data!];
        } else if (result?.pagination != null) {
          // If it's a paginated list, extract the data array
          final data = result!.pagination!['data'];
          if (data is List) {
            employees = data.map((e) => Employee.fromJson(e)).toList();
          }
        }

        state = state.copyWith(isLoading: false);
        return employees;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return [];
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear employee data
  void clearEmployee() {
    state = state.copyWith(employee: null);
  }
}

// Employee Provider
final employeeProvider = StateNotifierProvider<EmployeeNotifier, EmployeeState>(
  (ref) {
    final apiService = ref.watch(apiServiceProvider);
    return EmployeeNotifier(apiService);
  },
);
