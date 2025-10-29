// App values - magic numbers, default values, and configuration constants
class AppValues {
  // Dashboard
  static const int mobileBreakpoint = 768;
  static const double sidebarAnimationDuration = 300.0; // milliseconds

  // Attendance
  static const String punchIn = 'PunchIn';
  static const String punchOut = 'PunchOut';
  static const String recordTypeManual = 'Manual';
  static const double workingDurationCircleMinSize = 120.0;
  static const double workingDurationCircleMaxSize = 180.0;
  static const double workingDurationCircleMobileMinSize = 140.0;
  static const double workingDurationCircleMobileMaxSize = 180.0;

  // Geofencing
  static const double geofenceDistanceFilter = 10.0; // meters
  static const double geofenceMapHeight = 300.0;
  static const double geofenceMapZoom = 16.0;
  static const int geofenceMinPolygonPoints = 3;

  // Location
  static const double locationAccuracyHigh = 0.0; // uses LocationAccuracy.high
  static const String defaultTimezone = 'Asia/Calcutta';
  static const int istOffsetMinutes = 330; // UTC+5:30

  // Date/Time
  static const List<String> monthAbbreviations = [
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

  // Status
  static const String workingStatus = 'Working';
  static const String notPunchedStatus = 'Not Punched';
  static const String presentStatus = 'Present';
  static const String absentStatus = 'Absent';
  static const String lateStatus = 'Late';

  // Attendance Logs
  static const int attendanceLogsTableColumns = 4;

  // UI
  static const double cardMaxWidth = 600.0;
  static const double mapContainerHeight = 200.0;
}
