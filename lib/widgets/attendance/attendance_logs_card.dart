import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../utils/app_theme.dart';
import 'attendance_log_item.dart';

/// Widget for displaying attendance logs card
class AttendanceLogsCard extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const AttendanceLogsCard({Key? key, required this.attendanceData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final attendanceLogs =
        attendanceData['attendanceLogsId'] as List<dynamic>? ?? [];

    if (attendanceLogs.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.backgroundColor, Colors.white],
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 48,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.noAttendanceLogs,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryColor.withOpacity(0.05), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.attendanceLogs,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${attendanceLogs.length} ${AppStrings.entries}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...attendanceLogs.asMap().entries.map((entry) {
                final index = entry.key;
                final log = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < attendanceLogs.length - 1 ? 16 : 0,
                  ),
                  child: AttendanceLogItem(
                    log: log as Map<String, dynamic>,
                    index: index + 1,
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
