import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/session_storage.dart';

class EmployeeLocationMapWidget extends StatefulWidget {
  final int employeeId;
  final ApiService apiService;

  const EmployeeLocationMapWidget({
    Key? key,
    required this.employeeId,
    required this.apiService,
  }) : super(key: key);

  @override
  State<EmployeeLocationMapWidget> createState() =>
      _EmployeeLocationMapWidgetState();
}

class _EmployeeLocationMapWidgetState extends State<EmployeeLocationMapWidget> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _locationPoints = [];
  MapController? _mapController;
  latlong.LatLng? _mapCenter;

  // Geofence boundary data
  Map<String, dynamic>? _geofenceConfig;
  List<latlong.LatLng> _polygonPoints = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadLocationPoints();
    _loadGeofenceConfig();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadLocationPoints() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final date =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final resp = await widget.apiService.getEmployeeLocationList(
        employeeId: widget.employeeId,
        date: date,
        limit: 100,
        page: 1,
      );

      // Parse response: { error: false, content: { result: { data: [...] } } }
      if (resp['error'] == false && resp['content'] != null) {
        final content = resp['content'];
        if (content['result'] != null && content['result']['data'] != null) {
          final data = content['result']['data'];
          if (data is List) {
            final points = data
                .whereType<Map>()
                .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
                .cast<Map<String, dynamic>>()
                .toList();

            setState(() {
              _locationPoints = points;
              _isLoading = false;
            });

            _calculateMapCenter();
            _updateGeofenceBoundary();
            // ignore: avoid_print
            print('✅ Loaded ${_locationPoints.length} location points');
          } else {
            setState(() {
              _locationPoints = [];
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _locationPoints = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = resp['message']?.toString() ?? 'Failed to load locations';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading locations: $e';
        _isLoading = false;
      });
    }
  }

  // Load geofence configuration
  Future<void> _loadGeofenceConfig() async {
    try {
      final tenantId = await SessionStorage.getTenantId();
      if (tenantId == null) return;

      final response = await widget.apiService.getGeofencingConfig(
        tenantId: tenantId,
        branchId: null,
      );

      if (response['error'] == false && response['content'] != null) {
        final result = response['content']['result'];
        if (result != null &&
            result['data'] != null &&
            result['data'].isNotEmpty) {
          setState(() {
            _geofenceConfig = result['data'][0];
          });
          _updateGeofenceBoundary();
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error loading geofence config: $e');
    }
  }

  // Update geofence boundary points
  void _updateGeofenceBoundary() {
    if (_geofenceConfig == null) return;

    _polygonPoints.clear();

    // Check for polygon boundary
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

      // Update map center if no location points
      if (_polygonPoints.isNotEmpty && _locationPoints.isEmpty) {
        double totalLat = 0;
        double totalLon = 0;
        for (final point in _polygonPoints) {
          totalLat += point.latitude;
          totalLon += point.longitude;
        }
        setState(() {
          _mapCenter = latlong.LatLng(
            totalLat / _polygonPoints.length,
            totalLon / _polygonPoints.length,
          );
        });
      }
    }
  }

  void _calculateMapCenter() {
    if (_locationPoints.isEmpty) {
      // Default center (you can change this to your default location)
      _mapCenter = const latlong.LatLng(
        12.9716,
        77.5946,
      ); // Default to a location
      return;
    }

    double totalLat = 0;
    double totalLon = 0;
    int validPoints = 0;

    for (final location in _locationPoints) {
      final lat = double.tryParse(location['lat']?.toString() ?? '0');
      final lon = double.tryParse(location['lon']?.toString() ?? '0');

      if (lat != null && lon != null && lat != 0 && lon != 0) {
        totalLat += lat;
        totalLon += lon;
        validPoints++;
      }
    }

    if (validPoints > 0) {
      setState(() {
        _mapCenter = latlong.LatLng(
          totalLat / validPoints,
          totalLon / validPoints,
        );
      });
    } else {
      _mapCenter = const latlong.LatLng(12.9716, 77.5946);
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
                Icon(Icons.map, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Location Tracking Map',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _loadLocationPoints();
                          _loadGeofenceConfig();
                        },
                  tooltip: 'Refresh locations',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'All location points recorded today',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),

            // Legend
            if (_locationPoints.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_pin, color: Colors.green, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'In (${_locationPoints.where((p) => (p['inOut']?.toString().toLowerCase() ?? '') == 'in').length})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_pin, color: Colors.red, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      'Out (${_locationPoints.where((p) => (p['inOut']?.toString().toLowerCase() ?? '') == 'out').length})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      'Total: ${_locationPoints.length} points',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            if (_locationPoints.isNotEmpty) const SizedBox(height: 12),

            // Map or Loading/Error State
            if (_isLoading)
              Container(
                height: 400,
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
                      Text('Loading location points...'),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              Container(
                height: 400,
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
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadLocationPoints,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_locationPoints.isEmpty)
              Container(
                height: 400,
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
                        Icons.location_off,
                        color: AppTheme.warningColor,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No location points found for today',
                        style: TextStyle(color: AppTheme.warningColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_mapCenter != null)
              Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _mapCenter!,
                      initialZoom: 15.0,
                    ),
                    children: [
                      // OpenStreetMap tiles
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.qreams.hrms',
                      ),

                      // Polygon layer for geofence boundary
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

                      // Circle layer for circular geofence boundary
                      if (_polygonPoints.isEmpty &&
                          _geofenceConfig != null &&
                          _geofenceConfig!['lat'] != null &&
                          _geofenceConfig!['lon'] != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: latlong.LatLng(
                                _geofenceConfig!['lat']?.toDouble() ?? 0.0,
                                _geofenceConfig!['lon']?.toDouble() ?? 0.0,
                              ),
                              radius:
                                  _geofenceConfig!['radius']?.toDouble() ?? 100,
                              color: Colors.green.withOpacity(
                                0.2,
                              ), // Light green fill
                              borderStrokeWidth: 3,
                              borderColor: Colors.green, // Green boundary
                            ),
                          ],
                        ),

                      // Marker layer for all location points
                      MarkerLayer(
                        markers: _locationPoints
                            .map((location) {
                              final lat =
                                  double.tryParse(
                                    location['lat']?.toString() ?? '0',
                                  ) ??
                                  0.0;
                              final lon =
                                  double.tryParse(
                                    location['lon']?.toString() ?? '0',
                                  ) ??
                                  0.0;
                              final inOut = location['inOut']?.toString() ?? '';
                              final time = location['time']?.toString() ?? '';
                              final isIn = inOut.toLowerCase() == 'in';

                              if (lat == 0.0 || lon == 0.0) {
                                return null;
                              }

                              return Marker(
                                point: latlong.LatLng(lat, lon),
                                width: 32,
                                height: 32,
                                child: Tooltip(
                                  message: '${isIn ? "In" : "Out"} - $time',
                                  child: Icon(
                                    Icons.location_pin,
                                    color: isIn ? Colors.green : Colors.red,
                                    size: 32,
                                  ),
                                ),
                              );
                            })
                            .whereType<Marker>()
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
