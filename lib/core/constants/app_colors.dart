import 'package:flutter/material.dart';

// App color scheme
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF004990);
  static const Color primaryLight = Color(0xFF467091);
  static const Color primaryDark = Color(0xFF003366);

  // Secondary Colors
  static const Color secondary = Color(0xFF2196F3);
  static const Color secondaryLight = Color(0xFF64B5F6);
  static const Color secondaryDark = Color(0xFF1976D2);

  // Background Colors
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textDisabled = Color(0xFFCCCCCC);

  // Status Colors
  static const Color success = Color(0xFF38A169);
  static const Color successLight = Color(0xFF68D391);
  static const Color successDark = Color(0xFF2F855A);

  static const Color error = Color(0xFFE53E3E);
  static const Color errorLight = Color(0xFFFC8181);
  static const Color errorDark = Color(0xFFC53030);

  static const Color warning = Color(0xFFED8936);
  static const Color warningLight = Color(0xFFF6AD55);
  static const Color warningDark = Color(0xFFDD6B20);

  static const Color info = Color(0xFF3182CE);
  static const Color infoLight = Color(0xFF63B3ED);
  static const Color infoDark = Color(0xFF2C5282);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFFF3F4F6);
  static const Color greyDark = Color(0xFF374151);

  // Sidebar Colors
  static const Color sidebarBackground = Color(0xFF1F2937);
  static const Color sidebarHeader = Color(0xFF374151);
  static const Color sidebarBorder = Color(0xFF4B5563);
  static const Color sidebarText = Color(0xFFD1D5DB);
  static const Color sidebarTextActive = Color(0xFF004990);

  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderDark = Color(0xFFD1D5DB);

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowDark = Color(0x33000000);

  // Overlay Colors
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  static const Color overlayDark = Color(0xCC000000);

  // Status-specific colors for employee work status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return success;
      case 'inactive':
        return error;
      case 'pending':
        return warning;
      case 'suspended':
        return error;
      case 'terminated':
        return grey;
      default:
        return textSecondary;
    }
  }

  // Geofence-specific colors
  static const Color geofenceInside = Color(0xFF10B981); // Emerald green
  static const Color geofenceInsideLight = Color(0xFFD1FAE5); // Light emerald
  static const Color geofenceOutside = Color(0xFFEF4444); // Red
  static const Color geofenceOutsideLight = Color(0xFFFEE2E2); // Light red
  static const Color geofenceNeutral = Color(0xFF6B7280); // Gray
  static const Color geofenceNeutralLight = Color(0xFFF3F4F6); // Light gray

  // Location permission colors
  static const Color locationGranted = Color(0xFF059669); // Green
  static const Color locationDenied = Color(0xFFDC2626); // Red
  static const Color locationPending = Color(0xFFD97706); // Amber

  // Geofence status colors with better contrast
  static Color getGeofenceStatusColor(bool isInside) {
    return isInside ? geofenceInside : geofenceOutside;
  }

  static Color getGeofenceStatusLightColor(bool isInside) {
    return isInside ? geofenceInsideLight : geofenceOutsideLight;
  }

  // Location permission status colors
  static Color getLocationPermissionColor(String status) {
    switch (status.toLowerCase()) {
      case 'granted':
      case 'while_in_use':
      case 'always':
        return locationGranted;
      case 'denied':
      case 'denied_forever':
        return locationDenied;
      case 'pending':
        return locationPending;
      default:
        return geofenceNeutral;
    }
  }

  // Attendance status colors
  static Color getAttendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return success;
      case 'absent':
        return error;
      case 'late':
        return warning;
      case 'half_day':
        return info;
      default:
        return textSecondary;
    }
  }
}
