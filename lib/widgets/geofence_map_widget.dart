import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart' as geolocator;
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../services/geofence_service.dart';
import '../../utils/session_storage.dart';

class GeofenceMapWidget extends StatefulWidget {
  final int employeeId;
  final int tenantId;
  final ApiService apiService;

  const GeofenceMapWidget({
    Key? key,
    required this.employeeId,
    required this.tenantId,
    required this.apiService,
  }) : super(key: key);

  @override
  State<GeofenceMapWidget> createState() => _GeofenceMapWidgetState();
}

class _GeofenceMapWidgetState extends State<GeofenceMapWidget> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _geofenceConfig;
  geolocator.Position? _currentPosition;
  bool _isInsideGeofence = false;
  bool _isDisposed = false;

  // Flutter Map related variables
  latlong.LatLng? _mapCenter;
  List<latlong.LatLng> _polygonPoints = [];
  latlong.LatLng? _currentLocationPoint;
  MapController? _mapController;

  // Location stream subscription for live tracking
  StreamSubscription<geolocator.Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadGeofenceConfig();
    _startLocationTracking();

    // Listen to GeofenceService for real-time updates
    _listenToGeofenceService();
  }

  // Listen to GeofenceService for consistent status updates
  void _listenToGeofenceService() {
    final geofenceService = GeofenceService();

    // Listen to geofence status changes
    geofenceService.isInsideGeofence.listen((isInside) {
      if (mounted) {
        print('🔄 GeofenceMapWidget received status update: $isInside');
        _safeSetState(() {
          _isInsideGeofence = isInside;
          _updateMapDisplay();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh geofence status when dependencies change
    if (_currentPosition != null) {
      _checkGeofenceStatus();
    }
  }

  // Helper method to safely call setState
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  Future<void> _loadGeofenceConfig() async {
    try {
      final tenantId = await SessionStorage.getTenantId();
      print('Using tenantId from SessionStorage: $tenantId');

      final response = await widget.apiService.getGeofencingConfig(
        tenantId: tenantId,
        branchId: null,
      );

      if (response['error'] == false && response['content'] != null) {
        final result = response['content']['result'];
        if (result != null &&
            result['data'] != null &&
            result['data'].isNotEmpty) {
          _safeSetState(() {
            _geofenceConfig = result['data'][0];
            _isLoading = false;
          });
          _updateMapDisplay();

          // Sync loaded config into shared GeofenceService for consistency
          await _syncConfigToService();
          // After syncing config, refresh inside/outside status in service
          if (_currentPosition != null) {
            final service = GeofenceService();
            await service.refreshGeofenceStatus(_currentPosition!);
          }
        }
      } else {
        _safeSetState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _safeSetState(() {
        _error = 'Failed to load geofence config: $e';
        _isLoading = false;
      });
    }
  }

  // Start continuous location tracking
  Future<void> _startLocationTracking() async {
    try {
      geolocator.LocationPermission permission =
          await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
      }

      if (permission == geolocator.LocationPermission.deniedForever) {
        _safeSetState(() {
          _error = 'Location permission permanently denied';
          _isLoading = false;
        });
        return;
      }

      // Get initial position first
      geolocator.Position initialPosition =
          await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.high,
          );

      _safeSetState(() {
        _currentPosition = initialPosition;
        _checkGeofenceStatus();
        _isLoading = false;
      });

      // Set up continuous location stream
      _positionStreamSubscription =
          geolocator.Geolocator.getPositionStream(
            locationSettings: const geolocator.LocationSettings(
              accuracy: geolocator.LocationAccuracy.high,
              distanceFilter: 10, // Update every 10 meters
            ),
          ).listen(
            (geolocator.Position position) {
              print(
                '📍 Location updated: ${position.latitude}, ${position.longitude}',
              );
              if (!mounted || _isDisposed) return;

              // Update position and map display in a single setState
              _safeSetState(() {
                _currentPosition = position;
                // Update map display with new location
                if (_currentPosition != null) {
                  _currentLocationPoint = latlong.LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  );
                }
                // Check geofence status and update display
                if (_currentPosition != null && _geofenceConfig != null) {
                  final userLat = _currentPosition!.latitude;
                  final userLon = _currentPosition!.longitude;
                  bool isInside = false;

                  // Check if it's a polygon boundary
                  if (_geofenceConfig!['boundary'] != null &&
                      _geofenceConfig!['boundary']['type'] == 'Polygon') {
                    // Server provides boundary coordinates as [longitude, latitude]
                    final coordinates =
                        _geofenceConfig!['boundary']['coordinates'][0]
                            as List<dynamic>;
                    final polygonCoords = coordinates.map<List<double>>((
                      coord,
                    ) {
                      final coordList = coord as List<dynamic>;
                      // Keep [lon, lat] format as received from server
                      return [coordList[0].toDouble(), coordList[1].toDouble()];
                    }).toList();
                    isInside = _isPointInPolygonConsistent(
                      userLat,
                      userLon,
                      polygonCoords,
                    );
                  } else {
                    final geofenceLat =
                        _geofenceConfig!['lat']?.toDouble() ?? 0.0;
                    final geofenceLon =
                        _geofenceConfig!['lon']?.toDouble() ?? 0.0;
                    final radius =
                        _geofenceConfig!['radius']?.toDouble() ?? 0.0;
                    if (geofenceLat != 0.0 &&
                        geofenceLon != 0.0 &&
                        radius > 0) {
                      final distance = geolocator.Geolocator.distanceBetween(
                        userLat,
                        userLon,
                        geofenceLat,
                        geofenceLon,
                      );
                      isInside = distance <= radius;
                    }
                  }
                  _isInsideGeofence = isInside;
                }
              });
            },
            onError: (error) {
              print('❌ Location stream error: $error');
              if (mounted && !_isDisposed) {
                _safeSetState(() {
                  _error = 'Location tracking error: $error';
                });
              }
            },
          );
    } catch (e) {
      _safeSetState(() {
        _error = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  // Get current location (for refresh button)
  Future<void> _getCurrentLocation() async {
    try {
      geolocator.Position position =
          await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.high,
          );

      _safeSetState(() {
        _currentPosition = position;
        _checkGeofenceStatus();
      });
    } catch (e) {
      _safeSetState(() {
        _error = 'Error getting location: $e';
      });
    }
  }

  void _checkGeofenceStatus() {
    if (_currentPosition == null || _geofenceConfig == null) return;

    final userLat = _currentPosition!.latitude;
    final userLon = _currentPosition!.longitude;

    print('🔍 GeofenceMapWidget checking status for: $userLat, $userLon');

    bool isInside = false;

    // Check if it's a polygon boundary
    if (_geofenceConfig!['boundary'] != null &&
        _geofenceConfig!['boundary']['type'] == 'Polygon') {
      print('🔍 Using GeofenceService for polygon validation');

      // Convert dynamic coordinates to List<List<double>>
      // Server provides boundary coordinates as [longitude, latitude] format
      final coordinates =
          _geofenceConfig!['boundary']['coordinates'][0] as List<dynamic>;
      final polygonCoords = coordinates.map<List<double>>((coord) {
        final coordList = coord as List<dynamic>;
        // Keep [lon, lat] format as received from server
        return [coordList[0].toDouble(), coordList[1].toDouble()]; // [lon, lat]
      }).toList();

      // Use the same algorithm as GeofenceService
      isInside = _isPointInPolygonConsistent(userLat, userLon, polygonCoords);
      print('🔍 Polygon geofence result: $isInside');
    } else {
      // Fallback to circle geofence
      final geofenceLat = _geofenceConfig!['lat']?.toDouble() ?? 0.0;
      final geofenceLon = _geofenceConfig!['lon']?.toDouble() ?? 0.0;
      final radius = _geofenceConfig!['radius']?.toDouble() ?? 0.0;

      if (geofenceLat != 0.0 && geofenceLon != 0.0 && radius > 0) {
        final distance = geolocator.Geolocator.distanceBetween(
          userLat,
          userLon,
          geofenceLat,
          geofenceLon,
        );
        isInside = distance <= radius;
        print(
          '🔍 Circle geofence result: $isInside (distance: $distance, radius: $radius)',
        );
      }
    }

    _safeSetState(() {
      _isInsideGeofence = isInside;
      _updateMapDisplay();
    });

    // Also refresh status in shared GeofenceService so other widgets get updated
    final service = GeofenceService();
    service.refreshGeofenceStatus(_currentPosition!);
  }

  // Consistent polygon validation algorithm matching GeofenceService
  // Note: polygon parameter expects coordinates in [lon, lat] format (as received from server)
  // polygon[i][0] = longitude, polygon[i][1] = latitude
  bool _isPointInPolygonConsistent(
    double lat, // User's latitude
    double lon, // User's longitude
    List<List<double>> polygon, // Polygon coordinates in [lon, lat] format
  ) {
    if (polygon.length < 3) {
      print('⚠️ Polygon has less than 3 points, cannot validate');
      return false;
    }

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      // Server provides coordinates as [longitude, latitude]
      final xi = polygon[i][0]; // longitude from server
      final yi = polygon[i][1]; // latitude from server
      final xj = polygon[j][0]; // longitude from server
      final yj = polygon[j][1]; // latitude from server

      // Ray casting algorithm with proper coordinate handling
      // Compares latitude values (yi, yj) with user's latitude
      // Compares longitude values (xi, xj) with user's longitude
      if (((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Update map display with geofence and current location
  void _updateMapDisplay() {
    // Use current position for map display
    if (_currentPosition != null) {
      final newLocationPoint = latlong.LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      // Only update if location actually changed
      if (_currentLocationPoint == null ||
          _currentLocationPoint!.latitude != newLocationPoint.latitude ||
          _currentLocationPoint!.longitude != newLocationPoint.longitude) {
        _currentLocationPoint = newLocationPoint;
        print(
          '🗺️ Map location updated to: ${_currentLocationPoint!.latitude}, ${_currentLocationPoint!.longitude}',
        );
      }
    }

    if (_geofenceConfig == null) return;

    _polygonPoints.clear();

    // Add geofence polygon if available
    if (_geofenceConfig!['boundary'] != null &&
        _geofenceConfig!['boundary']['type'] == 'Polygon') {
      final coordinates =
          _geofenceConfig!['boundary']['coordinates'][0] as List<dynamic>;

      // Convert polygon coordinates to LatLng list for map display
      // Server provides coordinates as [longitude, latitude]
      for (final coord in coordinates) {
        final coordList = coord as List<dynamic>;
        // Extract: coordList[0] = longitude, coordList[1] = latitude
        final lon = coordList[0].toDouble(); // longitude from server
        final lat = coordList[1].toDouble(); // latitude from server
        // LatLng constructor expects (latitude, longitude)
        _polygonPoints.add(latlong.LatLng(lat, lon));
      }

      // Set map center to polygon center
      if (_polygonPoints.isNotEmpty) {
        double totalLat = 0;
        double totalLon = 0;
        for (final point in _polygonPoints) {
          totalLat += point.latitude;
          totalLon += point.longitude;
        }
        _mapCenter = latlong.LatLng(
          totalLat / _polygonPoints.length,
          totalLon / _polygonPoints.length,
        );
      }
    } else {
      // Circle geofence
      final geofenceLat = _geofenceConfig!['lat']?.toDouble() ?? 0.0;
      final geofenceLon = _geofenceConfig!['lon']?.toDouble() ?? 0.0;
      final radius = _geofenceConfig!['radius']?.toDouble() ?? 0.0;

      if (geofenceLat != 0.0 && geofenceLon != 0.0 && radius > 0) {
        _mapCenter = latlong.LatLng(geofenceLat, geofenceLon);
      }
    }

    // If no geofence center, use current location
    if (_mapCenter == null && _currentLocationPoint != null) {
      _mapCenter = _currentLocationPoint;
    }
  }

  // Zoom to current location
  void _zoomToCurrentLocation() {
    if (_currentLocationPoint != null && _mapController != null) {
      _mapController!.move(_currentLocationPoint!, 18.0);
      print(
        '📍 Zoomed to current location: ${_currentLocationPoint!.latitude}, ${_currentLocationPoint!.longitude}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Geofence Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_geofenceConfig != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getGeofenceStatusLightColor(
                        _isInsideGeofence,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.getGeofenceStatusColor(
                          _isInsideGeofence,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _isInsideGeofence ? 'Inside' : 'Outside',
                      style: TextStyle(
                        color: AppTheme.getGeofenceStatusColor(
                          _isInsideGeofence,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your current location relative to the configured geofence.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // Loading or Error State
            if (_isLoading)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading geofence data...'),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: Text(
                          _error!,
                          style: TextStyle(color: AppTheme.errorColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_mapCenter == null)
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: AppTheme.warningColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: Text(
                          'No geofence configuration found',
                          style: TextStyle(color: AppTheme.warningColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Geofence Status with improved colors
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.getGeofenceStatusLightColor(
                    _isInsideGeofence,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.getGeofenceStatusColor(
                      _isInsideGeofence,
                    ).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isInsideGeofence
                          ? Icons.location_on
                          : Icons.location_off,
                      color: AppTheme.getGeofenceStatusColor(_isInsideGeofence),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isInsideGeofence
                                ? 'Inside Office Area'
                                : 'Outside Office Area',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.getGeofenceStatusColor(
                                    _isInsideGeofence,
                                  ),
                                ),
                          ),
                          if (_currentLocationPoint != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Location: ${_currentLocationPoint!.latitude.toStringAsFixed(4)}, ${_currentLocationPoint!.longitude.toStringAsFixed(4)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // OpenStreetMap with Flutter Map
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _mapCenter!,
                          initialZoom: 16.0,
                        ),
                        children: [
                          // OpenStreetMap tiles
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.testingapp',
                          ),

                          // Polygon layer for geofence with green boundary
                          if (_polygonPoints.isNotEmpty)
                            PolygonLayer(
                              polygons: [
                                Polygon(
                                  points: _polygonPoints,
                                  color: Colors.green.withOpacity(
                                    0.2,
                                  ), // Light green fill
                                  borderColor: Colors.green, // Green boundary
                                  borderStrokeWidth: 3.0,
                                  isFilled: true,
                                ),
                              ],
                            ),

                          // Circle layer for circular geofence with green boundary
                          if (_polygonPoints.isEmpty && _geofenceConfig != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _mapCenter!,
                                  radius:
                                      _geofenceConfig!['radius']?.toDouble() ??
                                      100,
                                  color: Colors.green.withOpacity(
                                    0.2,
                                  ), // Light green fill
                                  borderStrokeWidth: 3,
                                  borderColor: Colors.green, // Green boundary
                                ),
                              ],
                            ),

                          // Marker layer for current location with improved colors
                          if (_currentLocationPoint != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _currentLocationPoint!,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on,
                                    color: AppTheme.getGeofenceStatusColor(
                                      _isInsideGeofence,
                                    ),
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Current Location Button
                      if (_currentLocationPoint != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: FloatingActionButton.small(
                            onPressed: _zoomToCurrentLocation,
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Refresh Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          _safeSetState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          await _loadGeofenceConfig();
                          await _getCurrentLocation();
                          await _syncConfigToService();
                          if (_currentPosition != null) {
                            final service = GeofenceService();
                            await service.refreshGeofenceStatus(
                              _currentPosition!,
                            );
                          }
                          _safeSetState(() {
                            _isLoading = false;
                          });
                        },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Helper to sync current widget geofence config into the shared service
extension on _GeofenceMapWidgetState {
  Future<void> _syncConfigToService() async {
    try {
      if (_geofenceConfig == null) return;
      final service = GeofenceService();
      service.setApiService(widget.apiService);

      // Prefer polygon if available; else circle
      if (_geofenceConfig!['boundary'] != null &&
          _geofenceConfig!['boundary']['type'] == 'Polygon') {
        await service.setupPolygonGeofence(
          employeeId: widget.employeeId,
          tenantId: _geofenceConfig!['tenantId'] ?? widget.tenantId,
          boundary: _geofenceConfig!['boundary'],
          geofenceId: _geofenceConfig!['id'],
          geofenceName: 'Office Location',
        );
      } else if (_geofenceConfig!['lat'] != null &&
          _geofenceConfig!['lon'] != null &&
          _geofenceConfig!['radius'] != null) {
        await service.setupGeofence(
          employeeId: widget.employeeId,
          tenantId: _geofenceConfig!['tenantId'] ?? widget.tenantId,
          latitude: _geofenceConfig!['lat']?.toDouble() ?? 0.0,
          longitude: _geofenceConfig!['lon']?.toDouble() ?? 0.0,
          radius: _geofenceConfig!['radius']?.toDouble() ?? 100.0,
          geofenceName: 'Office Location',
        );
      }
    } catch (e) {
      // Do not surface to UI; just log
      // ignore: avoid_print
      print('❌ Error syncing config to GeofenceService: $e');
    }
  }
}
