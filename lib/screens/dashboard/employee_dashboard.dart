import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/session_storage.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/profile_card.dart';
import '../../widgets/punch_in_out_widget.dart';
import '../../widgets/geofence_map_widget.dart';
import '../../widgets/attendance/attendance_status_card.dart';
import '../../widgets/attendance/punch_button_widget.dart';
import '../../widgets/attendance/attendance_details_card.dart';
import '../../widgets/attendance/attendance_logs_card.dart';
import '../../widgets/dashboard/quick_stats_widget.dart';
import '../../widgets/geofence/location_table.dart';
import '../../widgets/dashboard/dashboard_app_bar.dart';
import '../../widgets/profile/profile_content_widget.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_values.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_constants.dart';
import '../../services/geofence_service.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;
  late GeofenceService _geofenceService;
  bool _isGeofencingSupported = false;
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize sidebar animation controller FIRST (synchronously)
    _sidebarController = AnimationController(
      duration: Duration(
        milliseconds: AppValues.sidebarAnimationDuration.toInt(),
      ),
      vsync: this,
    );
    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeInOut,
    );

    // Then initialize other services
    _geofenceService = GeofenceService();
    _initializeServices();
    _loadEmployeeData();
    _initializeGeofencing();
  }

  @override
  void dispose() {
    // Remove listener if provider is available
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.removeListener(_ensureEmployeeLoaded);
    } catch (_) {
      // Employee provider not available during dispose
    }
    _geofenceService.dispose();
    if (_sidebarController.isAnimating || _sidebarController.isCompleted) {
      _sidebarController.stop();
    }
    _sidebarController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    final wasOpen = _isSidebarOpen;
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });

    if (_isSidebarOpen && !wasOpen) {
      _sidebarController.forward();
    } else if (!_isSidebarOpen && wasOpen) {
      _sidebarController.reverse();
    }
  }

  void _closeSidebar() {
    if (_isSidebarOpen) {
      setState(() {
        _isSidebarOpen = false;
      });
      _sidebarController.reverse();
    }
  }

  void _initializeServices() {
    // Services are already initialized in main.dart and provided via Provider
    // We can access them through the providers
  }

  Future<void> _initializeGeofencing() async {
    try {
      // Check if geofencing is supported
      _isGeofencingSupported = await _geofenceService.isGeofencingSupported();

      if (_isGeofencingSupported) {
        // Initialize geofence service
        await _geofenceService.initialize();

        // Set API service
        final employeeProvider = Provider.of<EmployeeProvider>(
          context,
          listen: false,
        );
        _geofenceService.setApiService(employeeProvider.apiService);

        // Listen to geofence status changes

        // Load geofence configuration for the employee
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.user?.employeeId != null) {
          // Get tenantId using the improved method
          final tenantId = await SessionStorage.getTenantId();

          await _geofenceService.fetchGeofenceConfigFromServer(
            employeeId: authProvider.user!.employeeId!,
            tenantId: tenantId,
          );
        }
      }
    } catch (e) {
      // Error initializing geofencing
    }
  }

  // Get employee and tenant data from session storage
  Future<Map<String, dynamic>> _getEmployeeAndTenantData() async {
    try {
      final userData = await SessionStorage.getUserData();
      if (userData == null) {
        return {'employeeId': 0, 'tenantId': 0};
      }

      // Extract employeeId from user data
      int? employeeId = userData['user']?['employeeId'];

      // Extract tenantId using the improved method
      int? tenantId = userData['user']?['tenantId'];
      if (tenantId == null) {
        tenantId = userData['user']?['branch']?['tenantId'];
      }
      if (tenantId == null) {
        tenantId = userData['user']?['tenant']?['id'];
      }
      if (tenantId == null) {
        // Try to get tenantId from JWT token
        final token = userData['token'];
        if (token != null) {
          try {
            final parts = token.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final padding = ((4 - payload.length % 4) % 4).toInt();
              final padded = payload + '=' * padding;
              final decoded = utf8.decode(base64.decode(padded));
              final payloadMap = jsonDecode(decoded);

              tenantId =
                  payloadMap['companyId'] ??
                  payloadMap['tenantId'] ??
                  payloadMap['tenant_id'] ??
                  payloadMap['company_id'];
            }
          } catch (e) {
            // Failed to decode JWT token
          }
        }
      }
      if (tenantId == null) {
        tenantId = userData['user']?['companyId'];
      }

      return {'employeeId': employeeId ?? 0, 'tenantId': tenantId ?? 0};
    } catch (e) {
      // Error getting employee and tenant data
      return {'employeeId': 0, 'tenantId': 0};
    }
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

  // Ensure employee data is fetched when auth user becomes available
  void _ensureEmployeeLoaded() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final employeeProvider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );
      if (employeeProvider.employee == null &&
          authProvider.user?.employeeId != null &&
          !employeeProvider.isLoading) {
        employeeProvider.fetchEmployeeById(authProvider.user!.employeeId!);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width <= AppValues.mobileBreakpoint;

    return Consumer2<AuthProvider, EmployeeProvider>(
      builder: (context, authProvider, employeeProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Stack(
            children: [
              // Desktop Layout with Sidebar
              if (!isMobile)
                Row(
                  children: [
                    // Desktop Sidebar (permanent)
                    Sidebar(
                      user: authProvider.user,
                      selectedIndex: _selectedIndex,
                      onItemSelected: _onSidebarItemSelected,
                      onLogout: _handleLogout,
                      onClose: null,
                    ),

                    // Main Content
                    Expanded(
                      child: SafeArea(
                        top: false,
                        child: Column(
                          children: [
                            // Top App Bar
                            _buildAppBar(context, authProvider),

                            // Main Content Area
                            Expanded(
                              child: _buildMainContent(employeeProvider),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              // Mobile Layout without Sidebar in main content
              if (isMobile)
                Column(
                  children: [
                    // Top App Bar
                    _buildAppBar(context, authProvider),

                    // Main Content Area
                    Expanded(
                      child: SafeArea(
                        top: false,
                        child: _buildMainContent(employeeProvider),
                      ),
                    ),
                  ],
                ),

              // Mobile backdrop overlay with animation
              if (isMobile && _isSidebarOpen)
                FadeTransition(
                  opacity: _sidebarAnimation,
                  child: GestureDetector(
                    onTap: _closeSidebar,
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

              // Mobile Sidebar (slides in from left)
              if (isMobile)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1.0, 0.0),
                      end: Offset.zero,
                    ).animate(_sidebarAnimation),
                    child: IgnorePointer(
                      ignoring: !_isSidebarOpen,
                      child: Sidebar(
                        user: authProvider.user,
                        selectedIndex: _selectedIndex,
                        onItemSelected: _onSidebarItemSelected,
                        onLogout: _handleLogout,
                        onClose: _closeSidebar,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, AuthProvider authProvider) {
    return DashboardAppBar(
      title: _getPageTitle(),
      onMenuPressed: _toggleSidebar,
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
          // Profile Card or loading/error placeholder
          if (employeeProvider.employee != null) ...[
            ProfileCard(employee: employeeProvider.employee!),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (employeeProvider.isLoading) ...[
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppDimensions.spacingM),
                      const Text(AppStrings.loadingEmployee),
                    ] else ...[
                      const Icon(Icons.info_outline, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          employeeProvider.error ??
                              AppStrings.employeeNotLoaded,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final auth = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          if (auth.user?.employeeId != null) {
                            employeeProvider.fetchEmployeeById(
                              auth.user!.employeeId!,
                            );
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Punch In/Out Widget
          Consumer<EmployeeProvider>(
            builder: (context, employeeProvider, child) {
              return PunchInOutWidget(
                apiService: Provider.of<EmployeeProvider>(
                  context,
                  listen: false,
                ).apiService,
              );
            },
          ),

          const SizedBox(height: 24),

          // Geofence Map
          FutureBuilder<Map<String, dynamic>>(
            future: _getEmployeeAndTenantData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        '${AppStrings.failedToLoadGeofenceConfig}: ${snapshot.error}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final data = snapshot.data ?? {};
              final employeeId = data['employeeId'] ?? 0;
              final tenantId = data['tenantId'] ?? 0;

              if (employeeId == 0) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        AppStrings.noDataFound,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Consumer<EmployeeProvider>(
                builder: (context, employeeProvider, child) {
                  return GeofenceMapWidget(
                    employeeId: employeeId,
                    tenantId: tenantId,
                    apiService: employeeProvider.apiService,
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick Stats
          const QuickStatsWidget(),

          const SizedBox(height: 24),

          // Today's Location List
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getTodayLocationList(employeeProvider),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Failed to load today\'s locations: ${snapshot.error}',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                );
              }
              final locations = snapshot.data ?? const <Map<String, dynamic>>[];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Today\'s Location Records',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  LocationTable(locations: locations),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getTodayLocationList(
    EmployeeProvider employeeProvider,
  ) async {
    try {
      final userData = await SessionStorage.getUserData();
      if (userData == null) return [];

      final employeeId = userData['user']?['employeeId'];
      if (employeeId == null) return [];

      final now = DateTime.now();
      final date =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final resp = await employeeProvider.apiService.getEmployeeLocationList(
        employeeId: employeeId,
        date: date,
        limit: 100,
        page: 1,
      );

      // Expecting response like { error: false, content: { result: { data: [...] } } }
      final content = resp['content'];
      if (content == null) return [];
      final result = content['result'];
      if (result == null) return [];
      final data = result['data'];
      if (data is List) {
        // Normalize to List<Map<String, dynamic>>
        return data
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .cast<Map<String, dynamic>>()
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Widget _buildAttendanceContent() {
    return Consumer<EmployeeProvider>(
      builder: (context, employeeProvider, child) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _getTodayAttendanceData(employeeProvider),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading attendance: ${snapshot.error}',
                      style: TextStyle(color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Refresh
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final attendanceData = snapshot.data;
            if (attendanceData == null) {
              return Center(child: Text(AppStrings.noDataFound));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attendance Status Card
                  AttendanceStatusCard(attendanceData: attendanceData),
                  const SizedBox(height: 16),

                  // Punch In/Out Button
                  PunchButtonWidget(
                    attendanceData: attendanceData,
                    onPunch: () => _handlePunchAction(
                      _getNextPunchAction(attendanceData),
                      attendanceData,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance Details Card
                  AttendanceDetailsCard(attendanceData: attendanceData),
                  const SizedBox(height: 16),

                  // Attendance Logs Card
                  AttendanceLogsCard(attendanceData: attendanceData),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Get today's attendance data
  Future<Map<String, dynamic>?> _getTodayAttendanceData(
    EmployeeProvider employeeProvider,
  ) async {
    try {
      final userData = await SessionStorage.getUserData();
      if (userData == null) return null;

      final employeeId = userData['user']?['employeeId'];
      final tenantId =
          userData['user']?['tenantId'] ??
          userData['user']?['branch']?['tenantId'] ??
          userData['user']?['tenant']?['id'];

      if (employeeId == null || tenantId == null) return null;

      final response = await employeeProvider.apiService.getTodayAttendance(
        employeeId,
        tenantId,
      );

      return response.toJson();
    } catch (e) {
      // Error getting today attendance
      return null;
    }
  }

  // Get next punch action from attendance data
  String _getNextPunchAction(Map<String, dynamic> attendanceData) {
    final attendanceLogs =
        attendanceData['attendanceLogsId'] as List<dynamic>? ?? [];
    final lastLog = attendanceLogs.isNotEmpty ? attendanceLogs.last : null;
    final lastPunchType = lastLog?['punchType'] ?? 'PunchOut';
    return lastPunchType == 'PunchIn' ? 'PunchOut' : 'PunchIn';
  }

  // Handle punch action
  Future<void> _handlePunchAction(
    String action,
    Map<String, dynamic> attendanceData,
  ) async {
    try {
      final userData = await SessionStorage.getUserData();
      if (userData == null) return;

      final employeeId = userData['user']?['employeeId'];
      if (employeeId == null) return;

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final employeeProvider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );
      Map<String, dynamic> response;

      if (action == 'PunchIn') {
        response = await employeeProvider.apiService.punchIn(
          employeeId: employeeId,
          lat: position.latitude,
          lon: position.longitude,
          dateWithTime: DateTime.now().toIso8601String(),
        );
      } else {
        response = await employeeProvider.apiService.punchOut(
          employeeId: employeeId,
          lat: position.latitude,
          lon: position.longitude,
          dateWithTime: DateTime.now().toIso8601String(),
        );
      }

      if (response['error'] == false) {
        final tenantId = await SessionStorage.getTenantId();

        if (action == 'PunchIn') {
          final employeeProvider = Provider.of<EmployeeProvider>(
            context,
            listen: false,
          );
          _geofenceService.setApiService(employeeProvider.apiService);
          _geofenceService.startAutoLocationUploadForEmployee(
            employeeId: employeeId,
            tenantId: tenantId ?? 0,
          );
        } else if (action == 'PunchOut') {
          _geofenceService.stopAutoLocationUpload();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action} successful!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${action} failed: ${response['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildLeavesContent() {
    return Center(
      child: Text('${AppStrings.leaves} - ${AppStrings.comingSoon}'),
    );
  }

  Widget _buildProfileContent(EmployeeProvider employeeProvider) {
    if (employeeProvider.employee == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    return ProfileContentWidget(employee: employeeProvider.employee!);
  }

  Widget _buildComingSoonContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: AppDimensions.iconXXL,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            AppStrings.comingSoon,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            AppStrings.underDevelopment,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return AppStrings.dashboard;
      case 1:
        return AppStrings.employees;
      case 6:
        return AppStrings.attendance;
      case 7:
        return AppStrings.leaves;
      case 11:
        return AppStrings.myProfile;
      default:
        return AppConstants.appName;
    }
  }

  void _onSidebarItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Close sidebar on mobile after selection
    if (MediaQuery.of(context).size.width <= AppValues.mobileBreakpoint) {
      _closeSidebar();
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
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
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }
}
