import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import 'custom_button.dart';

class PunchInOutWidget extends StatefulWidget {
  final int employeeId;
  final int tenantId;
  final ApiService apiService;

  const PunchInOutWidget({
    Key? key,
    required this.employeeId,
    required this.tenantId,
    required this.apiService,
  }) : super(key: key);

  @override
  State<PunchInOutWidget> createState() => _PunchInOutWidgetState();
}

class _PunchInOutWidgetState extends State<PunchInOutWidget> {
  bool _isPunchedIn = false;
  bool _isLoading = false;
  String? _currentLocation;
  Position? _currentPosition;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
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
        _currentLocation =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
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
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final response = await widget.apiService.punchIn(
        employeeId: widget.employeeId,
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
        dateWithTime: now.toIso8601String(),
        tenantId: widget.tenantId,
      );

      if (response['error'] == false) {
        setState(() {
          _isPunchedIn = true;
        });

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
    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final response = await widget.apiService.punchOut(
        employeeId: widget.employeeId,
        lat: _currentPosition!.latitude,
        lon: _currentPosition!.longitude,
        dateWithTime: now.toIso8601String(),
        tenantId: widget.tenantId,
      );

      if (response['error'] == false) {
        setState(() {
          _isPunchedIn = false;
        });

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
                Icon(Icons.access_time, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Punch In/Out',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Current Time
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _getCurrentTime(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getCurrentDate(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location Info
            if (_currentLocation != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location: $_currentLocation',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Error Message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Punch Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: _isPunchedIn ? 'Punch Out' : 'Punch In',
                onPressed: _isLoading
                    ? null
                    : (_isPunchedIn ? _handlePunchOut : _handlePunchIn),
                isLoading: _isLoading,
                icon: _isPunchedIn ? Icons.logout : Icons.login,
              ),
            ),

            const SizedBox(height: 12),

            // Refresh Location Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Refresh Location',
                onPressed: _isLoading ? null : _getCurrentLocation,
                isSecondary: true,
                icon: Icons.refresh,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
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
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}
