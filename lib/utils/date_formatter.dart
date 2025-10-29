import '../../core/constants/app_values.dart';

/// Utility class for date and time formatting
class DateFormatter {
  /// Format date as "Oct 28, 2025"
  static String formatDateForDisplay(DateTime date) {
    final month = AppValues.monthAbbreviations[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  /// Format time as "HH:mm:ss"
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}:'
        '${date.second.toString().padLeft(2, '0')}';
  }

  /// Format time as "HH:mm"
  static String formatTimeShort(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  /// Parse date from API format "YYYY-MM-DD HH:mm:ss" or ISO format
  static DateTime? parseAttendanceDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Try to parse ISO format first
      final isoParsed = DateTime.tryParse(dateStr);
      if (isoParsed != null) return isoParsed;

      // Try to parse "YYYY-MM-DD HH:mm:ss" format
      if (dateStr.contains(' ') && dateStr.length >= 19) {
        final parts = dateStr.split(' ');
        if (parts.length == 2) {
          final datePart = parts[0]; // YYYY-MM-DD
          final timePart = parts[1]; // HH:mm:ss
          final dateTimeStr = '${datePart}T$timePart';
          return DateTime.tryParse(dateTimeStr);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Format date as "dd/MM/yyyy"
  static String formatDateShort(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

/// Utility class for timezone handling
class TimezoneHelper {
  /// Get current timezone string
  static String getCurrentTimezone() {
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final totalMinutes = offset.inMinutes;

      // Check if it's IST (UTC+5:30)
      if (totalMinutes == AppValues.istOffsetMinutes ||
          (offset.inHours == 5 && offset.inMinutes % 60 == 30)) {
        return AppValues.defaultTimezone;
      }

      // For other timezones, return UTC offset format
      final hours = offset.inHours;
      final minutes = offset.inMinutes % 60;
      final sign = hours >= 0 ? '+' : '';
      return 'UTC$sign${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}';
    } catch (e) {
      return AppValues.defaultTimezone;
    }
  }
}

/// Utility class for duration calculations
class DurationHelper {
  /// Calculate working duration from attendance logs
  static String calculateWorkingDuration(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return '00:00:00';

    Duration totalDuration = Duration.zero;
    DateTime? punchInTime;

    for (var log in logs) {
      if (log['punchType'] == AppValues.punchIn) {
        punchInTime = DateFormatter.parseAttendanceDate(log['date']?.toString());
      } else if (log['punchType'] == AppValues.punchOut && punchInTime != null) {
        final punchOutTime = DateFormatter.parseAttendanceDate(log['date']?.toString());
        if (punchOutTime != null) {
          totalDuration += punchOutTime.difference(punchInTime);
          punchInTime = null;
        }
      }
    }

    // If last log is PunchIn, add current session duration
    if (logs.isNotEmpty) {
      final lastLog = logs.last;
      if (lastLog['punchType'] == AppValues.punchIn) {
        // Find the latest punch in time
        DateTime? latestPunchIn;
        for (var log in logs.reversed) {
          if (log['punchType'] == AppValues.punchIn) {
            latestPunchIn = DateFormatter.parseAttendanceDate(log['date']?.toString());
            break;
          }
        }
        if (latestPunchIn != null) {
          totalDuration += DateTime.now().difference(latestPunchIn);
        }
      }
    }

    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    final seconds = totalDuration.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Get start time (first PunchIn) from logs
  static String getStartTime(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return '--:--:--';

    for (var log in logs) {
      if (log['punchType'] == AppValues.punchIn) {
        final dateTime = DateFormatter.parseAttendanceDate(log['date']?.toString());
        if (dateTime != null) {
          return DateFormatter.formatTime(dateTime);
        }
      }
    }

    return '--:--:--';
  }

  /// Get formatted punch in time
  static String getFormattedPunchInTime(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return '--:--:--';

    for (var log in logs.reversed) {
      if (log['punchType'] == AppValues.punchIn) {
        final dateTime = DateFormatter.parseAttendanceDate(log['date']?.toString());
        if (dateTime != null) {
          return DateFormatter.formatTime(dateTime);
        }
      }
    }

    return '--:--:--';
  }

  /// Get last punch type
  static String getLastPunchType(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return AppValues.punchOut;
    }

    final lastLog = logs.last;
    return lastLog['punchType']?.toString() ?? AppValues.punchOut;
  }
}

