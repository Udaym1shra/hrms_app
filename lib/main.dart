import 'package:flutter/material.dart';
// Added By uday on 30_10_2025: Firebase initialization and messaging
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/employee_dashboard.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/api_service.dart';
import 'services/background_location_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/employee_provider.dart';
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
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (_) {}

  // Added: FCM init for debugging and verification
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
  } catch (_) {}

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
  final apiService = ApiService(storageService);
  final authService = AuthService(apiService, storageService);

  runApp(
    MyApp(
      storageService: storageService,
      apiService: apiService,
      authService: authService,
    ),
  );

  // If the user is already punched in, make sure the foreground service is running
  // after app launch (covers cold start and process recreation scenarios).
  try {
    await BackgroundLocationService.ensureServiceRunning();
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;
  final AuthService authService;

  const MyApp({
    Key? key,
    required this.storageService,
    required this.apiService,
    required this.authService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => EmployeeProvider(apiService)),
      ],
      child: MaterialApp(
        title: 'HRMS',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.isAuthenticated) {
          return const EmployeeDashboard();
        }

        return const LoginScreen();
      },
    );
  }
}
