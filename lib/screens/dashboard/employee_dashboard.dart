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
  bool _hasLoggedEmployee = false; // one-time employee data log

  @override
  void initState() {
    super.initState();

    // Initialize sidebar animation controller FIRST (synchronously)
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    // After first frame, attach a listener to log employee data once when loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final employeeProvider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );
      employeeProvider.addListener(_logEmployeeOnce);
      _ensureEmployeeLoaded();
      // Also watch AuthProvider to fetch once user becomes available
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.addListener(_ensureEmployeeLoaded);
    });
  }

  @override
  void dispose() {
    // Remove listener if provider is available
    try {
      final employeeProvider = Provider.of<EmployeeProvider>(
        context,
        listen: false,
      );
      employeeProvider.removeListener(_logEmployeeOnce);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.removeListener(_ensureEmployeeLoaded);
    } catch (_) {
      // ignore: avoid_print
      print('Employee provider not available during dispose');
    }
    _geofenceService.dispose();
    if (_sidebarController.isAnimating || _sidebarController.isCompleted) {
      _sidebarController.stop();
    }
    _sidebarController.dispose();
    super.dispose();
  }

  // One-time logger for employee data once it's available
  void _logEmployeeOnce() {
    final employeeProvider = Provider.of<EmployeeProvider>(
      context,
      listen: false,
    );
    if (!_hasLoggedEmployee && employeeProvider.employee != null) {
      final e = employeeProvider.employee!;
      _hasLoggedEmployee = true;
      // ignore: avoid_print
      print(
        'Employee Loaded: '
        '{id: ${e.id}, '
        'name: ${e.fullName}, '
        'email: ${e.email}, '
        'empCode: ${e.empCode}, '
        'department: ${e.departmentModel?.name}, '
        'designation: ${e.designationModel?.name}}',
      );
    }
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
          print('Using tenantId from SessionStorage: $tenantId');

          await _geofenceService.fetchGeofenceConfigFromServer(
            employeeId: authProvider.user!.employeeId!,
            tenantId: tenantId,
          );
        }
      }
    } catch (e) {
      print('❌ Error initializing geofencing: $e');
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
            print('Failed to decode JWT token: $e');
          }
        }
      }
      if (tenantId == null) {
        tenantId = userData['user']?['companyId'];
      }

      print(
        '🔍 Extracted data - Employee ID: $employeeId, Tenant ID: $tenantId',
      );

      return {'employeeId': employeeId ?? 0, 'tenantId': tenantId ?? 0};
    } catch (e) {
      print('❌ Error getting employee and tenant data: $e');
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
    final isMobile = MediaQuery.of(context).size.width <= 768;

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

              // Mobile Layout without Sidebar in main content
              if (isMobile)
                Column(
                  children: [
                    // Top App Bar
                    _buildAppBar(context, authProvider),

                    // Main Content Area
                    Expanded(child: _buildMainContent(employeeProvider)),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;

    // Responsive padding - reduced to prevent system UI overlap
    final horizontalPadding = isMobile ? 12.0 : 20.0;
    final verticalPadding = isMobile ? 8.0 : 12.0;

    // Responsive icon sizes
    final iconSize = isMobile ? 18.0 : 24.0;
    final menuIconSize = isMobile ? 20.0 : 24.0;

    // Responsive spacing
    final spacing = isMobile ? 8.0 : 16.0;
    final titleSpacing = isMobile ? 8.0 : 12.0;

    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Menu Button - Hamburger icon
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: AppTheme.primaryColor,
                  size: menuIconSize,
                ),
                onPressed: _toggleSidebar,
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 36 : 48,
                  minHeight: isMobile ? 36 : 48,
                ),
              ),
            ),

            SizedBox(width: spacing),

            // Title with icon
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.dashboard_rounded,
                      color: Colors.white,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: titleSpacing),
                  Flexible(
                    child: Text(
                      _getPageTitle(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.5,
                            fontSize: isMobile ? 16 : 20,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    print('Employee Provider: ${employeeProvider}');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card or loading/error placeholder
          if (employeeProvider.employee != null) ...[
            // Log employee data to console safely during build
            Builder(
              builder: (_) {
                final e = employeeProvider.employee!;
                // ignore: avoid_print
                print(
                  'Employee Provider: '
                  '{id: ${e.id}, '
                  'name: ${e.fullName}, '
                  'email: ${e.email}, '
                  'empCode: ${e.empCode}, '
                  'department: ${e.departmentModel?.name}, '
                  'designation: ${e.designationModel?.name}}',
                );
                return const SizedBox.shrink();
              },
            ),
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
                      const SizedBox(width: 12),
                      const Text('Loading employee...'),
                    ] else ...[
                      const Icon(Icons.info_outline, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          employeeProvider.error ?? 'Employee not loaded',
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
                        'Error loading geofence data: ${snapshot.error}',
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

              print(
                '🔍 Final values - Employee ID: $employeeId, Tenant ID: $tenantId',
              );

              if (employeeId == 0) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Employee ID not available',
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
            Icons.calendar_today_rounded,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Present',
            '28',
            Icons.check_circle_rounded,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Leaves',
            '2',
            Icons.event_busy_rounded,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.05), color.withOpacity(0.02)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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
              return const Center(child: Text('No attendance data available'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attendance Status Card
                  _buildAttendanceStatusCard(attendanceData),
                  const SizedBox(height: 16),

                  // Punch In/Out Button
                  _buildPunchButton(attendanceData),
                  const SizedBox(height: 16),

                  // Attendance Details Card
                  _buildAttendanceDetailsCard(attendanceData),
                  const SizedBox(height: 16),

                  // Attendance Logs Card
                  _buildAttendanceLogsCard(attendanceData),
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
      print('Error getting today attendance: $e');
      return null;
    }
  }

  // Build attendance status card
  Widget _buildAttendanceStatusCard(Map<String, dynamic> attendanceData) {
    final status = attendanceData['status'] ?? 'Unknown';
    final attendanceDate = attendanceData['attendanceDate'] ?? 'N/A';
    final productionHour = attendanceData['productionHour'] ?? 0;

    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'present':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'absent':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'late':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.schedule_rounded;
        break;
      default:
        statusColor = AppTheme.textSecondary;
        statusIcon = Icons.help_outline_rounded;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [statusColor.withOpacity(0.05), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Status',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: $attendanceDate',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Production Hours',
                        '${productionHour.toStringAsFixed(1)} hrs',
                        Icons.access_time_rounded,
                        AppTheme.primaryColor,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: _buildStatItem(
                        'Early Coming',
                        '${attendanceData['earlyComingMinutes'] ?? 0} min',
                        Icons.trending_up_rounded,
                        AppTheme.successColor,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: _buildStatItem(
                        'Late Coming',
                        '${attendanceData['lateComingMinutes'] ?? 0} min',
                        Icons.trending_down_rounded,
                        AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build stat item widget
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Build punch button
  Widget _buildPunchButton(Map<String, dynamic> attendanceData) {
    final attendanceLogs =
        attendanceData['attendanceLogsId'] as List<dynamic>? ?? [];
    final lastLog = attendanceLogs.isNotEmpty ? attendanceLogs.last : null;
    final lastPunchType = lastLog?['punchType'] ?? 'PunchOut';

    // Determine next action
    final nextAction = lastPunchType == 'PunchIn' ? 'PunchOut' : 'PunchIn';
    final buttonColor = nextAction == 'PunchIn'
        ? AppTheme.successColor
        : AppTheme.errorColor;
    final buttonIcon = nextAction == 'PunchIn'
        ? Icons.login_rounded
        : Icons.logout_rounded;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [buttonColor.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: buttonColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.flash_on_rounded,
                      color: buttonColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Action',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _handlePunchAction(nextAction, attendanceData),
                  icon: Icon(buttonIcon, size: 24),
                  label: Text(
                    nextAction,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: buttonColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (lastLog != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last: ${lastPunchType} at ${lastLog['date']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

  // Build attendance details card
  Widget _buildAttendanceDetailsCard(Map<String, dynamic> attendanceData) {
    final punchInTime = attendanceData['punchInTime'];
    final punchOutTime = attendanceData['punchOutTime'];
    final earlyDepartureMinutes = attendanceData['earlyDepartureMinutes'] ?? 0;
    final lateDepartureMinutes = attendanceData['lateDepartureMinutes'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor.withOpacity(0.05), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Attendance Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Punch In Time',
                      punchInTime ?? 'Not Available',
                      Icons.login_rounded,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Punch Out Time',
                      punchOutTime ?? 'Not Available',
                      Icons.logout_rounded,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Early Departure',
                      '$earlyDepartureMinutes minutes',
                      Icons.trending_up_rounded,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Late Departure',
                      '$lateDepartureMinutes minutes',
                      Icons.trending_down_rounded,
                    ),
                    if (attendanceData['remark'] != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Remark',
                        attendanceData['remark'],
                        Icons.note_rounded,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build detail row widget
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Build attendance logs card
  Widget _buildAttendanceLogsCard(Map<String, dynamic> attendanceData) {
    final attendanceLogs =
        attendanceData['attendanceLogsId'] as List<dynamic>? ?? [];

    if (attendanceLogs.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.backgroundColor, Colors.white],
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 48,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No attendance logs available',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor.withOpacity(0.05), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Attendance Logs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${attendanceLogs.length} entries',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...attendanceLogs.asMap().entries.map((entry) {
                final index = entry.key;
                final log = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < attendanceLogs.length - 1 ? 12 : 0,
                  ),
                  child: _buildLogItem(log, index + 1),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // Build individual log item
  Widget _buildLogItem(Map<String, dynamic> log, int index) {
    final punchType = log['punchType'] ?? 'Unknown';
    final date = log['date'] ?? 'N/A';
    final recordType = log['recordType'] ?? 'Manual';
    final lat = log['lat'] ?? 'N/A';
    final lon = log['lon'] ?? 'N/A';

    final punchColor = punchType == 'PunchIn'
        ? AppTheme.successColor
        : AppTheme.errorColor;
    final punchIcon = punchType == 'PunchIn'
        ? Icons.login_rounded
        : Icons.logout_rounded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: punchColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: punchColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  punchColor.withOpacity(0.2),
                  punchColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(punchIcon, color: punchColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: punchColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$index $punchType',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: punchColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        recordType,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$lat, $lon',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeavesContent() {
    return const Center(child: Text('Leave Management - Coming Soon'));
  }

  Widget _buildProfileContent(EmployeeProvider employeeProvider) {
    if (employeeProvider.employee == null) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Personal Information',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            'Name',
                            employeeProvider.employee!.fullName,
                            Icons.person_outline_rounded,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Employee Code',
                            employeeProvider.employee!.empCode,
                            Icons.badge_outlined,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Email',
                            employeeProvider.employee!.email,
                            Icons.email_outlined,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Mobile',
                            employeeProvider.employee!.mobile ?? 'N/A',
                            Icons.phone_outlined,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Department',
                            employeeProvider.employee!.departmentModel?.name ??
                                'N/A',
                            Icons.business_outlined,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Designation',
                            employeeProvider.employee!.designationModel?.name ??
                                'N/A',
                            Icons.work_outline_rounded,
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(
                            'Join Date',
                            employeeProvider.employee!.joinDate ?? 'N/A',
                            Icons.calendar_today_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
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
    });
    // Close sidebar on mobile after selection
    if (MediaQuery.of(context).size.width <= 768) {
      _closeSidebar();
    }
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
