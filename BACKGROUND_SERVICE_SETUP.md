# Background Service Setup for HRMS Flutter App

## Overview
This document describes the background service implementation for location tracking in the HRMS Flutter Android application. The app can now run in the background and continue tracking employee location even when the app is closed or minimized.

## Implementation Details

### 1. Dependencies Added
- **flutter_background_service**: ^5.0.5 - Enables background execution of Flutter code

### 2. Files Created/Modified

#### New Files:
- `lib/services/background_location_service.dart`: Background service handler that tracks location continuously

#### Modified Files:
- `pubspec.yaml`: Added flutter_background_service dependency
- `android/app/src/main/AndroidManifest.xml`: Added foreground service declaration
- `lib/services/geofence_service.dart`: Integrated background service start/stop

### 3. Key Features

#### Background Location Tracking
- **Only runs when last attendance log is "punchin"**
- Continuously tracks location every 5 meters for better geofencing detection
- Uploads location every 3 minutes when employee is punched in
- Checks geofence status (inside/outside) for each location update
- Automatically stops when employee punches out or if last log is not "punchin"
- **Runs without notification** - operates silently in background
- **Works in sleep mode, closed app, or when running**

#### Service Monitoring
- Automatically restarts service if it stops unexpectedly
- Monitors punch status every 2 minutes
- Ensures continuous geofencing detection

### 4. Android Permissions

The following permissions are already configured in AndroidManifest.xml:
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION` (required for Android 10+)
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`
- `WAKE_LOCK`

### 5. How It Works

1. **Initialization**: Background service is initialized when GeofenceService initializes
2. **Start**: Background service starts only when employee punches in AND last attendance log is "punchin"
3. **Tracking**: Service continuously tracks location every 5 meters and uploads every 3 minutes
4. **Geofencing**: Real-time geofence detection for accurate attendance tracking
5. **Monitoring**: Service monitors itself every 2 minutes to ensure it keeps running
6. **Validation**: Service continuously checks if last attendance log is still "punchin"
7. **Stop**: Background service stops when employee punches out OR if last log is not "punchin"

### 6. Important Notes

#### Location Permission Requirements
For Android 10+ devices, users must grant "Allow all the time" (Always) location permission for background tracking to work properly. The app will request this permission when needed.

#### Battery Optimization
Users may need to disable battery optimization for the app to ensure uninterrupted background tracking:
- Go to Settings > Apps > HRMS > Battery > Unrestricted

#### Notification
The app will show a persistent notification while tracking location. This is required by Android and cannot be disabled.

### 7. Testing

To test background execution:
1. Start the app and log in
2. Punch in (this will start background service)
3. Minimize the app or close it completely
4. Move around (location should still be tracked)
5. Check server logs for location updates

### 8. Code Usage

The background service is automatically managed by GeofenceService:
- Starts when `startAutoLocationUploadForEmployee()` is called
- Stops when `stopAutoLocationUpload()` is called

Manual control (if needed):
```dart
// Start background service
await BackgroundLocationService.start();

// Stop background service
await BackgroundLocationService.stop();

// Check if running
bool isRunning = await BackgroundLocationService.isRunning();
```

### 9. Troubleshooting

#### Background service not working:
1. Check location permissions (must be "Always" for Android 10+)
2. Ensure battery optimization is disabled
3. Check notification permission is granted
4. Verify app is not in "Doze" mode

#### Location updates not uploading:
1. Verify employee is punched in (last attendance log must be "punchin")
2. Check network connectivity
3. Verify API service is properly configured
4. Check server logs for errors
5. Verify background service is running (check notification)

### 10. Next Steps

1. Run `flutter pub get` to install new dependencies
2. Rebuild the app for changes to take effect
3. Test on a physical Android device (background services don't work well in emulators)
4. Ensure users grant "Always" location permission when prompted

## Developer Notes

- Background service runs as a foreground service with a persistent notification
- Location updates are throttled to every 10 meters to save battery
- Upload frequency is configurable (currently set to 5 minutes)
- Service automatically stops if location permission is revoked

