import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
// Added By uday on 30_10_2025: Request notification permission (Android 13+)
import 'package:permission_handler/permission_handler.dart' as ph;
// Added By uday on 30_10_2025: OEM settings intents (Xiaomi Autostart, Battery Optimization)
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for checking and requesting location permissions
class LocationPermissionHelper {
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('❌ Error checking location service: $e');
      return false;
    }
  }

  /// Check current location permission status
  static Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      print('❌ Error checking location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  static Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Check if location permission is granted (whileInUse or always)
  static Future<bool> hasLocationPermission() async {
    final permission = await checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Check if location is fully enabled (service enabled + permission granted)
  static Future<Map<String, dynamic>> checkLocationStatus() async {
    final serviceEnabled = await isLocationServiceEnabled();
    final permission = await checkPermission();
    final hasPermission =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    return {
      'serviceEnabled': serviceEnabled,
      'permission': permission,
      'hasPermission': hasPermission,
      'isFullyEnabled': serviceEnabled && hasPermission,
      'needToEnableService': !serviceEnabled,
      'needToGrantPermission': !hasPermission,
      'permissionDeniedForever': permission == LocationPermission.deniedForever,
    };
  }

  /// Request location permission and handle the flow
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestLocationPermission() async {
    // Check if location service is enabled first
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Location service is disabled');
      return false;
    }

    // Check current permission
    LocationPermission permission = await checkPermission();

    // Request permission if denied
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }

    // Return true if permission is granted
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Show dialog to enable location services
  static Future<bool> showEnableLocationServiceDialog(
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Service Disabled'),
        content: const Text(
          'Please enable location services in your device settings to use location features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Open location settings
              final opened = await Geolocator.openLocationSettings();
              Navigator.of(context).pop(opened);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show dialog to request location permission
  static Future<bool> showRequestPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location access to track your attendance and validate geofencing. Please grant location permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );

    if (result == true) {
      return await requestLocationPermission();
    }

    return false;
  }

  /// Show dialog for permanently denied permission
  static Future<bool> showPermissionDeniedForeverDialog(
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text(
          'Location permission has been permanently denied. Please enable it manually in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Open app settings
              final opened = await Geolocator.openAppSettings();
              Navigator.of(context).pop(opened);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Comprehensive check and request flow with dialogs
  /// Returns true if location is fully enabled (service + permission)
  static Future<bool> checkAndRequestLocationPermission(
    BuildContext context,
  ) async {
    final status = await checkLocationStatus();

    // If everything is enabled, return true
    if (status['isFullyEnabled'] == true) {
      return true;
    }

    // If location service is disabled, show dialog to enable it
    if (status['needToEnableService'] == true) {
      final enabled = await showEnableLocationServiceDialog(context);
      if (!enabled) {
        return false;
      }
      // Re-check after user might have enabled service
      final newStatus = await checkLocationStatus();
      if (newStatus['isFullyEnabled'] == true) {
        return true;
      }
    }

    // If permission is permanently denied, show settings dialog
    if (status['permissionDeniedForever'] == true) {
      return await showPermissionDeniedForeverDialog(context);
    }

    // If permission is not granted, request it
    if (status['needToGrantPermission'] == true) {
      return await showRequestPermissionDialog(context);
    }

    return false;
  }

  // Added By uday on 30_10_2025: Show dialog guiding user to enable "Allow all the time" background location
  static Future<bool> showBackgroundPermissionDialog(
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Background Location'),
        content: const Text(
          'For reliable geofencing and background tracking, please set Location permission to "Allow all the time" in App settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              final opened = await Geolocator.openAppSettings();
              Navigator.of(context).pop(opened);
            },
            child: const Text('Open App Settings'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Added By uday on 30_10_2025: Ensure background readiness (service + background permission) with guided dialogs
  // Enhanced: Remembers permission state to avoid repeated dialogs
  static Future<void> ensureBackgroundReady(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Quick check: If we've already confirmed permission is "always", skip everything
    final alreadyGranted =
        prefs.getBool('location_permission_always_granted') ?? false;
    if (alreadyGranted) {
      // Verify it's still "always" (user might have changed it in settings)
      final permission = await checkPermission();
      if (permission == LocationPermission.always) {
        print(
          '✅ Location permission confirmed as "Always" - skipping all dialogs',
        );
        return;
      } else {
        // Permission was changed, reset flags
        await prefs.setBool('location_permission_always_granted', false);
      }
    }

    // Check location service first
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      final enabled = await showEnableLocationServiceDialog(context);
      if (!enabled) return;
    }

    // Check current permission status
    final permission = await checkPermission();

    // If permission is already "always" (allow all the time), skip all dialogs
    if (permission == LocationPermission.always) {
      print('✅ Location permission already set to "Always" - skipping dialogs');
      // Mark that we've checked and permission is granted
      await prefs.setBool('location_permission_always_granted', true);
      await prefs.setBool('location_permission_dialog_shown', true);
      // Still check notification permission silently
      _checkNotificationPermissionSilently();
      return;
    }

    // If permission is denied, request it (only if not already requested)
    if (permission == LocationPermission.denied) {
      final alreadyRequested =
          prefs.getBool('location_permission_requested') ?? false;
      if (!alreadyRequested) {
        await requestPermission();
        await prefs.setBool('location_permission_requested', true);
        // Re-check after requesting
        final newPermission = await checkPermission();
        if (newPermission == LocationPermission.always) {
          await prefs.setBool('location_permission_always_granted', true);
          await prefs.setBool('location_permission_dialog_shown', true);
          _checkNotificationPermissionSilently();
          return;
        }
      }
    }

    // If only whileInUse is granted, check if we should show the "allow all time" dialog
    final hasForeground =
        permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;

    if (hasForeground && permission != LocationPermission.always) {
      // Check if user has already seen and declined this dialog
      final dialogShown =
          prefs.getBool('background_permission_dialog_shown') ?? false;
      final userDeclined =
          prefs.getBool('background_permission_declined') ?? false;

      // Only show if not already shown or if user hasn't explicitly declined
      if (!dialogShown || !userDeclined) {
        final result = await showBackgroundPermissionDialog(context);
        await prefs.setBool('background_permission_dialog_shown', true);
        if (result == false) {
          // User clicked "Later", remember this
          await prefs.setBool('background_permission_declined', true);
        }
      } else {
        print('ℹ️ Background permission dialog already shown - skipping');
      }
    }

    // Added By uday on 30_10_2025: Ensure notifications are allowed for foreground service
    _checkNotificationPermissionSilently();

    // Added By uday on 30_10_2025: Offer Xiaomi-specific guidance to keep service alive
    // Only show once per app installation
    if (Platform.isAndroid) {
      final xiaomiGuidanceShown =
          prefs.getBool('xiaomi_guidance_shown') ?? false;
      if (!xiaomiGuidanceShown) {
        await _showXiaomiGuidanceIfApplicable(context);
        await prefs.setBool('xiaomi_guidance_shown', true);
      }
    }
  }

  // Helper method to check notification permission silently without showing dialog
  static Future<void> _checkNotificationPermissionSilently() async {
    try {
      final status = await ph.Permission.notification.status;
      if (!status.isGranted) {
        // Only request if not already requested
        final prefs = await SharedPreferences.getInstance();
        final alreadyRequested =
            prefs.getBool('notification_permission_requested') ?? false;
        if (!alreadyRequested) {
          await ph.Permission.notification.request();
          await prefs.setBool('notification_permission_requested', true);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Notification permission check failed: $e');
    }
  }

  // Added By uday on 30_10_2025: OEM guidance dialog + deep links (Xiaomi/Realme/Oppo/Vivo)
  // Enhanced for HyperOS compatibility - only shows once
  static Future<void> _showXiaomiGuidanceIfApplicable(
    BuildContext context,
  ) async {
    // Best-effort manufacturer check; MIUI/HyperOS family often needs extra steps
    // We proceed to offer the guidance without strict manufacturer gating.

    final prefs = await SharedPreferences.getInstance();

    // Check if already shown (will be set by caller, but double-check here)
    final alreadyShown = prefs.getBool('xiaomi_guidance_shown') ?? false;
    if (alreadyShown) {
      print('ℹ️ Xiaomi guidance already shown - skipping');
      return;
    }

    // Check battery optimization status first
    final isIgnoringBatteryOptimizations =
        await ph.Permission.ignoreBatteryOptimizations.isGranted;

    // If battery optimization is already ignored, maybe skip the dialog
    if (isIgnoringBatteryOptimizations) {
      print('✅ Battery optimization already disabled - skipping guidance');
      return;
    }

    // Show a one-time helper dialog
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Optimize Background Tracking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'On Xiaomi/HyperOS devices, you MUST complete these steps to keep tracking when the app is closed:',
              ),
              const SizedBox(height: 12),
              const Text('1. Enable AutoStart (Required)'),
              const Text('2. Disable Battery Optimization (Required)'),
              const Text('3. Allow background activity'),
              const SizedBox(height: 8),
              if (!isIgnoringBatteryOptimizations)
                const Text(
                  '⚠️ Battery optimization is currently enabled!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Mark as shown even if user clicks "Later"
                prefs.setBool('xiaomi_guidance_shown', true);
              },
              child: const Text('I\'ll Do It Later'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _openAutoStartSettingsMultiVendor();
                prefs.setBool('xiaomi_guidance_shown', true);
              },
              child: const Text('1. AutoStart'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _openIgnoreBatteryOptimizations();
                prefs.setBool('xiaomi_guidance_shown', true);
              },
              child: const Text('2. Battery Settings'),
            ),
          ],
        );
      },
    );
  }

  // Added By uday on 30_10_2025: Try to open AutoStart management (multi-vendor)
  // Enhanced for HyperOS compatibility
  static Future<void> _openAutoStartSettingsMultiVendor() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final package = info.packageName;

      final candidates = <AndroidIntent>[
        // HyperOS / Xiaomi / MIUI (tried first for HyperOS compatibility)
        AndroidIntent(
          componentName:
              'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
        ),
        AndroidIntent(
          action: 'miui.intent.action.OP_AUTO_START',
          componentName:
              'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
        ),
        AndroidIntent(
          componentName:
              'com.miui.securitycenter/com.miui.permcenter.permissions.PermissionsEditorActivity',
        ),
        AndroidIntent(
          componentName:
              'com.miui.securitycenter/com.miui.appmanager.AppManagerMainActivity',
        ),
        // HyperOS alternative paths
        AndroidIntent(
          action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
          data: 'package:$package',
        ),
        // Oppo
        AndroidIntent(
          componentName:
              'com.coloros.safecenter/com.coloros.safecenter.permission.startup.StartupAppListActivity',
        ),
        AndroidIntent(
          componentName:
              'com.coloros.safecenter/com.coloros.safecenter.startupapp.StartupAppListActivity',
        ),
        AndroidIntent(
          componentName:
              'com.coloros.oppoguardelf/com.coloros.powermanager.fuelgaue.PowerUsageModelActivity',
        ),
        // Realme
        AndroidIntent(
          componentName:
              'com.realme.securitycenter/com.coloros.safecenter.startupapp.StartupAppListActivity',
        ),
        // Vivo
        AndroidIntent(
          componentName:
              'com.iqoo.secure/com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity',
        ),
        AndroidIntent(
          componentName:
              'com.vivo.permissionmanager/com.vivo.permissionmanager.activity.BgStartUpManagerActivity',
        ),
        // OnePlus
        AndroidIntent(
          componentName:
              'com.oneplus.security/com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity',
        ),
        // Generic app details as last resort
        AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:',
          // data will be filled below if this candidate is chosen
        ),
      ];
      for (final intent in candidates) {
        try {
          if (intent.data == 'package:') {
            // Fill package for generic candidate
            final info = await PackageInfo.fromPlatform();
            final package = info.packageName;
            await AndroidIntent(
              action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
              data: 'package:$package',
            ).launch();
            return;
          }
          await intent.launch();
          return;
        } catch (_) {
          // try next
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Failed to open Xiaomi AutoStart settings: $e');
    }
  }

  // Added By uday on 30_10_2025: Request ignore battery optimizations for this package
  // Enhanced for HyperOS compatibility
  static Future<void> _openIgnoreBatteryOptimizations() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final package = info.packageName;

      // First try the direct request intent
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        data: 'package:$package',
      );
      await intent.launch();

      // Also try opening battery optimization settings directly for HyperOS
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final batteryIntent = AndroidIntent(
          action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
        );
        await batteryIntent.launch();
      } catch (_) {
        // Ignore if this fails, the first intent should work
      }
    } catch (e) {
      // Fallback: open app info where user can find battery settings
      try {
        final info = await PackageInfo.fromPlatform();
        final package = info.packageName;
        final appInfo = AndroidIntent(
          action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
          data: 'package:$package',
        );
        await appInfo.launch();
      } catch (e2) {
        // ignore: avoid_print
        print('⚠️ Failed to open battery/app settings: $e | $e2');
      }
    }
  }

  // Check if battery optimization is currently ignored
  static Future<bool> isBatteryOptimizationIgnored() async {
    try {
      return await ph.Permission.ignoreBatteryOptimizations.isGranted;
    } catch (e) {
      print('⚠️ Error checking battery optimization status: $e');
      return false;
    }
  }

  // Request battery optimization exemption (for HyperOS compatibility)
  static Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final status = await ph.Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (e) {
      print('⚠️ Error requesting battery optimization exemption: $e');
      return false;
    }
  }

  // Reset all permission tracking flags (useful for testing or if user wants to see dialogs again)
  static Future<void> resetPermissionTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('location_permission_always_granted');
    await prefs.remove('location_permission_dialog_shown');
    await prefs.remove('location_permission_requested');
    await prefs.remove('background_permission_dialog_shown');
    await prefs.remove('background_permission_declined');
    await prefs.remove('notification_permission_requested');
    await prefs.remove('xiaomi_guidance_shown');
    print('✅ Permission tracking flags reset');
  }

  // Check if location permission is already set to "always" (quick check)
  static Future<bool> isLocationPermissionAlways() async {
    final permission = await checkPermission();
    return permission == LocationPermission.always;
  }
}
