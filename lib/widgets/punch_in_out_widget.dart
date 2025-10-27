import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../utils/app_theme.dart';
import '../utils/session_storage.dart';
import '../services/api_service.dart';
import '../services/geofence_service.dart';

class PunchInOutWidget extends StatefulWidget {
  final ApiService apiService;

  const PunchInOutWidget({Key? key, required this.apiService})
    : super(key: key);

  @override
  State<PunchInOutWidget> createState() => _PunchInOutWidgetState();
}

class _PunchInOutWidgetState extends State<PunchInOutWidget> {
  bool _isPunchedIn = false;
  bool _isLoading = false;
  Position? _currentPosition;
  String? _error;
  int? _employeeId;
  int? _tenantId;
  List<Map<String, dynamic>> _attendanceLogs = [];
  bool _showAttendanceLogs = false;
  bool _showMap = false;
  int? _selectedLogIndex;
  Timer? _durationTimer;

  // Geofence service
  final GeofenceService _geofenceService = GeofenceService();
  bool _isInsideGeofence = false;

  @override
  void initState() {
    super.initState();
    _initializeGeofenceService();
    _loadSessionData();
    _checkLocationPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh attendance when widget dependencies change (e.g., on reload)
    if (_employeeId != null && _tenantId != null) {
      _fetchTodayAttendance();
    }
  }

  Future<void> _initializeGeofenceService() async {
    try {
      // Set API service for geofence service
      _geofenceService.setApiService(widget.apiService);

      await _geofenceService.initialize();

      // Listen to geofence events
      _geofenceService.geofenceEvents.listen((event) {
        if (mounted) {
          setState(() {
            _isInsideGeofence = event.type == GeofenceEventType.enter;
          });

          // Show notification for geofence events
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                event.type == GeofenceEventType.enter
                    ? 'You have entered the office area'
                    : 'You have left the office area',
              ),
              backgroundColor: event.type == GeofenceEventType.enter
                  ? AppTheme.successColor
                  : AppTheme.warningColor,
            ),
          );
        }
      });

      // Update geofence status
      _isInsideGeofence = _geofenceService.isInsideGeofenceStatus;

      print('✅ Geofence service initialized in punch widget');
    } catch (e) {
      print('❌ Error initializing geofence service: $e');
    }
  }

  Future<void> _loadSessionData() async {
    try {
      print('=== Loading Session Data ===');
      final sessionData = await useSession();
      print('Session data loaded:');
      print('Employee ID: ${sessionData.employeeId}');
      print('Tenant ID: ${sessionData.tenantId}');
      print('User: ${sessionData.user?.toJson()}');
      print('JWT Token: ${sessionData.jwtToken}');

      setState(() {
        _employeeId = sessionData.employeeId;
        _tenantId = sessionData.tenantId;
      });

      print('Final values - Employee ID: $_employeeId, Tenant ID: $_tenantId');

      // If we have both IDs, fetch today's attendance to determine punch status
      if (_employeeId != null) {
        print('Calling _fetchTodayAttendance from _loadSessionData');
        await _fetchTodayAttendance();

        // Fetch geofence configuration from server
        await _fetchGeofenceConfig();
      }

      print('=== Session Data Loading Complete ===');

      // If still null, show specific error
      if (_employeeId == null || _tenantId == null) {
        setState(() {
          _error =
              'Missing required IDs - Employee: $_employeeId, Tenant: $_tenantId';
        });
      }
    } catch (e) {
      print('Error loading session data: $e');
      setState(() {
        _error = 'Failed to load session data: $e';
      });
    }
  }

  Future<void> _fetchTodayAttendance() async {
    if (_employeeId == null) return;

    try {
      print('Fetching today\'s attendance for employee: $_employeeId');

      // First try to get today's attendance list
      final attendanceResponse = await widget.apiService.getTodayAttendance(
        _employeeId!,
        _tenantId!,
      );

      print('Today\'s attendance response: ${attendanceResponse.toJson()}');

      if (!attendanceResponse.error &&
          attendanceResponse.content.data.isNotEmpty) {
        final todayAttendance = attendanceResponse.content.data.first;

        // Get the attendance ID to fetch detailed logs
        // Note: AttendanceRecord doesn't have an 'id' field directly
        // We'll use the attendance date as identifier or fetch from logs
        print('Processing attendance record for detailed logs');

        // Fetch detailed attendance logs using employee ID and today's date
        final today = DateTime.now().toIso8601String().split(
          'T',
        )[0]; // YYYY-MM-DD format
        await _fetchAttendanceLogsByEmployeeAndDate(today);

        // Check if employee has punched in today
        final hasPunchedIn =
            todayAttendance.punchInTime != null &&
            todayAttendance.punchInTime!.isNotEmpty;
        final hasPunchedOut =
            todayAttendance.punchOutTime != null &&
            todayAttendance.punchOutTime!.isNotEmpty;

        setState(() {
          _isPunchedIn = hasPunchedIn && !hasPunchedOut;
        });

        // Update duration timer based on punch status
        _updateDurationTimer();

        // Update duration timer based on punch status
        _updateDurationTimer();

        print(
          'Punch status - Punched In: $hasPunchedIn, Punched Out: $hasPunchedOut, Current Status: $_isPunchedIn',
        );
      } else {
        // No attendance record for today, employee hasn't punched in
        setState(() {
          _isPunchedIn = false;
        });
        print('No attendance record for today, employee can punch in');
      }
    } catch (e) {
      print('Error fetching today\'s attendance: $e');
      // On error, assume not punched in
      setState(() {
        _isPunchedIn = false;
      });
    }
  }

  Future<void> _fetchGeofenceConfig() async {
    if (_employeeId == null) return;

    try {
      print('🌐 Fetching geofence configuration for employee: $_employeeId');

      final success = await _geofenceService.fetchGeofenceConfigFromServer(
        employeeId: _employeeId!,
        tenantId: _tenantId,
      );

      if (success) {
        print('✅ Geofence configuration loaded successfully');
      } else {
        print('⚠️ No geofence configuration found for this employee');
      }
    } catch (e) {
      print('❌ Error fetching geofence configuration: $e');
    }
  }

  Future<void> _fetchAttendanceLogsByEmployeeAndDate(String date) async {
    if (_employeeId == null) return;

    try {
      print(
        'Fetching attendance logs for employee: $_employeeId on date: $date',
      );
      final attendanceLogs = await widget.apiService
          .getAttendanceLogsByEmployeeAndDate(
            employeeId: _employeeId!,
            date: date,
          );

      print('Attendance logs response: $attendanceLogs');

      // Process the attendance logs to determine punch status
      if (attendanceLogs['content'] != null &&
          attendanceLogs['content']['data'] != null &&
          attendanceLogs['content']['data'] is List) {
        final logs = attendanceLogs['content']['data'] as List;
        print('Found ${logs.length} attendance logs');

        // Store the logs for display
        setState(() {
          _attendanceLogs = List<Map<String, dynamic>>.from(logs);
        });

        // Analyze the logs to determine current punch status
        bool hasPunchedIn = false;
        bool hasPunchedOut = false;

        for (var log in logs) {
          if (log['punchType'] == 'PunchIn') {
            hasPunchedIn = true;
          } else if (log['punchType'] == 'PunchOut') {
            hasPunchedOut = true;
          }
        }

        setState(() {
          _isPunchedIn = hasPunchedIn && !hasPunchedOut;
        });

        // Update duration timer based on punch status
        _updateDurationTimer();

        print(
          'Log analysis - Punched In: $hasPunchedIn, Punched Out: $hasPunchedOut, Current Status: $_isPunchedIn',
        );
      }
    } catch (e) {
      print('Error fetching attendance logs: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission permanently denied';
        });
        return;
      }

      await _getCurrentLocation();
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePunchIn() async {
    if (_employeeId == null || _tenantId == null) {
      print(
        'Missing IDs before punch in - Employee: $_employeeId, Tenant: $_tenantId',
      );
      // Try to reload session data once more
      await _loadSessionData();

      if (_employeeId == null || _tenantId == null) {
        setState(() {
          _error =
              'Employee ID or Tenant ID not available. Please check your login session.';
        });
        return;
      }
    }

    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Validate geofence before punch in
      final geofenceValidation = await _validateGeofenceForPunch();
      if (!geofenceValidation['isValid']) {
        setState(() {
          _error = geofenceValidation['message'];
        });
        return;
      }

      final now = DateTime.now();
      final response = await widget.apiService.punchIn(
        employeeId: _employeeId!,
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
        dateWithTime: now.toIso8601String(),
      );

      if (response['error'] == false) {
        setState(() {
          _isPunchedIn = true;
        });

        // Start duration timer for real-time updates
        _updateDurationTimer();

        // Refresh attendance status after successful punch in
        await _fetchTodayAttendance();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Punched in successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Punch in failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Punch in failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePunchOut() async {
    if (_employeeId == null || _tenantId == null) {
      print(
        'Missing IDs before punch out - Employee: $_employeeId, Tenant: $_tenantId',
      );
      // Try to reload session data once more
      await _loadSessionData();

      if (_employeeId == null || _tenantId == null) {
        setState(() {
          _error =
              'Employee ID or Tenant ID not available. Please check your login session.';
        });
        return;
      }
    }

    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Validate geofence before punch out
      final geofenceValidation = await _validateGeofenceForPunch();
      if (!geofenceValidation['isValid']) {
        setState(() {
          _error = geofenceValidation['message'];
        });
        return;
      }

      final now = DateTime.now();
      final response = await widget.apiService.punchOut(
        employeeId: _employeeId!,
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
        dateWithTime: now.toIso8601String(),
        // tenantId: _tenantId!,
      );

      if (response['error'] == false) {
        setState(() {
          _isPunchedIn = false;
        });

        // Stop duration timer
        _updateDurationTimer();

        // Refresh attendance status after successful punch out
        await _fetchTodayAttendance();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Punched out successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        setState(() {
          _error = response['message'] ?? 'Punch out failed';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Punch out failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Punch Card
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.grey[800],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Attendance',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Timezone: ${_getCurrentTimezone()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isPunchedIn
                            ? Colors.green[100]
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isPunchedIn ? 'Working' : 'Not Punched',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isPunchedIn
                              ? Colors.green[800]
                              : Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Working Hours Display
                Center(
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange[100]!, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Hours',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _calculateWorkingDuration(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Error Display
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Geofence Status Display with improved colors
                if (_geofenceService.getCurrentGeofence() != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.getGeofenceStatusLightColor(
                        _isInsideGeofence,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.getGeofenceStatusColor(
                          _isInsideGeofence,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isInsideGeofence
                              ? Icons.location_on
                              : Icons.location_off,
                          color: AppTheme.getGeofenceStatusColor(
                            _isInsideGeofence,
                          ),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isInsideGeofence
                              ? 'Inside Office Area'
                              : 'Outside Office Area',
                          style: TextStyle(
                            color: AppTheme.getGeofenceStatusColor(
                              _isInsideGeofence,
                            ),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _geofenceService
                              .showGeofenceStatusDialog(context),
                          child: Icon(
                            Icons.info_outline,
                            color: AppTheme.textSecondary,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Punch Status Display
                if (_isPunchedIn)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Punched In at ${_getFormattedPunchInTime()}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.grey[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Not Punched',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Punch Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_isPunchedIn ? _handlePunchOut : _handlePunchIn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _isLoading
                                ? (_isPunchedIn
                                      ? "Punching Out..."
                                      : "Punching In...")
                                : (_isPunchedIn ? "Punch Out" : "Punch In"),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Attendance Logs Section
          if (_attendanceLogs.isNotEmpty) _buildAttendanceLogsSection(),

          // Map Section
          if (_hasLocationData()) _buildMapSection(),
        ],
      ),
    );
  }

  String _getCurrentTimezone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final hours = offset.inHours;
    final minutes = offset.inMinutes % 60;
    final sign = hours >= 0 ? '+' : '';
    return 'UTC$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  String _calculateWorkingDuration() {
    if (_attendanceLogs.isEmpty) return '00:00:00';

    // Calculate total working time from attendance logs
    Duration totalDuration = Duration.zero;
    DateTime? punchInTime;

    for (var log in _attendanceLogs) {
      if (log['punchType'] == 'PunchIn') {
        punchInTime = DateTime.tryParse(log['date'] ?? '');
      } else if (log['punchType'] == 'PunchOut' && punchInTime != null) {
        final punchOutTime = DateTime.tryParse(log['date'] ?? '');
        if (punchOutTime != null) {
          totalDuration += punchOutTime.difference(punchInTime);
          punchInTime = null;
        }
      }
    }

    // If currently punched in, add current session
    if (_isPunchedIn && punchInTime != null) {
      totalDuration += DateTime.now().difference(punchInTime);
    }

    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    final seconds = totalDuration.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getFormattedPunchInTime() {
    if (_attendanceLogs.isEmpty) return '--:--:--';

    // Find the latest punch in time
    for (var log in _attendanceLogs.reversed) {
      if (log['punchType'] == 'PunchIn') {
        final dateTime = DateTime.tryParse(log['date'] ?? '');
        if (dateTime != null) {
          return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
        }
      }
    }

    return '--:--:--';
  }

  bool _hasLocationData() {
    return _attendanceLogs.any(
      (log) => log['lat'] != null && log['lon'] != null,
    );
  }

  Widget _buildAttendanceLogsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // Expandable Header
          InkWell(
            onTap: () {
              setState(() {
                _showAttendanceLogs = !_showAttendanceLogs;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendance Logs',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _showAttendanceLogs
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Logs Table
          if (_showAttendanceLogs)
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Type',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Record',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Time',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  rows: _attendanceLogs.map((log) {
                    final dateTime = DateTime.tryParse(log['date'] ?? '');
                    final formattedDate = dateTime != null
                        ? '${dateTime.day}/${dateTime.month}/${dateTime.year}'
                        : 'N/A';
                    final formattedTime = dateTime != null
                        ? '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}'
                        : 'N/A';

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            formattedDate,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Text(
                            log['punchType'] ?? 'N/A',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Text(
                            log['recordType'] ?? 'N/A',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Text(
                            formattedTime,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          // Expandable Header
          InkWell(
            onTap: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Map ${_selectedLogIndex != null ? '(Selected Location)' : '(Latest Location)'}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _showMap
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Map Content
          if (_showMap)
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildMapWidget(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedLogIndex != null && _attendanceLogs.isNotEmpty
                        ? 'Showing location from selected punch log'
                        : 'Showing location from latest punch log',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapWidget() {
    // Get location data for map
    Map<String, dynamic>? locationData;

    if (_selectedLogIndex != null &&
        _selectedLogIndex! < _attendanceLogs.length) {
      locationData = _attendanceLogs[_selectedLogIndex!];
    } else if (_attendanceLogs.isNotEmpty) {
      locationData = _attendanceLogs.last;
    }

    if (locationData == null ||
        locationData['lat'] == null ||
        locationData['lon'] == null) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Text(
            'No location data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final lat = locationData['lat'];
    final lon = locationData['lon'];

    // For Flutter, we'll use a simple placeholder for now
    // In a real implementation, you'd use google_maps_flutter or similar
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: Colors.red[600], size: 40),
            const SizedBox(height: 8),
            Text(
              'Location: $lat, $lon',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Map integration would go here',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Geofencing validation method
  Future<Map<String, dynamic>> _validateGeofenceForPunch() async {
    try {
      print("🔍 Validating geofence for punch operation...");

      // Use the geofence service for validation
      final validation = await _geofenceService.validateGeofenceForPunch(
        _currentPosition,
      );

      // Update last known location if we have a position
      if (_currentPosition != null) {
        await _geofenceService.updateLastKnownLocation(_currentPosition!);
      }

      return validation;
    } catch (error) {
      print("Error validating geofence: $error");
      return {
        'isValid': true,
        'message': 'Unable to validate geofence. Punch allowed.',
        'distance': null,
      };
    }
  }

  // Start/stop duration timer based on punch status
  void _updateDurationTimer() {
    _durationTimer?.cancel();

    if (_isPunchedIn) {
      // Start timer to update duration every second
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            // This will trigger a rebuild and recalculate the duration
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _geofenceService.dispose();
    super.dispose();
  }
}
