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

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;
  late GeofenceService _geofenceService;
  bool _isInsideGeofence = false;
  bool _isGeofencingSupported = false;

  @override
  void initState() {
    super.initState();
    _geofenceService = GeofenceService();
    _initializeServices();
    _loadEmployeeData();
    _initializeGeofencing();
  }

  @override
  void dispose() {
    _geofenceService.dispose();
    super.dispose();
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
        _geofenceService.isInsideGeofence.listen((isInside) {
          if (mounted) {
            setState(() {
              _isInsideGeofence = isInside;
            });
          }
        });

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
                apiService: Provider.of<EmployeeProvider>(
                  context,
                  listen: false,
                ).apiService,
              );
            },
          ),

          const SizedBox(height: 24),

          // Geofence Status Card
          _buildGeofenceStatusCard(),

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

  Widget _buildGeofenceStatusCard() {
    if (!_isGeofencingSupported) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.location_off, color: AppTheme.warningColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Geofencing Not Supported',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningColor,
                      ),
                    ),
                    Text(
                      'This device does not support geofencing features.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
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

    final geofence = _geofenceService.getCurrentGeofence();
    if (geofence == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.location_searching,
                color: AppTheme.textSecondary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Geofence Configured',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      'Contact your administrator to set up geofencing.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isInsideGeofence ? Icons.location_on : Icons.location_off,
                  color: AppTheme.getGeofenceStatusColor(_isInsideGeofence),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Geofence Status',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _isInsideGeofence
                            ? 'Inside Office Area'
                            : 'Outside Office Area',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.getGeofenceStatusColor(
                            _isInsideGeofence,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () => _showGeofenceSetupDialog(),
                      tooltip: 'Setup Geofence',
                    ),
                    IconButton(
                      icon: Icon(Icons.info_outline),
                      onPressed: () =>
                          _geofenceService.showGeofenceStatusDialog(context),
                      tooltip: 'Geofence Info',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildGeofenceInfo(
                    'Location',
                    geofence['name'] ?? 'Office',
                    Icons.business,
                  ),
                ),
                Expanded(
                  child: _buildGeofenceInfo(
                    'Radius',
                    '${geofence['radius']?.toStringAsFixed(0) ?? '100'}m',
                    Icons.radio_button_unchecked,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofenceInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
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
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'absent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'late':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
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
                      Text(
                        'Date: $attendanceDate',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Production Hours',
                    '${productionHour.toStringAsFixed(1)} hrs',
                    Icons.access_time,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Early Coming',
                    '${attendanceData['earlyComingMinutes'] ?? 0} min',
                    Icons.schedule,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Late Coming',
                    '${attendanceData['lateComingMinutes'] ?? 0} min',
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
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
    final buttonColor = nextAction == 'PunchIn' ? Colors.green : Colors.red;
    final buttonIcon = nextAction == 'PunchIn' ? Icons.login : Icons.logout;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Quick Action',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => _handlePunchAction(nextAction, attendanceData),
                icon: Icon(buttonIcon, size: 24),
                label: Text(
                  nextAction,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (lastLog != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last Action: ${lastPunchType} at ${lastLog['date']}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attendance Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Punch In Time', punchInTime ?? 'Not Available'),
            _buildDetailRow('Punch Out Time', punchOutTime ?? 'Not Available'),
            _buildDetailRow(
              'Early Departure',
              '$earlyDepartureMinutes minutes',
            ),
            _buildDetailRow('Late Departure', '$lateDepartureMinutes minutes'),
            if (attendanceData['remark'] != null)
              _buildDetailRow('Remark', attendanceData['remark']),
          ],
        ),
      ),
    );
  }

  // Build detail row widget
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // Build attendance logs card
  Widget _buildAttendanceLogsCard(Map<String, dynamic> attendanceData) {
    final attendanceLogs =
        attendanceData['attendanceLogsId'] as List<dynamic>? ?? [];

    if (attendanceLogs.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No attendance logs available',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Attendance Logs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${attendanceLogs.length} entries',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...attendanceLogs.asMap().entries.map((entry) {
              final index = entry.key;
              final log = entry.value;
              return _buildLogItem(log, index + 1);
            }).toList(),
          ],
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

    final punchColor = punchType == 'PunchIn' ? Colors.green : Colors.red;
    final punchIcon = punchType == 'PunchIn' ? Icons.login : Icons.logout;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: punchColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: punchColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(punchIcon, color: punchColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#$index $punchType',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: punchColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      recordType,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Location: $lat, $lon',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
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

  void _showGeofenceSetupDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final TextEditingController latController = TextEditingController(
      text: '12.9716',
    );
    final TextEditingController lonController = TextEditingController(
      text: '77.5946',
    );
    final TextEditingController radiusController = TextEditingController(
      text: '100',
    );
    final TextEditingController nameController = TextEditingController(
      text: 'Office Location',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Geofence'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: latController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lonController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: radiusController,
                decoration: const InputDecoration(
                  labelText: 'Radius (meters)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final latitude = double.parse(latController.text);
                final longitude = double.parse(lonController.text);
                final radius = double.parse(radiusController.text);
                final name = nameController.text;

                // Get tenantId using the improved method
                final tenantId = await SessionStorage.getTenantId();
                print('Using tenantId for custom geofence: $tenantId');

                final success = await _geofenceService.setupCustomGeofence(
                  employeeId: authProvider.user?.employeeId ?? 0,
                  tenantId: tenantId ?? 0,
                  latitude: latitude,
                  longitude: longitude,
                  radius: radius,
                  name: name,
                );

                Navigator.of(context).pop();

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Geofence setup successful!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to setup geofence'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid input: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Setup'),
          ),
        ],
      ),
    );
  }
}
