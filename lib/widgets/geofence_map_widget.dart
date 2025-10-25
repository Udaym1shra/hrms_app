import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';

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
  Position? _currentPosition;
  bool _isInsideGeofence = false;

  @override
  void initState() {
    super.initState();
    _loadGeofenceConfig();
    _getCurrentLocation();
  }

  Future<void> _loadGeofenceConfig() async {
    try {
      final response = await widget.apiService.getGeofencingConfig(
        tenantId: widget.tenantId,
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
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load geofence config: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Location permission permanently denied';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _checkGeofenceStatus();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  void _checkGeofenceStatus() {
    if (_currentPosition == null || _geofenceConfig == null) return;

    final userLat = _currentPosition!.latitude;
    final userLon = _currentPosition!.longitude;
    final geofenceLat = _geofenceConfig!['lat']?.toDouble() ?? 0.0;
    final geofenceLon = _geofenceConfig!['lon']?.toDouble() ?? 0.0;
    final radius = _geofenceConfig!['radius']?.toDouble() ?? 0.0;

    if (geofenceLat != 0.0 && geofenceLon != 0.0 && radius > 0) {
      final distance = Geolocator.distanceBetween(
        userLat,
        userLon,
        geofenceLat,
        geofenceLon,
      );

      setState(() {
        _isInsideGeofence = distance <= radius;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Geofence Status',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Your current location relative to the configured geofence',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 20),

            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_geofenceConfig == null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: AppTheme.warningColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No geofence configuration found for your location',
                        style: TextStyle(color: AppTheme.warningColor),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Geofence Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isInsideGeofence
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isInsideGeofence
                        ? AppTheme.successColor.withOpacity(0.3)
                        : AppTheme.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isInsideGeofence ? Icons.check_circle : Icons.cancel,
                      color: _isInsideGeofence
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isInsideGeofence
                          ? 'Inside Geofence'
                          : 'Outside Geofence',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isInsideGeofence
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentPosition != null) ...[
                      Text(
                        'Your Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
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
                    _buildInfoRow(
                      'Center',
                      '${_geofenceConfig!['lat']?.toStringAsFixed(4) ?? 'N/A'}, ${_geofenceConfig!['lon']?.toStringAsFixed(4) ?? 'N/A'}',
                    ),
                    _buildInfoRow(
                      'Radius',
                      '${_geofenceConfig!['radius']?.toString() ?? 'N/A'} meters',
                    ),
                    if (_geofenceConfig!['boundary'] != null)
                      _buildInfoRow('Type', 'Polygon')
                    else
                      _buildInfoRow('Type', 'Circle'),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Refresh Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
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
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
