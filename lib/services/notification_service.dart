import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _geofenceChannel =
      AndroidNotificationChannel(
        'hrms_geofence_channel',
        'Geofence Alerts',
        description: 'Notifications for entering or exiting office geofence',
        importance: Importance.high,
      );

  // Channel for foreground location service
  static const AndroidNotificationChannel _locationChannel =
      AndroidNotificationChannel(
        'hrms_location_channel',
        'Location Tracking',
        description: 'Background location tracking for geofencing',
        importance:
            Importance.low, // Low importance for persistent foreground service
        playSound: false,
        enableVibration: false,
      );

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(initSettings);

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Create geofence channel on Android
    await androidImplementation?.createNotificationChannel(_geofenceChannel);

    // Create location tracking channel for foreground service
    await androidImplementation?.createNotificationChannel(_locationChannel);

    _initialized = true;
  }

  Future<void> showGeofenceStatusChange({required bool isInside}) async {
    if (!_initialized) {
      try {
        await initialize();
      } catch (_) {}
    }

    final title = isInside
        ? 'You are inside office area'
        : 'You left office area';
    final body = isInside
        ? 'Your location is within the designated geofence.'
        : 'You are outside the designated geofence.';

    final androidDetails = AndroidNotificationDetails(
      _geofenceChannel.id,
      _geofenceChannel.name,
      channelDescription: _geofenceChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'geofence',
    );

    final notifDetails = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        // A simple notification ID; not persistent
        1001,
        title,
        body,
        notifDetails,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to show geofence notification: $e');
      }
    }
  }
}
