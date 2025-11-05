import 'package:flutter/material.dart';
// Added By uday on 30_10_2025: Firebase initialization and messaging
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/storage_service.dart';
import 'services/background_location_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'core/router/app_router.dart';
import 'utils/app_theme.dart';

// Added By uday on 30_10_2025: Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Added By uday on 30_10_2025: Initialize Firebase
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // ignore: avoid_print
    print('✅ Firebase initialized successfully');
  } catch (e) {
    // ignore: avoid_print
    print('❌ Firebase initialization failed: $e');
  }

  // Added: FCM init for debugging and verification
  if (firebaseInitialized) {
    try {
      // Android 13+: request notifications
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Log token to console so we can test from backend/firebase console
      final token = await FirebaseMessaging.instance.getToken();
      // ignore: avoid_print
      print('FCM token (startup): ' + (token ?? 'null'));

      // Foreground listener (logs only)
      FirebaseMessaging.onMessage.listen((RemoteMessage m) {
        final t = m.notification?.title ?? '';
        final b = m.notification?.body ?? '';
        // ignore: avoid_print
        print(
          'onMessage: title=' + t + ' body=' + b + ' data=' + m.data.toString(),
        );
      });

      // Opened from notification listener (background -> foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) {
        // ignore: avoid_print
        print('onMessageOpenedApp data=' + m.data.toString());
      });
    } catch (e) {
      // ignore: avoid_print
      print('❌ Firebase Messaging setup failed: $e');
    }
  } else {
    // ignore: avoid_print
    print('⚠️ Skipping Firebase Messaging setup - Firebase not initialized');
  }

  // Note: If your server sets android.notification.channelId, ensure the
  // channel exists in the app. Easiest: omit channelId on the server during
  // development so FCM uses the fallback channel.

  // Initialize local notifications FIRST (channels etc.) so they exist before
  // the background service tries to use them for foreground notifications
  try {
    await NotificationService.instance.initialize();
  } catch (_) {}

  // Initialize background location service after notification channels are created
  // This ensures the notification channel exists before the service starts
  try {
    await BackgroundLocationService.initialize();
  } catch (_) {}

  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storageService)],
      child: MyApp(),
    ),
  );

  // If the user is already punched in, make sure the foreground service is running
  // after app launch (covers cold start and process recreation scenarios).
  try {
    await BackgroundLocationService.ensureServiceRunning();
  } catch (_) {}
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'HRMS',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
