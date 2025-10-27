import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:geolocator/geolocator.dart' as geolocator;
import '../utils/app_theme.dart';
import '../services/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadGeofenceConfig();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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

  Future<void> _getCurrentLocation() async {
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

      geolocator.Position position =
          await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.high,
          );

      _safeSetState(() {
        _currentPosition = position;
        _checkGeofenceStatus();
        _isLoading = false;
      });
    } catch (e) {
      _safeSetState(() {
        _error = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  void _checkGeofenceStatus() {
    if (_currentPosition == null || _geofenceConfig == null) return;

    final userLat = _currentPosition!.latitude;
    final userLon = _currentPosition!.longitude;

    bool isInside = false;

    // Check if it's a polygon boundary
    if (_geofenceConfig!['boundary'] != null &&
        _geofenceConfig!['boundary']['type'] == 'Polygon') {
      print('🔍 Checking polygon geofence with coordinates:');
      print('User position: Lat: $userLat, Lon: $userLon');
      print(
        'Polygon coordinates: ${_geofenceConfig!['boundary']['coordinates'][0]}',
      );

      // Convert dynamic coordinates to List<List<double>>
      final coordinates =
          _geofenceConfig!['boundary']['coordinates'][0] as List<dynamic>;
      final polygonCoords = coordinates.map<List<double>>((coord) {
        final coordList = coord as List<dynamic>;
        return [coordList[0].toDouble(), coordList[1].toDouble()]; // [lon, lat]
      }).toList();

      isInside = _isPointInPolygon(userLat, userLon, polygonCoords);

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
      }
    }

    _safeSetState(() {
      _isInsideGeofence = isInside;
      _updateMapDisplay();
    });
  }

  // Check if a point is inside a polygon using ray casting algorithm
  bool _isPointInPolygon(double lat, double lon, List<List<double>> polygon) {
    int intersections = 0;
    int n = polygon.length;

    for (int i = 0; i < n; i++) {
      double x1 = polygon[i][1]; // latitude (second element)
      double y1 = polygon[i][0]; // longitude (first element)
      double x2 = polygon[(i + 1) % n][1]; // latitude (second element)
      double y2 = polygon[(i + 1) % n][0]; // longitude (first element)

      // Check if the ray from the point intersects with the edge
      if (((x1 > lat) != (x2 > lat)) &&
          (lon < (y2 - y1) * (lat - x1) / (x2 - x1) + y1)) {
        intersections++;
      }
    }

    return intersections % 2 == 1;
  }

  // Update map display with geofence and current location
  void _updateMapDisplay() {
    // Use current position for map display
    if (_currentPosition != null) {
      _currentLocationPoint = latlong.LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }

    if (_geofenceConfig == null) return;

    _polygonPoints.clear();

    // Add geofence polygon if available
    if (_geofenceConfig!['boundary'] != null &&
        _geofenceConfig!['boundary']['type'] == 'Polygon') {
      final coordinates =
          _geofenceConfig!['boundary']['coordinates'][0] as List<dynamic>;

      // Convert polygon coordinates to LatLng list
      for (final coord in coordinates) {
        final coordList = coord as List<dynamic>;
        final lat = coordList[1].toDouble(); // latitude
        final lon = coordList[0].toDouble(); // longitude
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
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: AppTheme.errorColor),
                        textAlign: TextAlign.center,
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
                    children: [
                      Icon(
                        Icons.warning_outlined,
                        color: AppTheme.warningColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No geofence configuration found',
                        style: TextStyle(color: AppTheme.warningColor),
                        textAlign: TextAlign.center,
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

                          // Polygon layer for geofence with improved colors
                          if (_polygonPoints.isNotEmpty)
                            PolygonLayer(
                              polygons: [
                                Polygon(
                                  points: _polygonPoints,
                                  color: AppTheme.getGeofenceStatusColor(
                                    _isInsideGeofence,
                                  ).withOpacity(0.2),
                                  borderColor: AppTheme.getGeofenceStatusColor(
                                    _isInsideGeofence,
                                  ),
                                  borderStrokeWidth: 3.0,
                                  isFilled: true,
                                ),
                              ],
                            ),

                          // Circle layer for circular geofence with improved colors
                          if (_polygonPoints.isEmpty && _geofenceConfig != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _mapCenter!,
                                  radius:
                                      _geofenceConfig!['radius']?.toDouble() ??
                                      100,
                                  color: AppTheme.getGeofenceStatusColor(
                                    _isInsideGeofence,
                                  ).withOpacity(0.2),
                                  borderStrokeWidth: 3,
                                  borderColor: AppTheme.getGeofenceStatusColor(
                                    _isInsideGeofence,
                                  ),
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

              // Geofence Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Geofence Configuration',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Check if it's a polygon or circle
                    if (_geofenceConfig!['boundary'] != null &&
                        _geofenceConfig!['boundary']['type'] == 'Polygon') ...[
                      _buildInfoRow('Type', 'Polygon'),
                      _buildInfoRow(
                        'Vertices',
                        '${_geofenceConfig!['boundary']['coordinates'][0].length} points',
                      ),
                      _buildInfoRow('Area', 'Custom Polygon'),

                      // Show polygon coordinates
                      const SizedBox(height: 8),
                      Text(
                        'Polygon Coordinates:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: _geofenceConfig!['boundary']['coordinates'][0]
                              .map<Widget>(
                                (coord) => Text(
                                  'Lon: ${coord[0].toStringAsFixed(6)}, Lat: ${coord[1].toStringAsFixed(6)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontFamily: 'monospace',
                                      ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ] else ...[
                      _buildInfoRow(
                        'Center',
                        '${_geofenceConfig!['lat']?.toStringAsFixed(4) ?? 'N/A'}, ${_geofenceConfig!['lon']?.toStringAsFixed(4) ?? 'N/A'}',
                      ),
                      _buildInfoRow(
                        'Radius',
                        '${_geofenceConfig!['radius']?.toString() ?? 'N/A'} meters',
                      ),
                      _buildInfoRow('Type', 'Circle'),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Refresh Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _safeSetState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadGeofenceConfig();
                          _getCurrentLocation();
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
