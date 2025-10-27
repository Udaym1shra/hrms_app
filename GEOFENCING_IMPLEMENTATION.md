# Geofencing Implementation for Flutter Attendance App

This implementation provides geofencing functionality for the Flutter attendance app using location-based validation.

## Features Implemented

### 1. Geofence Service (`lib/services/geofence_service.dart`)
- **Location-based geofencing**: Uses GPS coordinates and radius to define geofenced areas
- **Server integration**: Fetches geofence configuration from the API
- **Local storage**: Persists geofence data and last known location
- **Real-time validation**: Checks if current location is within the geofenced area
- **Distance calculation**: Calculates distance from geofence center

### 2. API Service Extensions (`lib/services/api_service.dart`)
- `getEmployeeGeofenceConfig()`: Fetch geofence configuration for an employee
- `validateLocationAgainstGeofence()`: Server-side location validation
- `getEmployeeLocationHistory()`: Get location tracking history
- `updateGeofenceConfig()`: Update geofence settings
- `createEmployeeLocation()`: Log employee location data

### 3. Punch Widget Integration (`lib/widgets/punch_in_out_widget.dart`)
- **Geofence status display**: Shows whether employee is inside/outside office area
- **Location validation**: Validates location before allowing punch in/out
- **Real-time updates**: Updates geofence status based on current location
- **Error handling**: Provides clear feedback for location-related issues

## How It Works

### 1. Initialization
```dart
// The geofence service is automatically initialized when the punch widget loads
await _geofenceService.initialize();
```

### 2. Geofence Setup
```dart
// Geofence is set up when employee data is loaded
await _geofenceService.fetchGeofenceConfigFromServer(
  employeeId: employeeId,
  tenantId: tenantId,
);
```

### 3. Location Validation
```dart
// Before punch in/out, location is validated
final validation = await _geofenceService.validateGeofenceForPunch(currentPosition);
if (!validation['isValid']) {
  // Show error message
  setState(() {
    _error = validation['message'];
  });
  return;
}
```

### 4. UI Display
The punch widget shows:
- **Geofence Status**: "Inside Office Area" or "Outside Office Area"
- **Distance Information**: Shows distance from geofence center
- **Location Details**: Tap info icon to see detailed geofence information

## Configuration

### Android Permissions (`android/app/src/main/AndroidManifest.xml`)
```xml
<!-- Location Permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

<!-- Geofencing Permissions -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS Permissions (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to track attendance and validate geofencing.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to track attendance and validate geofencing even when the app is in the background.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs location access to track attendance and validate geofencing even when the app is in the background.</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>background-processing</string>
</array>
```

## Dependencies

### pubspec.yaml
```yaml
dependencies:
  geolocator: ^13.0.1
  geofencing_flutter_plugin: ^1.7.1
  shared_preferences: ^2.3.2
```

## API Endpoints

The implementation expects these API endpoints:

1. **GET** `/hrapi/geofencing-config/employee/{employeeId}` - Get employee geofence config
2. **POST** `/hrapi/geofencing-config/validate` - Validate location against geofence
3. **GET** `/hrapi/geofencing-employee-location` - Get location history
4. **PUT** `/hrapi/geofencing-config` - Update geofence configuration
5. **POST** `/hrapi/geofencing-employee-location` - Log employee location

## Usage Example

```dart
// Initialize geofence service
final geofenceService = GeofenceService();
await geofenceService.initialize();

// Set up geofence manually (if not using server config)
await geofenceService.setupGeofence(
  employeeId: 123,
  tenantId: 1,
  latitude: 37.7749,
  longitude: -122.4194,
  radius: 100.0,
  geofenceName: 'Office Location',
);

// Validate location for punch operation
final position = await Geolocator.getCurrentPosition();
final validation = await geofenceService.validateGeofenceForPunch(position);

if (validation['isValid']) {
  // Allow punch in/out
  print('Location validated: ${validation['message']}');
} else {
  // Deny punch in/out
  print('Location invalid: ${validation['message']}');
}
```

## Error Handling

The implementation includes comprehensive error handling:

- **Location permission denied**: Clear error messages and guidance
- **GPS unavailable**: Fallback to last known location
- **Network errors**: Graceful degradation with cached data
- **Invalid geofence data**: Default to allowing punches with warnings

## Future Enhancements

1. **Background location tracking**: Monitor location even when app is closed
2. **Multiple geofences**: Support for multiple office locations
3. **Time-based geofencing**: Different rules for different times
4. **Push notifications**: Notify when entering/leaving geofenced areas
5. **Offline support**: Cache geofence data for offline validation

## Testing

To test the geofencing functionality:

1. **Set up a test geofence** with known coordinates
2. **Use location simulation** in development
3. **Test edge cases** like being exactly on the boundary
4. **Verify error handling** with denied permissions
5. **Test offline scenarios** with cached data

## Troubleshooting

### Common Issues

1. **Location not updating**: Check location permissions
2. **Geofence not working**: Verify API configuration
3. **Distance calculation errors**: Check coordinate format
4. **Performance issues**: Optimize location update frequency

### Debug Information

Enable debug logging by checking console output for:
- `🔧 Initializing GeofenceService...`
- `🌐 Fetching geofence config from server...`
- `📍 Distance from geofence center: Xm`
- `✅ Geofence setup successful`
