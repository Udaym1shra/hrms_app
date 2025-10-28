import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import 'api_service.dart';

class GeofenceService {
  static const String _geofenceKey = 'geofence_data';
  static const String _lastKnownLocationKey = 'last_known_location';

  // Singleton instance
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  // API service for server communication
  ApiService? _apiService;

  // Stream controllers for geofence events
  final StreamController<GeofenceEvent> _geofenceEventController =
      StreamController<GeofenceEvent>.broadcast();

  final StreamController<bool> _isInsideGeofenceController =
      StreamController<bool>.broadcast();

  // Getters for streams
  Stream<GeofenceEvent> get geofenceEvents => _geofenceEventController.stream;
  Stream<bool> get isInsideGeofence => _isInsideGeofenceController.stream;

  // Current geofence data
  Map<String, dynamic>? _currentGeofence;
  bool _isInsideGeofence = false;
  Position? _lastKnownPosition;

  // Location monitoring
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationUpdateTimer;

  // Set API service
  void setApiService(ApiService apiService) {
    _apiService = apiService;
  }

  // Initialize the geofence service
  Future<void> initialize() async {
    try {
      print('🔧 Initializing GeofenceService...');

      // Load saved geofence data
      await _loadGeofenceData();

      // Load last known location
      await _loadLastKnownLocation();

      // Initialize location monitoring
      await _initializeLocationMonitoring();

      print('✅ GeofenceService initialized successfully');
    } catch (e) {
      print('❌ Error initializing GeofenceService: $e');
    }
  }

  // Initialize location monitoring with optimized settings
  Future<void> _initializeLocationMonitoring() async {
    try {
      // Check permissions first
      if (!await _checkLocationPermissions()) {
        print('⚠️ Location permissions not granted');
        return;
      }

      // Start location stream for real-time monitoring with more frequent updates
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter:
                  5, // Update every 5 meters for better responsiveness
            ),
          ).listen(
            _onLocationUpdate,
            onError: (error) {
              print('❌ Location stream error: $error');
            },
          );

      // Start periodic geofence checking with more frequent updates
      _locationUpdateTimer = Timer.periodic(
        const Duration(
          seconds: 15,
        ), // Check every 15 seconds for better responsiveness
        (_) => _checkGeofenceStatus(),
      );

      print('✅ Location monitoring initialized with enhanced frequency');
    } catch (e) {
      print('❌ Error initializing location monitoring: $e');
    }
  }

  // Check location permissions
  Future<bool> _checkLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('❌ Error checking location permissions: $e');
      return false;
    }
  }

  // Handle location updates with improved consistency
  void _onLocationUpdate(Position position) {
    print(
      '📍 Location update: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
    );

    _lastKnownPosition = position;
    _saveLastKnownLocation(position);

    // Immediately check geofence status for real-time updates
    _checkGeofenceStatus();
  }

  // Check geofence status with improved logging and consistency
  Future<void> _checkGeofenceStatus() async {
    if (_currentGeofence == null || _lastKnownPosition == null) {
      print('⚠️ Cannot check geofence status - missing data');
      return;
    }

    try {
      print(
        '🔍 Checking geofence status for position: ${_lastKnownPosition!.latitude}, ${_lastKnownPosition!.longitude}',
      );

      final isInside = await isLocationWithinGeofence(_lastKnownPosition!);

      print(
        '📊 Geofence check result - Current status: $_isInsideGeofence, New status: $isInside',
      );

      if (isInside != _isInsideGeofence) {
        print(
          '🔄 Geofence status changed from $_isInsideGeofence to $isInside',
        );
        _isInsideGeofence = isInside;
        _isInsideGeofenceController.add(_isInsideGeofence);

        // Emit geofence event
        _geofenceEventController.add(
          GeofenceEvent(
            regionId: _currentGeofence!['regionId'] ?? 'default',
            type: isInside ? GeofenceEventType.enter : GeofenceEventType.exit,
            timestamp: DateTime.now(),
          ),
        );

        print('📡 Geofence event emitted: ${isInside ? "ENTER" : "EXIT"}');
      } else {
        print('✅ Geofence status unchanged: $isInside');
      }
    } catch (e) {
      print('❌ Error checking geofence status: $e');
    }
  }

  // Fetch geofence configuration from server
  Future<bool> fetchGeofenceConfigFromServer({
    required int employeeId,
    int? tenantId,
  }) async {
    if (_apiService == null) {
      print('⚠️ API service not set');
      return false;
    }

    try {
      print(
        '🌐 Fetching geofence config from server for employee: $employeeId',
      );

      final response = await _apiService!.getEmployeeGeofenceConfig(
        employeeId: employeeId,
        tenantId: tenantId,
      );

      print('📡 Server response: ${response.toString()}');

      if (response['error'] == false && response['content'] != null) {
        final content = response['content'];

        // Handle the new API response structure
        if (content['result'] != null && content['result']['data'] != null) {
          final dataList = content['result']['data'] as List;

          if (dataList.isNotEmpty) {
            final geofenceData = dataList.first;

            // Priority 1: Check for polygon boundary first
            if (geofenceData['boundary'] != null &&
                geofenceData['boundary']['type'] == 'Polygon') {
              print('🎯 Setting up polygon geofence from server data');

              // Setup polygon geofence
              final success = await setupPolygonGeofence(
                employeeId: employeeId,
                tenantId: geofenceData['tenantId'] ?? tenantId ?? 0,
                boundary: geofenceData['boundary'],
                geofenceId: geofenceData['id'],
                geofenceName: 'Office Location (Server)',
              );

              if (success) {
                print(
                  '✅ Polygon geofence config loaded from server successfully',
                );
                return true;
              }
            }
            // Priority 2: Fallback to circle geofence only if polygon is not available
            else if (geofenceData['lat'] != null &&
                geofenceData['lon'] != null &&
                geofenceData['radius'] != null) {
              // Handle circle geofence (fallback)
              print(
                '🎯 Setting up circle geofence from server data (fallback)',
              );

              final success = await setupGeofence(
                employeeId: employeeId,
                tenantId: geofenceData['tenantId'] ?? tenantId ?? 0,
                latitude: geofenceData['lat']?.toDouble() ?? 0.0,
                longitude: geofenceData['lon']?.toDouble() ?? 0.0,
                radius: geofenceData['radius']?.toDouble() ?? 100.0,
                geofenceName: 'Office Location (Server)',
              );

              if (success) {
                print(
                  '✅ Circle geofence config loaded from server successfully',
                );
                return true;
              }
            } else {
              print('⚠️ No valid geofence data found in server response');
              print(
                '   - Polygon boundary: ${geofenceData['boundary'] != null ? 'Present' : 'Missing'}',
              );
              print(
                '   - Circle data (lat/lon/radius): ${geofenceData['lat'] != null && geofenceData['lon'] != null && geofenceData['radius'] != null ? 'Present' : 'Missing'}',
              );
            }
          }
        }
      }

      print('⚠️ No valid geofence config found on server');
      return false;
    } catch (e) {
      print('❌ Error fetching geofence config from server: $e');
      return false;
    }
  }

  // Set up geofence for an employee
  Future<bool> setupGeofence({
    required int employeeId,
    required int tenantId,
    required double latitude,
    required double longitude,
    required double radius,
    String? geofenceName,
  }) async {
    try {
      print('🎯 Setting up geofence for employee: $employeeId');

      // Save geofence data
      _currentGeofence = {
        'employeeId': employeeId,
        'tenantId': tenantId,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'name': geofenceName ?? 'Office Location',
        'regionId': 'employee_${employeeId}_tenant_${tenantId}',
        'type': 'circle',
      };

      await _saveGeofenceData();

      print('✅ Geofence setup successful');
      return true;
    } catch (e) {
      print('❌ Error setting up geofence: $e');
      return false;
    }
  }

  // Set up polygon geofence for an employee
  Future<bool> setupPolygonGeofence({
    required int employeeId,
    required int tenantId,
    required Map<String, dynamic> boundary,
    int? geofenceId,
    String? geofenceName,
  }) async {
    try {
      print('🎯 Setting up polygon geofence for employee: $employeeId');

      // Calculate center point from polygon coordinates for display purposes
      final coordinates = boundary['coordinates'][0] as List<dynamic>;
      double totalLat = 0;
      double totalLon = 0;

      for (var coord in coordinates) {
        totalLon += coord[0] as double; // longitude
        totalLat += coord[1] as double; // latitude
      }

      final centerLat = totalLat / coordinates.length;
      final centerLon = totalLon / coordinates.length;

      // Save geofence data with polygon boundary
      _currentGeofence = {
        'employeeId': employeeId,
        'tenantId': tenantId,
        'geofenceId': geofenceId,
        'boundary': boundary,
        'centerLatitude': centerLat,
        'centerLongitude': centerLon,
        'name': geofenceName ?? 'Office Location (Polygon)',
        'regionId': 'employee_${employeeId}_tenant_${tenantId}',
        'type': 'polygon',
      };

      await _saveGeofenceData();

      print('✅ Polygon geofence setup successful');
      print('📍 Center point: $centerLat, $centerLon');
      print('🔢 Polygon points: ${coordinates.length}');
      return true;
    } catch (e) {
      print('❌ Error setting up polygon geofence: $e');
      return false;
    }
  }

  // Check if current location is within geofence - optimized version
  Future<bool> isLocationWithinGeofence(Position position) async {
    if (_currentGeofence == null) {
      return false;
    }

    try {
      // Priority 1: Check for polygon boundary first
      if (_currentGeofence!['boundary'] != null &&
          _currentGeofence!['boundary']['type'] == 'Polygon') {
        print('🔍 Using polygon geofence validation');
        return _isPointInPolygonOptimized(position);
      }
      // Priority 2: Fallback to circle geofence only if polygon is not available
      else if (_currentGeofence!['latitude'] != null &&
          _currentGeofence!['longitude'] != null &&
          _currentGeofence!['radius'] != null) {
        print('🔍 Using circle geofence validation (fallback)');
        return _isPointInCircle(position);
      } else {
        print('⚠️ No valid geofence configuration found');
        return false;
      }
    } catch (e) {
      print('❌ Error checking geofence: $e');
      return false;
    }
  }

  // Optimized circle geofence check
  bool _isPointInCircle(Position position) {
    final centerLat = _currentGeofence!['latitude'] as double;
    final centerLon = _currentGeofence!['longitude'] as double;
    final radius = _currentGeofence!['radius'] as double;

    // Use Haversine formula for accurate distance calculation
    final distance = Geolocator.distanceBetween(
      centerLat,
      centerLon,
      position.latitude,
      position.longitude,
    );

    return distance <= radius;
  }

  // Optimized polygon geofence check with improved ray casting
  bool _isPointInPolygonOptimized(Position position) {
    final coordinates =
        _currentGeofence!['boundary']['coordinates'][0] as List<dynamic>;

    // Convert to optimized format once - Fix coordinate mapping
    final polygonPoints = coordinates.map<List<double>>((coord) {
      final coordList = coord as List<dynamic>;
      return [coordList[0].toDouble(), coordList[1].toDouble()]; // [lon, lat]
    }).toList();

    print(
      '🔍 Checking point (${position.latitude}, ${position.longitude}) against polygon with ${polygonPoints.length} points',
    );
    print(
      '📍 Polygon points: ${polygonPoints.take(3).map((p) => '(${p[0]}, ${p[1]})').join(', ')}...',
    );

    final result = _isPointInPolygon(
      position.latitude,
      position.longitude,
      polygonPoints,
    );

    print('✅ Polygon validation result: $result');
    return result;
  }

  // Fixed ray casting algorithm with proper coordinate handling
  bool _isPointInPolygon(double lat, double lon, List<List<double>> polygon) {
    if (polygon.length < 3) {
      print('⚠️ Polygon has less than 3 points, cannot validate');
      return false;
    }

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i][0]; // longitude
      final yi = polygon[i][1]; // latitude
      final xj = polygon[j][0]; // longitude
      final yj = polygon[j][1]; // latitude

      // Ray casting algorithm with proper coordinate handling
      if (((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  // Validate geofence for punch operation with improved consistency
  Future<Map<String, dynamic>> validateGeofenceForPunch(
    Position? position,
  ) async {
    try {
      print('🔍 Validating geofence for punch operation...');

      if (position == null) {
        return {
          'isValid': false,
          'message':
              'Unable to get your current location. Please enable location services and try again.',
          'distance': null,
        };
      }

      if (_currentGeofence == null) {
        print('ℹ️ No geofence configured. Punch allowed without validation.');
        return {
          'isValid': true,
          'message': 'No geofence configured. Punch allowed.',
          'distance': null,
        };
      }

      print('📍 Current position: ${position.latitude}, ${position.longitude}');
      print('🎯 Geofence type: ${getCurrentGeofenceType()}');

      // Use the same validation logic as real-time monitoring
      final isWithin = await isLocationWithinGeofence(position);
      final distance = await _calculateDistanceToGeofence(position);

      print('🔍 Validation result - Inside: $isWithin, Distance: $distance');

      // Update the internal status to match validation result for consistency
      if (isWithin != _isInsideGeofence) {
        print(
          '🔄 Updating internal geofence status from $_isInsideGeofence to $isWithin',
        );
        _isInsideGeofence = isWithin;
        _isInsideGeofenceController.add(_isInsideGeofence);
      }

      if (isWithin) {
        return {
          'isValid': true,
          'message':
              'Location validated successfully. You are within the designated area.',
          'distance': distance,
        };
      } else {
        return {
          'isValid': false,
          'message':
              'You are outside the designated area. Please move to the office location to punch in/out.',
          'distance': distance,
        };
      }
    } catch (e) {
      print('❌ Error validating geofence: $e');
      return {
        'isValid': true,
        'message': 'Unable to validate geofence. Punch allowed.',
        'distance': null,
      };
    }
  }

  // Calculate distance to geofence center
  Future<double?> _calculateDistanceToGeofence(Position position) async {
    if (_currentGeofence == null) return null;

    try {
      return Geolocator.distanceBetween(
        _currentGeofence!['latitude'],
        _currentGeofence!['longitude'],
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      print('❌ Error calculating distance: $e');
      return null;
    }
  }

  // Get current geofence information
  Map<String, dynamic>? getCurrentGeofence() {
    return _currentGeofence;
  }

  // Get current geofence type for debugging
  String getCurrentGeofenceType() {
    if (_currentGeofence == null) return 'None';

    if (_currentGeofence!['boundary'] != null &&
        _currentGeofence!['boundary']['type'] == 'Polygon') {
      return 'Polygon';
    } else if (_currentGeofence!['latitude'] != null &&
        _currentGeofence!['longitude'] != null &&
        _currentGeofence!['radius'] != null) {
      return 'Circle';
    } else {
      return 'Unknown';
    }
  }

  // Check if geofencing is enabled/configured
  bool get isGeofencingEnabled => _currentGeofence != null;

  // Check if currently inside geofence
  bool get isInsideGeofenceStatus => _isInsideGeofence;

  // Force refresh geofence status with current location
  Future<void> refreshGeofenceStatus(Position position) async {
    if (_currentGeofence == null) return;

    try {
      final isInside = await isLocationWithinGeofence(position);

      if (isInside != _isInsideGeofence) {
        _isInsideGeofence = isInside;
        _isInsideGeofenceController.add(_isInsideGeofence);

        // Emit geofence event
        _geofenceEventController.add(
          GeofenceEvent(
            regionId: _currentGeofence!['regionId'] ?? 'default',
            type: isInside ? GeofenceEventType.enter : GeofenceEventType.exit,
            timestamp: DateTime.now(),
          ),
        );
      }

      // Update last known position
      _lastKnownPosition = position;
      await _saveLastKnownLocation(position);

      print('✅ Geofence status refreshed: ${isInside ? "Inside" : "Outside"}');
    } catch (e) {
      print('❌ Error refreshing geofence status: $e');
    }
  }

  // Check if geofencing is supported on this device
  Future<bool> isGeofencingSupported() async {
    try {
      // Check if location services are available
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Error checking geofencing support: $e');
      return false;
    }
  }

  // Setup custom geofence for testing
  Future<bool> setupCustomGeofence({
    required int employeeId,
    required int tenantId,
    required double latitude,
    required double longitude,
    required double radius,
    String? name,
  }) async {
    try {
      print('🎯 Setting up custom geofence for employee: $employeeId');

      final success = await setupGeofence(
        employeeId: employeeId,
        tenantId: tenantId,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        geofenceName: name ?? 'Custom Office Location',
      );

      if (success) {
        print('✅ Custom geofence setup successful');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error setting up custom geofence: $e');
      return false;
    }
  }

  // Remove current geofence
  Future<void> removeGeofence() async {
    try {
      if (_currentGeofence != null) {
        _currentGeofence = null;
        await _saveGeofenceData();
        print('✅ Geofence removed successfully');
      }
    } catch (e) {
      print('❌ Error removing geofence: $e');
    }
  }

  // Save geofence data to shared preferences
  Future<void> _saveGeofenceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentGeofence != null) {
        await prefs.setString(_geofenceKey, jsonEncode(_currentGeofence));
      } else {
        await prefs.remove(_geofenceKey);
      }
    } catch (e) {
      print('❌ Error saving geofence data: $e');
    }
  }

  // Load geofence data from shared preferences
  Future<void> _loadGeofenceData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final geofenceData = prefs.getString(_geofenceKey);
      if (geofenceData != null) {
        _currentGeofence = jsonDecode(geofenceData);
        print('✅ Geofence data loaded: ${_currentGeofence!['name']}');
      }
    } catch (e) {
      print('❌ Error loading geofence data: $e');
    }
  }

  // Save last known location
  Future<void> _saveLastKnownLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.millisecondsSinceEpoch,
        'accuracy': position.accuracy,
      };
      await prefs.setString(_lastKnownLocationKey, jsonEncode(locationData));
    } catch (e) {
      print('❌ Error saving last known location: $e');
    }
  }

  // Load last known location
  Future<void> _loadLastKnownLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationData = prefs.getString(_lastKnownLocationKey);
      if (locationData != null) {
        final data = jsonDecode(locationData);
        _lastKnownPosition = Position(
          latitude: data['latitude'],
          longitude: data['longitude'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
          accuracy: data['accuracy'],
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        print('✅ Last known location loaded');
      }
    } catch (e) {
      print('❌ Error loading last known location: $e');
    }
  }

  // Update last known location
  Future<void> updateLastKnownLocation(Position position) async {
    _lastKnownPosition = position;
    await _saveLastKnownLocation(position);
  }

  // Get last known location
  Position? get lastKnownLocation => _lastKnownPosition;

  // Show geofence status dialog
  void showGeofenceStatusDialog(BuildContext context) {
    if (_currentGeofence == null) {
      _showDialog(
        context,
        'No Geofence',
        'No geofence is currently configured for this employee.',
        Icons.location_off,
        AppTheme.warningColor,
      );
      return;
    }

    String statusText =
        'Status: ${_isInsideGeofence ? 'Inside Office Area' : 'Outside Office Area'}';

    _showDialog(
      context,
      'Geofence Status',
      statusText,
      _isInsideGeofence ? Icons.location_on : Icons.location_off,
      _isInsideGeofence ? AppTheme.successColor : AppTheme.warningColor,
    );
  }

  // Show dialog helper
  void _showDialog(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Debug method to log current geofence state
  void debugGeofenceState() {
    print('🔍 === GEOFENCE DEBUG STATE ===');
    print(
      '📍 Current geofence: ${_currentGeofence != null ? "Configured" : "Not configured"}',
    );
    print('📍 Inside geofence: $_isInsideGeofence');
    print(
      '📍 Last known position: ${_lastKnownPosition?.latitude}, ${_lastKnownPosition?.longitude}',
    );
    print('📍 Geofence type: ${getCurrentGeofenceType()}');

    if (_currentGeofence != null) {
      if (_currentGeofence!['boundary'] != null) {
        print(
          '📍 Polygon coordinates: ${_currentGeofence!['boundary']['coordinates'][0].length} points',
        );
      } else {
        print(
          '📍 Circle center: ${_currentGeofence!['latitude']}, ${_currentGeofence!['longitude']}',
        );
        print('📍 Circle radius: ${_currentGeofence!['radius']} meters');
      }
    }
    print('🔍 === END DEBUG STATE ===');
  }

  // Dispose resources properly
  void dispose() {
    _positionStreamSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _geofenceEventController.close();
    _isInsideGeofenceController.close();
  }
}

// Geofence event model
class GeofenceEvent {
  final String regionId;
  final GeofenceEventType type;
  final DateTime timestamp;

  GeofenceEvent({
    required this.regionId,
    required this.type,
    required this.timestamp,
  });
}

// Geofence event types
enum GeofenceEventType { enter, exit }
