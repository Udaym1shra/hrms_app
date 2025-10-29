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
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/stat_item.dart';
import '../../widgets/common/detail_row.dart';
import '../../widgets/common/info_row.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/attendance/attendance_log_item.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= AppValues.mobileBreakpoint;

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
                  Image.asset(
                    AppConstants.companyLogoAsset,
                    height: iconSize + (isMobile ? 6 : 8),
                    fit: BoxFit.contain,
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
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total Days',
            value: '30',
            icon: Icons.calendar_today_rounded,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: StatCard(
            title: 'Present',
            value: '28',
            icon: Icons.check_circle_rounded,
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: StatCard(
            title: 'Leaves',
            value: '2',
            icon: Icons.event_busy_rounded,
            color: AppTheme.warningColor,
          ),
        ),
      ],
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
              return Center(child: Text(AppStrings.noDataFound));
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
      // Error getting today attendance
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
                          AppStrings.attendanceStatus,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppStrings.date}: $attendanceDate',
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
                    child: StatusBadge(status: status, color: statusColor),
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
                      child: StatItem(
                        label: AppStrings.productionHours,
                        value: '${productionHour.toStringAsFixed(1)} hrs',
                        icon: Icons.access_time_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: StatItem(
                        label: AppStrings.earlyComing,
                        value:
                            '${attendanceData['earlyComingMinutes'] ?? 0} ${AppStrings.minutes}',
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.successColor,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: StatItem(
                        label: AppStrings.lateComing,
                        value:
                            '${attendanceData['lateComingMinutes'] ?? 0} ${AppStrings.minutes}',
                        icon: Icons.trending_down_rounded,
                        color: AppTheme.warningColor,
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
                    AppStrings.quickAction,
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
                        '${AppStrings.lastPunch}: $lastPunchType at ${lastLog['date']}',
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
                    AppStrings.attendanceDetails,
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
                    DetailRow(
                      label: AppStrings.punchInTime,
                      value: punchInTime ?? AppStrings.notAvailable,
                      icon: Icons.login_rounded,
                    ),
                    const Divider(height: AppDimensions.spacingL),
                    DetailRow(
                      label: AppStrings.punchOutTime,
                      value: punchOutTime ?? AppStrings.notAvailable,
                      icon: Icons.logout_rounded,
                    ),
                    const Divider(height: AppDimensions.spacingL),
                    DetailRow(
                      label: AppStrings.earlyDeparture,
                      value: '$earlyDepartureMinutes ${AppStrings.minutes}',
                      icon: Icons.trending_up_rounded,
                    ),
                    const Divider(height: AppDimensions.spacingL),
                    DetailRow(
                      label: AppStrings.lateDeparture,
                      value: '$lateDepartureMinutes ${AppStrings.minutes}',
                      icon: Icons.trending_down_rounded,
                    ),
                    if (attendanceData['remark'] != null) ...[
                      const Divider(height: AppDimensions.spacingL),
                      DetailRow(
                        label: AppStrings.remark,
                        value: attendanceData['remark'],
                        icon: Icons.note_rounded,
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
                AppStrings.noAttendanceLogs,
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
                    AppStrings.attendanceLogs,
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
                      '${attendanceLogs.length} ${AppStrings.entries}',
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
                    bottom: index < attendanceLogs.length - 1
                        ? AppDimensions.spacingM
                        : 0,
                  ),
                  child: AttendanceLogItem(
                    log: log as Map<String, dynamic>,
                    index: index + 1,
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
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
                          AppStrings.personalInfo,
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
                          InfoRow(
                            label: AppStrings.name,
                            value: employeeProvider.employee!.fullName,
                            icon: Icons.person_outline_rounded,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.employeeCode,
                            value: employeeProvider.employee!.empCode,
                            icon: Icons.badge_outlined,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.emailLabel,
                            value: employeeProvider.employee!.email,
                            icon: Icons.email_outlined,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.mobileLabel,
                            value:
                                employeeProvider.employee!.mobile ??
                                AppStrings.notAvailable,
                            icon: Icons.phone_outlined,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.department,
                            value:
                                employeeProvider
                                    .employee!
                                    .departmentModel
                                    ?.name ??
                                AppStrings.notAvailable,
                            icon: Icons.business_outlined,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.designation,
                            value:
                                employeeProvider
                                    .employee!
                                    .designationModel
                                    ?.name ??
                                AppStrings.notAvailable,
                            icon: Icons.work_outline_rounded,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.joinDateLabel,
                            value:
                                employeeProvider.employee!.joinDate ??
                                AppStrings.notAvailable,
                            icon: Icons.calendar_today_outlined,
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
