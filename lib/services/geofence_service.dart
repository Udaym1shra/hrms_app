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

      // Start location stream for real-time monitoring
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10, // Update every 10 meters
            ),
          ).listen(
            _onLocationUpdate,
            onError: (error) {
              print('❌ Location stream error: $error');
            },
          );

      // Start periodic geofence checking
      _locationUpdateTimer = Timer.periodic(
        const Duration(seconds: 30), // Check every 30 seconds
        (_) => _checkGeofenceStatus(),
      );

      print('✅ Location monitoring initialized');
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

  // Handle location updates
  void _onLocationUpdate(Position position) {
    _lastKnownPosition = position;
    _saveLastKnownLocation(position);
    _checkGeofenceStatus();
  }

  // Check geofence status
  Future<void> _checkGeofenceStatus() async {
    if (_currentGeofence == null || _lastKnownPosition == null) return;

    try {
      final isInside = await isLocationWithinGeofence(_lastKnownPosition!);

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

      if (response['error'] == false && response['content'] != null) {
        final config = response['content'];

        // Setup geofence with server configuration
        final success = await setupGeofence(
          employeeId: employeeId,
          tenantId: tenantId ?? 0,
          latitude: config['latitude']?.toDouble() ?? 0.0,
          longitude: config['longitude']?.toDouble() ?? 0.0,
          radius: config['radius']?.toDouble() ?? 100.0,
          geofenceName: config['name'] ?? 'Office Location',
        );

        if (success) {
          print('✅ Geofence config loaded from server successfully');
          return true;
        }
      }

      print('⚠️ No geofence config found on server');
      return false;
    } catch (e) {
      print('❌ Error fetching geofence config from server: $e');

      // Check if it's a 404 error (endpoint not implemented)
      if (e.toString().contains('404')) {
        print(
          'ℹ️ Geofencing endpoints not implemented on server yet. Using mock data for testing.',
        );
        return await _setupMockGeofence(employeeId, tenantId);
      }

      return false;
    }
  }

  // Setup mock geofence for testing when server endpoints are not available
  Future<bool> _setupMockGeofence(int employeeId, int? tenantId) async {
    try {
      print('🎯 Setting up mock geofence for testing...');

      // Use a default office location (you can change these coordinates)
      const mockLatitude = 12.9716; // Bangalore coordinates
      const mockLongitude = 77.5946;
      const mockRadius = 100.0; // 100 meters
      const mockName = 'Office Location (Mock)';

      final success = await setupGeofence(
        employeeId: employeeId,
        tenantId: tenantId ?? 0,
        latitude: mockLatitude,
        longitude: mockLongitude,
        radius: mockRadius,
        geofenceName: mockName,
      );

      if (success) {
        print('✅ Mock geofence setup successful for testing');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error setting up mock geofence: $e');
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
      };

      await _saveGeofenceData();

      print('✅ Geofence setup successful');
      return true;
    } catch (e) {
      print('❌ Error setting up geofence: $e');
      return false;
    }
  }

  // Check if current location is within geofence - optimized version
  Future<bool> isLocationWithinGeofence(Position position) async {
    if (_currentGeofence == null) {
      return false;
    }

    try {
      // Check if it's a polygon boundary
      if (_currentGeofence!['boundary'] != null &&
          _currentGeofence!['boundary']['type'] == 'Polygon') {
        return _isPointInPolygonOptimized(position);
      } else {
        // Circle geofence - more efficient calculation
        return _isPointInCircle(position);
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

    // Convert to optimized format once
    final polygonPoints = coordinates.map<List<double>>((coord) {
      final coordList = coord as List<dynamic>;
      return [coordList[0].toDouble(), coordList[1].toDouble()]; // [lon, lat]
    }).toList();

    return _isPointInPolygon(
      position.latitude,
      position.longitude,
      polygonPoints,
    );
  }

  // Optimized ray casting algorithm
  bool _isPointInPolygon(double lat, double lon, List<List<double>> polygon) {
    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i][1]; // latitude
      final yi = polygon[i][0]; // longitude
      final xj = polygon[j][1]; // latitude
      final yj = polygon[j][0]; // longitude

      if (((yi > lon) != (yj > lon)) &&
          (lat < (xj - xi) * (lon - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  // Validate geofence for punch operation
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
        return {
          'isValid': true,
          'message': 'No geofence configured. Punch allowed.',
          'distance': null,
        };
      }

      final isWithin = await isLocationWithinGeofence(position);
      final distance = await _calculateDistanceToGeofence(position);

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

  // Check if currently inside geofence
  bool get isInsideGeofenceStatus => _isInsideGeofence;

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

    final geofence = _currentGeofence!;
    _showDialog(
      context,
      'Geofence Status',
      'Location: ${geofence['name']}\n'
          'Center: ${geofence['latitude'].toStringAsFixed(6)}, ${geofence['longitude'].toStringAsFixed(6)}\n'
          'Radius: ${geofence['radius']}m\n'
          'Status: ${_isInsideGeofence ? 'Inside' : 'Outside'}',
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
