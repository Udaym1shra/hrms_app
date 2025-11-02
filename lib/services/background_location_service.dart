import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'storage_service.dart';
import '../utils/session_storage.dart';
// Added By uday on 30_10_2025: Request notification permission on Android 13+
import 'package:permission_handler/permission_handler.dart' as ph;
import 'notification_service.dart';

@pragma('vm:entry-point')
class BackgroundLocationService {
  // Notification constants - Required for foreground service on Android
  static const String _notificationTitle = 'HRMS Location Tracking';
  static const String _notificationContent =
      'Tracking your location for geofencing';

  // Initialize background service
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart:
            true, // Added By uday on 30_10_2025: Ensure service can auto-run; it self-stops if not punched in
        isForegroundMode: true, // Required for background location on Android
        notificationChannelId: 'hrms_location_channel',
        initialNotificationTitle: _notificationTitle,
        initialNotificationContent: _notificationContent,
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  // Start the background service only if last attendance log is punchin
  // Enhanced for HyperOS compatibility
  static Future<void> start() async {
    // Check if employee is currently punched in before starting service
    if (!await _isEmployeePunchedIn()) {
      print('❌ Employee not punched in, not starting background service');
      return;
    }

    // Check location service and permission before starting
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Location service disabled, cannot start background service');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('❌ Location permission denied, cannot start background service');
      return;
    }

    // Added By uday on 30_10_2025: Ensure notification permission granted (Android 13+)
    try {
      final notifStatus = await ph.Permission.notification.status;
      if (!notifStatus.isGranted) {
        final requested = await ph.Permission.notification.request();
        if (!requested.isGranted) {
          print(
            '❌ Notification permission denied, cannot start foreground service',
          );
          return;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Notification permission request failed: $e');
    }

    // Enhanced for HyperOS: Check battery optimization status
    try {
      final batteryOptStatus =
          await ph.Permission.ignoreBatteryOptimizations.isGranted;
      if (!batteryOptStatus) {
        print(
          '⚠️ Battery optimization not ignored - service may be killed on HyperOS',
        );
        print(
          '⚠️ User should disable battery optimization for reliable background tracking',
        );
      }
    } catch (e) {
      print('⚠️ Could not check battery optimization status: $e');
    }

    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (!isRunning) {
      print(
        '🚀 Starting background location service for geofencing (HyperOS compatible)',
      );
      try {
        service.startService();
        // Verify service started (HyperOS may kill it immediately)
        await Future.delayed(const Duration(seconds: 2));
        final verifyRunning = await service.isRunning();
        if (!verifyRunning) {
          print('⚠️ Service may have been killed immediately - retrying...');
          await Future.delayed(const Duration(seconds: 1));
          service.startService();
        } else {
          print('✅ Background service started successfully');
        }
      } catch (e) {
        print('❌ Error starting service: $e');
        // Retry once
        await Future.delayed(const Duration(seconds: 2));
        try {
          service.startService();
        } catch (e2) {
          print('❌ Failed to start service after retry: $e2');
        }
      }
    } else {
      print('✅ Background location service already running');
    }
  }

  // Stop the background service
  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    bool isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke('stop');
    }
  }

  // Check if service is running
  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  // Ensure service continues running for geofencing (call this periodically)
  // Enhanced for HyperOS - more aggressive restart mechanism
  static Future<void> ensureServiceRunning() async {
    if (await _isEmployeePunchedIn()) {
      // Check location service and permission before ensuring service runs
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location service disabled, stopping background service');
        await stop();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('❌ Location permission denied, stopping background service');
        await stop();
        return;
      }

      final service = FlutterBackgroundService();
      bool isRunning = await service.isRunning();
      if (!isRunning) {
        print(
          '🔄 Service not running - restarting background service for geofencing (HyperOS compatibility)',
        );

        // On HyperOS, services get killed frequently, so we need to restart more aggressively
        try {
          // Request notification permission again if needed (HyperOS may reset it)
          final notifStatus = await ph.Permission.notification.status;
          if (!notifStatus.isGranted) {
            print('⚠️ Notification permission lost, requesting again...');
            await ph.Permission.notification.request();
          }

          // Start the service
          service.startService();

          // Wait a bit and verify it started
          await Future.delayed(const Duration(seconds: 2));
          final stillRunning = await service.isRunning();
          if (!stillRunning) {
            print('⚠️ Service failed to start, retrying...');
            await Future.delayed(const Duration(seconds: 1));
            service.startService();
          }
        } catch (e) {
          print('❌ Error restarting service: $e');
          // Try one more time after delay
          await Future.delayed(const Duration(seconds: 3));
          try {
            service.startService();
          } catch (e2) {
            print('❌ Failed to restart service after retry: $e2');
          }
        }
      } else {
        // Service is running - do a health check
        print('✅ Background service is running');
      }
    } else {
      print('⏹️ Employee not punched in, stopping background service');
      await stop();
    }
  }

  // Check if employee is currently punched in (last attendance log is punchin)
  static Future<bool> _isEmployeePunchedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get employee ID and tenant ID from SessionStorage
      final employeeId = await SessionStorage.getEmployeeId();
      final tenantId = await SessionStorage.getTenantId();

      if (employeeId == null || tenantId == null) {
        return false; // No employee data available
      }

      // Get API service instance
      final apiService = ApiService(StorageService(prefs));

      // Fetch today's attendance logs
      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final logsResp = await apiService.getAttendanceLogsByEmployeeAndDate(
        employeeId: employeeId,
        date: todayStr,
      );

      final logsList =
          (logsResp['content']?['attendanceLogsId'] as List?) ?? [];
      final lastLog = logsList.isNotEmpty ? logsList.last : null;
      final lastType = lastLog != null
          ? (lastLog['punchType']?.toString() ?? '')
          : '';

      // Return true only if last punch type is 'punchin'
      return lastType.toLowerCase() == 'punchin';
    } catch (e) {
      print('❌ Error checking punch status: $e');
      return false;
    }
  }

  // iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  // Main background service handler
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Ensure notification channel is created before starting foreground service
    try {
      await NotificationService.instance.initialize();
      // Give the channel creation time to propagate
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }

    if (service is AndroidServiceInstance) {
      // When isForegroundMode is true, the plugin handles foreground service automatically
      // Only manually set if needed (the plugin should handle it via configuration)
      // Remove the immediate call to avoid race condition with channel creation
      service.on('setAsForeground').listen((event) {
        try {
          service.setAsForegroundService();
        } catch (e) {
          print('❌ Error setting as foreground service: $e');
        }
      });

      service.on('setAsBackground').listen((event) {
        try {
          service.setAsBackgroundService();
        } catch (e) {
          print('❌ Error setting as background service: $e');
        }
      });
    }

    service.on('stop').listen((event) {
      service.stopSelf();
    });

    // Initialize location monitoring
    StreamSubscription<Position>? positionStream;
    Timer? uploadTimer;

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        service.stopSelf();
        return;
      }

      // Start location stream with background-optimized settings for persistent tracking
      // Added By uday on 30_10_2025: Remove timeLimit to avoid stream auto-stopping
      positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5, // Update every 5 meters for better geofencing
            ),
          ).listen(
            (Position position) async {
              // Check if employee is still punched in
              if (!await _isEmployeePunchedIn()) {
                print(
                  '❌ Employee no longer punched in, stopping background service',
                );
                service.stopSelf();
                return;
              }

              // Update notification with current location
              if (service is AndroidServiceInstance) {
                service.setForegroundNotificationInfo(
                  title: _notificationTitle,
                  content:
                      'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
                );
              }

              // Save location to shared preferences
              await _saveLocation(position);

              // Upload location if employee is punched in
              await _uploadLocationIfNeeded(position);
            },
            onError: (error) {
              print('❌ Background location error: $error');
            },
          );

      // Periodic upload timer (every 3 minutes) + queue processing
      uploadTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
        try {
          // Check if employee is still punched in
          if (!await _isEmployeePunchedIn()) {
            print(
              '❌ Employee no longer punched in, stopping background service',
            );
            service.stopSelf();
            return;
          }

          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          await _uploadLocationIfNeeded(position);

          // Also process offline queue periodically
          final prefs = await SharedPreferences.getInstance();
          final apiService = ApiService(StorageService(prefs));
          await _processOfflineQueue(prefs, apiService);
        } catch (e) {
          print('❌ Error in periodic upload: $e');
        }
      });

      // Keep service alive with continuous monitoring
      while (true) {
        await Future.delayed(const Duration(seconds: 30));

        // Check if employee is still punched in every 30 seconds
        if (!await _isEmployeePunchedIn()) {
          print('❌ Employee no longer punched in, stopping background service');
          service.stopSelf();
          break;
        }

        // Health check: Verify location service is still enabled
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('⚠️ Location service disabled, stopping background service');
          service.stopSelf();
          break;
        }

        // Health check: Verify permission is still granted
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          print('⚠️ Location permission revoked, stopping background service');
          service.stopSelf();
          break;
        }
      }
    } catch (e) {
      print('❌ Error starting background location service: $e');
      service.stopSelf();
    }

    // Cleanup on service stop
    service.on('stop').listen((event) {
      positionStream?.cancel();
      uploadTimer?.cancel();
    });
  }

  // Save location to shared preferences
  static Future<void> _saveLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Added By uday on 30_10_2025: Guard against null timestamp from Geolocator
      // Even though timestamp is typed non-nullable in newer geolocator versions,
      // some devices can still yield null; guard via try/catch.
      int safeTimestampMs;
      try {
        safeTimestampMs = position.timestamp.millisecondsSinceEpoch;
      } catch (_) {
        safeTimestampMs = DateTime.now().millisecondsSinceEpoch;
      }
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': safeTimestampMs,
        'accuracy': position.accuracy,
      };
      await prefs.setString('last_known_location', jsonEncode(locationData));
    } catch (e) {
      print('❌ Error saving location: $e');
    }
  }

  // Upload location if employee is punched in
  static Future<void> _uploadLocationIfNeeded(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get employee ID and tenant ID from SessionStorage
      final employeeId = await SessionStorage.getEmployeeId();
      final tenantId = await SessionStorage.getTenantId();

      if (employeeId == null || tenantId == null) {
        return; // No employee data available
      }

      // Get API service instance
      final apiService = ApiService(StorageService(prefs));

      // Fetch today's attendance logs
      final now = DateTime.now();
      final todayStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final logsResp = await apiService.getAttendanceLogsByEmployeeAndDate(
        employeeId: employeeId,
        date: todayStr,
      );

      final logsList =
          (logsResp['content']?['attendanceLogsId'] as List?) ?? [];
      final lastLog = logsList.isNotEmpty ? logsList.last : null;
      final lastType = lastLog != null
          ? (lastLog['punchType']?.toString() ?? '')
          : '';

      // Only upload if currently punched in
      if (lastType.toLowerCase() != 'punchin') {
        return;
      }

      // Get geofence data
      final geofenceDataStr = prefs.getString('geofence_data');
      bool isInside = false;

      if (geofenceDataStr != null) {
        final geofenceData = jsonDecode(geofenceDataStr);
        isInside = _checkGeofenceStatus(position, geofenceData);
      }

      // Notify on geofence status change (background isolate)
      try {
        final prev = prefs.getBool('is_inside_geofence');
        if (prev == null || prev != isInside) {
          await prefs.setBool('is_inside_geofence', isInside);
          await NotificationService.instance.showGeofenceStatusChange(
            isInside: isInside,
          );
        }
      } catch (_) {}

      // Prepare payload
      final date =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final inOut = isInside ? 'In' : 'Out';

      // Prepare location data for queue
      final locationData = {
        'employeeId': employeeId,
        'lat': position.latitude,
        'lon': position.longitude,
        'date': date,
        'time': time,
        'inOut': inOut,
        'tenantId': tenantId,
        'timestamp': now.millisecondsSinceEpoch,
      };

      // Try to upload with retry logic
      bool uploadSuccess = false;
      int maxRetries = 3;
      int retryCount = 0;

      while (retryCount < maxRetries && !uploadSuccess) {
        try {
          await apiService.createEmployeeLocation(
            employeeId: employeeId,
            lat: position.latitude,
            lon: position.longitude,
            date: date,
            time: time,
            inOut: inOut,
            tenantId: tenantId,
          );

          uploadSuccess = true;
          print('✅ Background location uploaded: $date $time (In/Out: $inOut)');

          // Remove from queue if successfully uploaded
          await _removeFromQueue(prefs, locationData);
        } catch (e) {
          retryCount++;
          print(
            '❌ Error uploading location (attempt $retryCount/$maxRetries): $e',
          );

          if (retryCount < maxRetries) {
            // Wait before retry (exponential backoff)
            await Future.delayed(Duration(seconds: retryCount * 2));
          } else {
            // Failed after all retries, add to offline queue
            print(
              '⚠️ Failed to upload after $maxRetries attempts, adding to queue',
            );
            await _addToOfflineQueue(prefs, locationData);
          }
        }
      }

      // Process offline queue periodically
      await _processOfflineQueue(prefs, apiService);
    } catch (e) {
      print('❌ Error in _uploadLocationIfNeeded: $e');
    }
  }

  // Add location to offline queue
  static Future<void> _addToOfflineQueue(
    SharedPreferences prefs,
    Map<String, dynamic> locationData,
  ) async {
    try {
      final queueStr = prefs.getString('location_upload_queue') ?? '[]';
      final queue = jsonDecode(queueStr) as List;

      // Remove duplicates based on timestamp (within 1 minute)
      final timestamp = locationData['timestamp'] as int;
      queue.removeWhere((item) {
        final itemTimestamp = item['timestamp'] as int;
        return (timestamp - itemTimestamp).abs() < 60000; // 1 minute
      });

      queue.add(locationData);

      // Keep only last 100 items to prevent queue from growing too large
      if (queue.length > 100) {
        queue.removeRange(0, queue.length - 100);
      }

      await prefs.setString('location_upload_queue', jsonEncode(queue));
      print('📦 Added location to queue (queue size: ${queue.length})');
    } catch (e) {
      print('❌ Error adding to queue: $e');
    }
  }

  // Remove location from queue after successful upload
  static Future<void> _removeFromQueue(
    SharedPreferences prefs,
    Map<String, dynamic> locationData,
  ) async {
    try {
      final queueStr = prefs.getString('location_upload_queue') ?? '[]';
      final queue = jsonDecode(queueStr) as List;

      final timestamp = locationData['timestamp'] as int;
      queue.removeWhere((item) {
        final itemTimestamp = item['timestamp'] as int;
        return (timestamp - itemTimestamp).abs() < 60000; // 1 minute
      });

      await prefs.setString('location_upload_queue', jsonEncode(queue));
    } catch (e) {
      print('❌ Error removing from queue: $e');
    }
  }

  // Process offline queue and upload pending locations
  static Future<void> _processOfflineQueue(
    SharedPreferences prefs,
    ApiService apiService,
  ) async {
    try {
      final queueStr = prefs.getString('location_upload_queue') ?? '[]';
      final queue = jsonDecode(queueStr) as List;

      if (queue.isEmpty) {
        return;
      }

      print('📦 Processing offline queue (${queue.length} items)');

      final List<Map<String, dynamic>> failedItems = [];

      for (var item in queue) {
        try {
          await apiService.createEmployeeLocation(
            employeeId: item['employeeId'],
            lat: item['lat'],
            lon: item['lon'],
            date: item['date'],
            time: item['time'],
            inOut: item['inOut'],
            tenantId: item['tenantId'],
          );

          print('✅ Uploaded queued location: ${item['date']} ${item['time']}');
        } catch (e) {
          print('❌ Failed to upload queued location: $e');
          failedItems.add(item);
        }
      }

      // Save back only failed items
      await prefs.setString('location_upload_queue', jsonEncode(failedItems));

      if (failedItems.isNotEmpty) {
        print('⚠️ ${failedItems.length} items still in queue');
      } else {
        print('✅ Queue processed successfully');
      }
    } catch (e) {
      print('❌ Error processing queue: $e');
    }
  }

  // Check geofence status
  static bool _checkGeofenceStatus(
    Position position,
    Map<String, dynamic> geofenceData,
  ) {
    try {
      // Check for polygon boundary
      if (geofenceData['boundary'] != null &&
          geofenceData['boundary']['type'] == 'Polygon') {
        return _isPointInPolygon(position, geofenceData['boundary']);
      }
      // Check for circle geofence
      else if (geofenceData['latitude'] != null &&
          geofenceData['longitude'] != null &&
          geofenceData['radius'] != null) {
        final distance = Geolocator.distanceBetween(
          geofenceData['latitude'],
          geofenceData['longitude'],
          position.latitude,
          position.longitude,
        );
        return distance <= geofenceData['radius'];
      }
      return false;
    } catch (e) {
      print('❌ Error checking geofence: $e');
      return false;
    }
  }

  // Check if point is in polygon
  static bool _isPointInPolygon(
    Position position,
    Map<String, dynamic> boundary,
  ) {
    try {
      final coordinates = boundary['coordinates'][0] as List<dynamic>;
      if (coordinates.length < 3) return false;

      final polygonPoints = coordinates.map<List<double>>((coord) {
        final coordList = coord as List<dynamic>;
        return [coordList[0].toDouble(), coordList[1].toDouble()];
      }).toList();

      bool inside = false;
      int j = polygonPoints.length - 1;

      for (int i = 0; i < polygonPoints.length; i++) {
        final xi = polygonPoints[i][0];
        final yi = polygonPoints[i][1];
        final xj = polygonPoints[j][0];
        final yj = polygonPoints[j][1];

        if (((yi > position.latitude) != (yj > position.latitude)) &&
            (position.longitude <
                (xj - xi) * (position.latitude - yi) / (yj - yi) + xi)) {
          inside = !inside;
        }
        j = i;
      }

      return inside;
    } catch (e) {
      print('❌ Error in polygon check: $e');
      return false;
    }
  }
}
