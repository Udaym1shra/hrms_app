import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/auth_models.dart';
import '../../models/employee_models.dart';
import '../../utils/app_theme.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/profile_card.dart';
import '../../widgets/punch_in_out_widget.dart';
import '../../widgets/geofence_map_widget.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadEmployeeData();
  }

  void _initializeServices() {
    // Services are already initialized in main.dart and provided via Provider
    // We can access them through the providers
  }

  void _loadEmployeeData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employeeProvider = Provider.of<EmployeeProvider>(
      context,
      listen: false,
    );

    if (authProvider.user?.employeeId != null) {
      employeeProvider.fetchEmployeeById(authProvider.user!.employeeId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, EmployeeProvider>(
      builder: (context, authProvider, employeeProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Row(
            children: [
              // Sidebar
              if (_isSidebarOpen || MediaQuery.of(context).size.width > 768)
                Sidebar(
                  user: authProvider.user,
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onSidebarItemSelected,
                  onLogout: _handleLogout,
                ),

              // Main Content
              Expanded(
                child: Column(
                  children: [
                    // Top App Bar
                    _buildAppBar(context, authProvider),

                    // Main Content Area
                    Expanded(child: _buildMainContent(employeeProvider)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Menu Button
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              setState(() {
                _isSidebarOpen = !_isSidebarOpen;
              });
            },
          ),

          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              _getPageTitle(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

          // User Info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  authProvider.user?.firstName.substring(0, 1).toUpperCase() ??
                      'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    authProvider.user?.fullName ?? 'User',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    authProvider.user?.role?.name ?? 'Employee',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(EmployeeProvider employeeProvider) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent(employeeProvider);
      case 6:
        return _buildAttendanceContent();
      case 7:
        return _buildLeavesContent();
      case 11:
        return _buildProfileContent(employeeProvider);
      default:
        return _buildComingSoonContent();
    }
  }

  Widget _buildDashboardContent(EmployeeProvider employeeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          if (employeeProvider.employee != null)
            ProfileCard(employee: employeeProvider.employee!),

          const SizedBox(height: 24),

          // Punch In/Out Widget
          Consumer<EmployeeProvider>(
            builder: (context, employeeProvider, child) {
              return PunchInOutWidget(
                employeeId: employeeProvider.employee?.id ?? 0,
                tenantId: employeeProvider.employee?.tenantIds ?? 0,
                apiService: Provider.of<EmployeeProvider>(
                  context,
                  listen: false,
                ).apiService,
              );
            },
          ),

          const SizedBox(height: 24),

          // Geofence Map
          Consumer<EmployeeProvider>(
            builder: (context, employeeProvider, child) {
              return GeofenceMapWidget(
                employeeId: employeeProvider.employee?.id ?? 0,
                tenantId: employeeProvider.employee?.tenantIds ?? 0,
                apiService: Provider.of<EmployeeProvider>(
                  context,
                  listen: false,
                ).apiService,
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Days',
            '30',
            Icons.calendar_today,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Present',
            '28',
            Icons.check_circle,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Leaves',
            '2',
            Icons.event_busy,
            AppTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceContent() {
    return const Center(child: Text('Attendance Management - Coming Soon'));
  }

  Widget _buildLeavesContent() {
    return const Center(child: Text('Leave Management - Coming Soon'));
  }

  Widget _buildProfileContent(EmployeeProvider employeeProvider) {
    if (employeeProvider.employee == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Name', employeeProvider.employee!.fullName),
                  _buildInfoRow(
                    'Employee Code',
                    employeeProvider.employee!.empCode,
                  ),
                  _buildInfoRow('Email', employeeProvider.employee!.email),
                  _buildInfoRow(
                    'Mobile',
                    employeeProvider.employee!.mobile ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Department',
                    employeeProvider.employee!.departmentModel?.name ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Designation',
                    employeeProvider.employee!.designationModel?.name ?? 'N/A',
                  ),
                  _buildInfoRow(
                    'Join Date',
                    employeeProvider.employee!.joinDate ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This feature is under development',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Employees';
      case 6:
        return 'Attendance';
      case 7:
        return 'Leaves';
      case 11:
        return 'My Profile';
      default:
        return 'HRMS Mobile';
    }
  }

  void _onSidebarItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
      _isSidebarOpen = false;
    });
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
