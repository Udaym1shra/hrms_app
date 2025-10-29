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

  // Location stream subscription for continuous tracking
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isDisposed = false;

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
      // Also refresh geofence status when dependencies change
      _refreshGeofenceStatus();
      // Ensure geofence config is loaded if not already
      _fetchGeofenceConfig();
    }
  }

  // Method to refresh geofence status
  Future<void> _refreshGeofenceStatus() async {
    try {
      if (_currentPosition != null) {
        print('🔄 Refreshing geofence status in punch widget...');
        print(
          '📍 Current position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
        );

        // Check if geofence exists before refreshing
        final geofence = _geofenceService.getCurrentGeofence();
        if (geofence == null) {
          print(
            '⚠️ No geofence config found - refreshGeofenceStatus will not run',
          );
          print('🔍 Checking if geofence needs to be loaded...');
          return;
        }

        // First update the local state from service (in case stream hasn't fired yet)
        final currentStatus = _geofenceService.isInsideGeofenceStatus;
        if (mounted && !_isDisposed) {
          setState(() {
            _isInsideGeofence = currentStatus;
          });
          print('🔄 Initial status from service: $currentStatus');
        }

        // Then refresh - the stream listener will update the state automatically
        await _geofenceService.refreshGeofenceStatus(_currentPosition!);

        // Read updated status after refresh
        final newStatus = _geofenceService.isInsideGeofenceStatus;
        final hasConfig = _geofenceService.getCurrentGeofence() != null;

        if (mounted && !_isDisposed) {
          print(
            '🔄 After refresh - Service status: $newStatus, Widget status: $_isInsideGeofence',
          );
          print('🔄 Has geofence config: $hasConfig');

          // Ensure local state matches service state
          if (_isInsideGeofence != newStatus) {
            setState(() {
              _isInsideGeofence = newStatus;
            });
            print(
              '🔄 Corrected widget state to match service: $_isInsideGeofence',
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error refreshing geofence status: $e');
    }
  }

  Future<void> _initializeGeofenceService() async {
    try {
      // Set API service for geofence service
      _geofenceService.setApiService(widget.apiService);

      await _geofenceService.initialize();

      // Check if geofence was loaded from shared preferences
      final geofence = _geofenceService.getCurrentGeofence();
      if (geofence != null) {
        print(
          '✅ Geofence service initialized - found existing geofence config',
        );
        print('🔍 Geofence type: ${_geofenceService.getCurrentGeofenceType()}');
      } else {
        print(
          '⚠️ Geofence service initialized but no geofence config found yet',
        );
      }

      // Listen to geofence status changes for real-time UI updates
      _geofenceService.isInsideGeofence.listen((isInside) {
        if (mounted && !_isDisposed) {
          setState(() {
            _isInsideGeofence = isInside;
          });
        }
      });

      // Listen to geofence events
      _geofenceService.geofenceEvents.listen((event) {
        if (mounted && !_isDisposed) {
          final isInside = event.type == GeofenceEventType.enter;
          setState(() {
            _isInsideGeofence = isInside;
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

      // Update initial geofence status
      _isInsideGeofence = _geofenceService.isInsideGeofenceStatus;
      print('🔍 Initial geofence status: $_isInsideGeofence');

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
        print('About to call _fetchGeofenceConfig from _loadSessionData');
        await _fetchGeofenceConfig();
        print('Completed _fetchGeofenceConfig from _loadSessionData');
      } else {
        print('⚠️ Cannot fetch data - Employee ID is null');
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
    if (_employeeId == null) {
      print('⚠️ Cannot fetch attendance - Employee ID is null');
      return;
    }

    try {
      print(
        '🔄 Fetching today\'s attendance for employee: $_employeeId, tenant: $_tenantId',
      );

      // First try to get today's attendance list
      final attendanceResponse = await widget.apiService.getTodayAttendance(
        _employeeId!,
        _tenantId!,
      );

      print('📥 Today\'s attendance response: ${attendanceResponse.toJson()}');
      print('📥 Response error: ${attendanceResponse.error}');

      // Extract attendance logs from the response
      // The logs are in content.attendanceLogsId array (if attendance record exists)
      if (!attendanceResponse.error) {
        final responseData = attendanceResponse.toJson();
        final content = responseData['content'];

        // Check if attendance record exists (content has direct fields, not content.data)
        if (content != null && content is Map) {
          // Check if it's the direct attendance record format (has attendanceLogsId)
          if (content.containsKey('attendanceLogsId')) {
            final logsArray = content['attendanceLogsId'];
            print(
              '📊 Found attendance logs in response: ${logsArray?.length ?? 0} logs',
            );

            if (logsArray != null &&
                logsArray is List &&
                logsArray.isNotEmpty) {
              print('🔄 Processing ${logsArray.length} logs from array');

              // Convert logs to our format
              final formattedLogs = <Map<String, dynamic>>[];
              for (var i = 0; i < logsArray.length; i++) {
                final log = logsArray[i];
                print('   Processing log $i: $log (type: ${log.runtimeType})');

                // Handle different log formats
                Map<String, dynamic> logMap;
                if (log is Map) {
                  logMap = Map<String, dynamic>.from(log);
                } else {
                  logMap = {'error': 'Invalid log format'};
                }

                final formattedLog = {
                  'id': logMap['id'],
                  'date': logMap['date']?.toString() ?? '',
                  'punchType': logMap['punchType']?.toString() ?? 'PunchOut',
                  'recordType': logMap['recordType']?.toString() ?? 'Manual',
                  'lat': logMap['lat'],
                  'lon': logMap['lon'],
                };

                print('   Formatted log $i: $formattedLog');
                formattedLogs.add(formattedLog);
              }

              print(
                '📦 Storing ${formattedLogs.length} attendance logs from attendance record',
              );
              for (var i = 0; i < formattedLogs.length; i++) {
                print('   Log $i: ${formattedLogs[i]}');
              }

              // Store logs first
              setState(() {
                _attendanceLogs = formattedLogs;
              });

              // Wait a moment for setState to complete, then verify
              await Future.delayed(const Duration(milliseconds: 100));

              // Verify logs are stored
              print(
                '✅ Verification - Attendance logs count after setState: ${_attendanceLogs.length}',
              );
              if (_attendanceLogs.isNotEmpty) {
                print('✅ Verification - Last log: ${_attendanceLogs.last}');
              }

              // Update timer based on last punch type
              _updateDurationTimer();

              // Get last punch type for display
              final lastPunchType = _getLastPunchType();
              print('✅ Last punch type from logs: $lastPunchType');

              return; // Exit early since we got logs from attendance record
            } else {
              print('⚠️ logsArray is null, empty, or not a List');
            }
          }

          // If it's the paginated format (content.data)
          if (content.containsKey('data') && content['data'] is List) {
            final dataList = content['data'] as List;
            print(
              '📊 Found attendance records in data array: ${dataList.length} records',
            );

            if (dataList.isNotEmpty) {
              final todayAttendance = dataList.first;
              // Check if this record has attendanceLogsId
              if (todayAttendance.containsKey('attendanceLogsId')) {
                final logsArray = todayAttendance['attendanceLogsId'];
                if (logsArray != null && logsArray is List) {
                  final formattedLogs = logsArray.map((log) {
                    return {
                      'id': log['id'],
                      'date': log['date'],
                      'punchType': log['punchType'],
                      'recordType': log['recordType'],
                      'lat': log['lat'],
                      'lon': log['lon'],
                    };
                  }).toList();

                  setState(() {
                    _attendanceLogs = formattedLogs;
                  });

                  _updateDurationTimer();

                  print(
                    '✅ Loaded ${formattedLogs.length} logs from paginated response',
                  );
                  return;
                }
              }
            }
          }
        }
      }

      // Fallback: Try fetching logs by date if not found in attendance response
      final today = DateTime.now().toIso8601String().split(
        'T',
      )[0]; // YYYY-MM-DD format
      print('📅 Fetching attendance logs separately for date: $today');
      await _fetchAttendanceLogsByEmployeeAndDate(today);
    } catch (e) {
      print('❌ Error fetching today\'s attendance: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _fetchGeofenceConfig() async {
    print(
      '🔍 _fetchGeofenceConfig called - Employee ID: $_employeeId, Tenant ID: $_tenantId',
    );

    if (_employeeId == null) {
      print('⚠️ Cannot fetch geofence - Employee ID is null');
      return;
    }

    try {
      print('🌐 Fetching geofence configuration for employee: $_employeeId');
      print('🔍 Tenant ID: $_tenantId');

      // First check if geofence was already loaded (e.g., from shared preferences)
      final existingGeofence = _geofenceService.getCurrentGeofence();
      if (existingGeofence != null) {
        print('✅ Found existing geofence config in service');
        print('🔍 Geofence type: ${_geofenceService.getCurrentGeofenceType()}');

        // Still refresh status with current location
        if (_currentPosition != null) {
          await _refreshGeofenceStatus();
        }
        return;
      }

      // Try to fetch from server using the same method as GeofenceMapWidget
      // First try employee-specific endpoint
      bool success = await _geofenceService.fetchGeofenceConfigFromServer(
        employeeId: _employeeId!,
        tenantId: _tenantId,
      );

      // If that fails, try tenant-based endpoint (same as GeofenceMapWidget)
      if (!success) {
        print(
          '⚠️ Employee-specific geofence fetch failed, trying tenant-based...',
        );
        try {
          final response = await widget.apiService.getGeofencingConfig(
            tenantId: _tenantId,
            branchId: null,
          );

          if (response['error'] == false && response['content'] != null) {
            final result = response['content']['result'];
            if (result != null &&
                result['data'] != null &&
                result['data'].isNotEmpty) {
              final geofenceData = result['data'][0];
              print('✅ Got geofence config from tenant endpoint');

              // Load it into GeofenceService
              if (geofenceData['boundary'] != null &&
                  geofenceData['boundary']['type'] == 'Polygon') {
                success = await _geofenceService.setupPolygonGeofence(
                  employeeId: _employeeId!,
                  tenantId: geofenceData['tenantId'] ?? _tenantId ?? 0,
                  boundary: geofenceData['boundary'],
                  geofenceId: geofenceData['id'],
                  geofenceName: 'Office Location',
                );
              } else if (geofenceData['lat'] != null &&
                  geofenceData['lon'] != null &&
                  geofenceData['radius'] != null) {
                success = await _geofenceService.setupGeofence(
                  employeeId: _employeeId!,
                  tenantId: geofenceData['tenantId'] ?? _tenantId ?? 0,
                  latitude: geofenceData['lat']?.toDouble() ?? 0.0,
                  longitude: geofenceData['lon']?.toDouble() ?? 0.0,
                  radius: geofenceData['radius']?.toDouble() ?? 100.0,
                  geofenceName: 'Office Location',
                );
              }
            }
          }
        } catch (e) {
          print('❌ Error fetching geofence from tenant endpoint: $e');
        }
      }

      if (success) {
        print('✅ Geofence configuration loaded successfully from server');
        // Verify geofence was actually loaded
        final geofence = _geofenceService.getCurrentGeofence();
        print('🔍 Geofence loaded check: ${geofence != null}');
        print('🔍 Geofence type: ${_geofenceService.getCurrentGeofenceType()}');
        print(
          '🔍 Is geofencing enabled: ${_geofenceService.isGeofencingEnabled}',
        );

        // Force a widget rebuild to update button state
        if (mounted && !_isDisposed) {
          setState(() {
            print('🔄 setState called after geofence load');
          });
        }

        // Refresh geofence status after loading config
        if (_currentPosition != null) {
          await _refreshGeofenceStatus();
        } else {
          print('⚠️ No current position - cannot refresh geofence status');
        }
      } else {
        print('⚠️ No geofence configuration found for this employee');
        print(
          '🔍 Double-checking: geofence = ${_geofenceService.getCurrentGeofence() != null}',
        );
        print('🔍 Geofence type: ${_geofenceService.getCurrentGeofenceType()}');
      }
    } catch (e) {
      print('❌ Error fetching geofence configuration: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _fetchAttendanceLogsByEmployeeAndDate(String date) async {
    if (_employeeId == null) {
      print('⚠️ Cannot fetch attendance logs - Employee ID is null');
      return;
    }

    try {
      print(
        '🔄 Fetching attendance logs for employee: $_employeeId, tenant: $_tenantId, date: $date',
      );
      final attendanceLogs = await widget.apiService
          .getAttendanceLogsByEmployeeAndDate(
            employeeId: _employeeId!,
            date: date,
          );

      print('📥 Attendance logs API response: $attendanceLogs');

      // Process the attendance logs - check both response formats
      List<dynamic> logs = [];

      if (attendanceLogs['content'] != null &&
          attendanceLogs['content'] is Map) {
        final content = attendanceLogs['content'] as Map;

        // Check if logs are in content.attendanceLogsId (direct format)
        if (content.containsKey('attendanceLogsId') &&
            content['attendanceLogsId'] is List) {
          logs = content['attendanceLogsId'] as List;
          print('✅ Found ${logs.length} logs in content.attendanceLogsId');
        }
        // Check if logs are in content.data (paginated format)
        else if (content.containsKey('data') && content['data'] is List) {
          final dataList = content['data'] as List;
          if (dataList.isNotEmpty && dataList.first is Map) {
            final firstRecord = dataList.first as Map;
            if (firstRecord.containsKey('attendanceLogsId') &&
                firstRecord['attendanceLogsId'] is List) {
              logs = firstRecord['attendanceLogsId'] as List;
              print(
                '✅ Found ${logs.length} logs in content.data[0].attendanceLogsId',
              );
            }
          }
        }
      }

      if (logs.isNotEmpty) {
        // Convert logs to our format
        final formattedLogs = logs.map<Map<String, dynamic>>((log) {
          final logMap = log is Map
              ? log
              : Map<String, dynamic>.from(log as dynamic);
          return {
            'id': logMap['id'],
            'date': logMap['date'],
            'punchType': logMap['punchType'],
            'recordType': logMap['recordType'] ?? 'Manual',
            'lat': logMap['lat'],
            'lon': logMap['lon'],
          };
        }).toList();

        // Store the logs for display
        print('📦 Storing ${formattedLogs.length} attendance logs');
        for (var i = 0; i < formattedLogs.length; i++) {
          print('   Log $i: ${formattedLogs[i]}');
        }

        setState(() {
          _attendanceLogs = formattedLogs;
        });

        // Get last punch type
        final lastPunchType = _getLastPunchType();
        print('✅ Stored logs. Last punch type: $lastPunchType');
        print('🔍 Last log details: ${formattedLogs.last}');

        // Update duration timer based on punch status
        _updateDurationTimer();
      } else {
        print('⚠️ No logs found in response');
        setState(() {
          _attendanceLogs = [];
        });
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

      // Refresh geofence status with initial position
      if (_currentPosition != null) {
        await _refreshGeofenceStatus();
      }

      // Start continuous location tracking
      _startLocationTracking();
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  // Start continuous location tracking for geofence monitoring
  void _startLocationTracking() {
    // Cancel existing subscription if any
    _positionStreamSubscription?.cancel();

    // Set up continuous location stream
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
        ).listen(
          (Position position) {
            if (!mounted || _isDisposed) return;

            setState(() {
              _currentPosition = position;
            });

            // Refresh geofence status with new location
            // The stream listener will automatically update _isInsideGeofence when status changes
            _geofenceService.refreshGeofenceStatus(position).catchError((
              error,
            ) {
              print('❌ Error refreshing geofence: $error');
            });
          },
          onError: (error) {
            print('❌ Location stream error: $error');
          },
        );
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
        punchType: "PunchIn",
      );

      if (response['error'] == false) {
        // Refresh attendance logs to get the latest status
        final today = DateTime.now().toIso8601String().split('T')[0];
        await _fetchAttendanceLogsByEmployeeAndDate(today);

        // Update timer based on new status
        _updateDurationTimer();

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
        punchType: "PunchOut",
        // tenantId: _tenantId!,
      );

      if (response['error'] == false) {
        // Refresh attendance logs to get the latest status
        final today = DateTime.now().toIso8601String().split('T')[0];
        await _fetchAttendanceLogsByEmployeeAndDate(today);

        // Stop duration timer
        _updateDurationTimer();

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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
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
                                  color: const Color(0xFF1E3A5F), // Dark blue
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
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getLastPunchType() == 'PunchIn'
                                ? const Color(
                                    0xFFC8E6C9,
                                  ) // Light green background
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: _getLastPunchType() == 'PunchIn'
                                ? Border.all(
                                    color: const Color(0xFF81C784),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Text(
                            _getLastPunchType() == 'PunchIn'
                                ? 'Working'
                                : 'Not Punched',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getLastPunchType() == 'PunchIn'
                                  ? const Color(0xFF2E7D32) // Dark green text
                                  : Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Working Hours Display
                    Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive size based on available width
                          final maxWidth = constraints.maxWidth;
                          final screenWidth = MediaQuery.of(context).size.width;
                          final isMobile = screenWidth <= 768;

                          // Larger minimum size for mobile to accommodate text
                          final circleSize = isMobile
                              ? (maxWidth * 0.45).clamp(140.0, 180.0)
                              : (maxWidth * 0.4).clamp(120.0, 180.0);

                          // Calculate text sizes with better mobile support
                          final titleSize = circleSize < 150
                              ? (circleSize * 0.09).clamp(10.0, 14.0)
                              : (circleSize * 0.1).clamp(12.0, 16.0);
                          final durationSize = circleSize < 150
                              ? (circleSize * 0.12).clamp(14.0, 20.0)
                              : (circleSize * 0.15).clamp(18.0, 24.0);
                          final startTimeSize = circleSize < 150
                              ? (circleSize * 0.07).clamp(8.0, 11.0)
                              : (circleSize * 0.08).clamp(10.0, 13.0);

                          // Adjust spacing for smaller circles
                          final spacing1 = circleSize < 150
                              ? circleSize * 0.04
                              : circleSize * 0.06;
                          final spacing2 = circleSize < 150
                              ? circleSize * 0.02
                              : circleSize * 0.03;

                          // Padding to ensure text stays inside circle
                          final innerPadding = circleSize * 0.1;

                          return Container(
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                  0xFFFFE0B2,
                                ), // Light orange/beige
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(innerPadding),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Production Hours',
                                        style: TextStyle(
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[500],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: spacing1),
                                      Text(
                                        _calculateWorkingDuration(),
                                        style: TextStyle(
                                          fontSize: durationSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: spacing2),
                                      Text(
                                        'Start: ${_getStartTime()}',
                                        style: TextStyle(
                                          fontSize: startTimeSize,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Punch Status Display
                    Builder(
                      builder: (context) {
                        final lastPunchType = _getLastPunchType();
                        if (lastPunchType == 'PunchIn') {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green[600],
                                  size: 20,
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
                          );
                        }
                        return Container(
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
                        );
                      },
                    ),

                    // Geofence restriction message (if outside boundary and geofence is configured)
                    Builder(
                      builder: (context) {
                        // Get fresh status directly from service and combine with widget state
                        final serviceInsideStatus =
                            _geofenceService.isInsideGeofenceStatus;
                        final isInsideCombined =
                            _isInsideGeofence || serviceInsideStatus;
                        final geofenceConfig = _geofenceService
                            .getCurrentGeofence();
                        final hasGeofenceConfig = geofenceConfig != null;

                        // Additional check: if service has geofencing enabled, treat as configured
                        final serviceGeofenceEnabled =
                            _geofenceService.isGeofencingEnabled;
                        final isGeofenceConfigured =
                            hasGeofenceConfig || serviceGeofenceEnabled;

                        final isOutsideGeofence =
                            isGeofenceConfigured && !isInsideCombined;

                        if (isOutsideGeofence) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.warningColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_off,
                                  color: AppTheme.warningColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You are outside the office area. Please come inside to punch in/out.',
                                    style: TextStyle(
                                      color: AppTheme.warningColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Punch Button
                    Builder(
                      builder: (context) {
                        final lastPunchType = _getLastPunchType();
                        final shouldShowPunchOut = lastPunchType == 'PunchIn';

                        // Get fresh status directly from service (most reliable)
                        final serviceInsideStatus =
                            _geofenceService.isInsideGeofenceStatus;
                        final isInsideCombined =
                            _isInsideGeofence || serviceInsideStatus;

                        // CRITICAL: Check geofence configuration
                        // Use the geofence display status as the source of truth
                        // If the geofence status display is showing, geofence is configured
                        final geofence = _geofenceService.getCurrentGeofence();
                        final serviceHasGeofence =
                            _geofenceService.isGeofencingEnabled;
                        final geofenceType = _geofenceService
                            .getCurrentGeofenceType();

                        // Check if geofence exists by looking at the UI display condition
                        // The geofence status display section shows when geofence exists
                        final hasGeofenceConfig =
                            geofence != null ||
                            serviceHasGeofence ||
                            geofenceType != 'None';

                        // Sync widget state with service if different
                        if (mounted &&
                            _isInsideGeofence != serviceInsideStatus) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_isDisposed) {
                              setState(() {
                                _isInsideGeofence = serviceInsideStatus;
                              });
                            }
                          });
                        }

                        // If geofence is configured and user is outside, disable button
                        final isButtonDisabled =
                            _isLoading ||
                            (hasGeofenceConfig && !isInsideCombined);

                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isButtonDisabled
                                ? null
                                : (shouldShowPunchOut
                                      ? _handlePunchOut
                                      : _handlePunchIn),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF1E3A5F,
                              ), // Dark blue
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
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
                                        ? (shouldShowPunchOut
                                              ? "Punching Out..."
                                              : "Punching In...")
                                        : (shouldShowPunchOut
                                              ? "Punch Out"
                                              : "Punch In"),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isButtonDisabled
                                          ? Colors.grey[600]
                                          : Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      },
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
        ),
      ),
    );
  }

  String _getCurrentTimezone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final totalMinutes = offset.inMinutes;

      // Check if it's IST (UTC+5:30) - 5 hours 30 minutes = 330 minutes
      if (totalMinutes == 330 ||
          (offset.inHours == 5 && offset.inMinutes % 60 == 30)) {
        return 'Asia/Calcutta';
      }

      // For other timezones, return UTC offset format
      final hours = offset.inHours;
      final minutes = offset.inMinutes % 60;
      final sign = hours >= 0 ? '+' : '';
      return 'UTC$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } catch (e) {
      // Final fallback - assume IST for Indian users
      return 'Asia/Calcutta';
    }
  }

  // Helper method to parse date from API format "YYYY-MM-DD HH:mm:ss"
  DateTime? _parseAttendanceDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Try to parse ISO format first
      final isoParsed = DateTime.tryParse(dateStr);
      if (isoParsed != null) return isoParsed;

      // Try to parse "YYYY-MM-DD HH:mm:ss" format
      if (dateStr.contains(' ') && dateStr.length >= 19) {
        final parts = dateStr.split(' ');
        if (parts.length == 2) {
          final datePart = parts[0]; // YYYY-MM-DD
          final timePart = parts[1]; // HH:mm:ss
          final dateTimeStr = '${datePart}T$timePart';
          return DateTime.tryParse(dateTimeStr);
        }
      }

      return null;
    } catch (e) {
      print('❌ Error parsing date: $dateStr, error: $e');
      return null;
    }
  }

  String _calculateWorkingDuration() {
    if (_attendanceLogs.isEmpty) return '00:00:00';

    // Calculate total working time from attendance logs
    Duration totalDuration = Duration.zero;
    DateTime? punchInTime;

    for (var log in _attendanceLogs) {
      if (log['punchType'] == 'PunchIn') {
        punchInTime = _parseAttendanceDate(log['date']?.toString());
      } else if (log['punchType'] == 'PunchOut' && punchInTime != null) {
        final punchOutTime = _parseAttendanceDate(log['date']?.toString());
        if (punchOutTime != null) {
          totalDuration += punchOutTime.difference(punchInTime);
          punchInTime = null;
        }
      }
    }

    // If last log is PunchIn, add current session duration
    if (_getLastPunchType() == 'PunchIn') {
      // Find the latest punch in time
      DateTime? latestPunchIn;
      for (var log in _attendanceLogs.reversed) {
        if (log['punchType'] == 'PunchIn') {
          latestPunchIn = _parseAttendanceDate(log['date']?.toString());
          break;
        }
      }
      if (latestPunchIn != null) {
        totalDuration += DateTime.now().difference(latestPunchIn);
      }
    }

    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    final seconds = totalDuration.inSeconds % 60;

    // Format as HH:MM:SS with leading zeros
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get the start time (first PunchIn) for display
  String _getStartTime() {
    if (_attendanceLogs.isEmpty) return '--:--:--';

    // Find the first punch in time
    for (var log in _attendanceLogs) {
      if (log['punchType'] == 'PunchIn') {
        final dateTime = _parseAttendanceDate(log['date']?.toString());
        if (dateTime != null) {
          return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
        }
      }
    }

    return '--:--:--';
  }

  String _formatDateForDisplay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Get the last punch type from attendance logs
  String _getLastPunchType() {
    if (_attendanceLogs.isEmpty) {
      return 'PunchOut';
    }

    // Get the last log entry
    final lastLog = _attendanceLogs.last;
    final punchType = lastLog['punchType']?.toString() ?? 'PunchOut';

    return punchType;
  }

  String _getFormattedPunchInTime() {
    if (_attendanceLogs.isEmpty) return '--:--:--';

    // Find the latest punch in time
    for (var log in _attendanceLogs.reversed) {
      if (log['punchType'] == 'PunchIn') {
        final dateTime = _parseAttendanceDate(log['date']?.toString());
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
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Attendance Logs',
                    style: TextStyle(
                      color: Colors.grey[800],
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
                        'DATE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'TYPE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'RECORD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'TIME',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  rows: _attendanceLogs.map((log) {
                    final dateTime = _parseAttendanceDate(
                      log['date']?.toString(),
                    );
                    final formattedDate = dateTime != null
                        ? _formatDateForDisplay(
                            dateTime,
                          ) // Format as "Oct 28, 2025"
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Map ${_selectedLogIndex != null ? '(Selected Location)' : '(Latest Location)'}',
                    style: TextStyle(
                      color: Colors.grey[800],
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

  // Geofencing validation method with improved location refresh
  Future<Map<String, dynamic>> _validateGeofenceForPunch() async {
    try {
      print("🔍 Validating geofence for punch operation...");

      // Check if geofence is configured
      if (_geofenceService.getCurrentGeofence() == null) {
        print("ℹ️ No geofence configured. Punch allowed without validation.");
        return {
          'isValid': true,
          'message': 'No geofence configured. Punch allowed.',
          'distance': null,
        };
      }

      // Get fresh location data for validation
      Position? currentPosition = _currentPosition;
      if (currentPosition == null) {
        print("📍 Getting fresh location for validation...");
        try {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          setState(() {
            _currentPosition = currentPosition;
          });
        } catch (e) {
          print("❌ Error getting current position: $e");
          return {
            'isValid': false,
            'message':
                'Unable to get your current location. Please enable location services and try again.',
            'distance': null,
          };
        }
      }

      print(
        '📍 Current position: ${currentPosition.latitude}, ${currentPosition.longitude}',
      );
      print('🎯 Geofence type: ${_geofenceService.getCurrentGeofenceType()}');

      // Debug geofence state
      _geofenceService.debugGeofenceState();

      // Use the geofence service for validation
      final validation = await _geofenceService.validateGeofenceForPunch(
        currentPosition,
      );

      // Update UI state to reflect the refreshed status
      if (mounted) {
        setState(() {
          _isInsideGeofence = _geofenceService.isInsideGeofenceStatus;
        });
      }

      print("✅ Geofence validation completed: ${validation['isValid']}");
      return validation;
    } catch (error) {
      print("❌ Error validating geofence: $error");
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

    if (_getLastPunchType() == 'PunchIn') {
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
    _isDisposed = true;
    _durationTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
