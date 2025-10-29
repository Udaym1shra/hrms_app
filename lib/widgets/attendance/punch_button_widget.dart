import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../utils/app_theme.dart';

/// Widget for displaying punch in/out button
class PunchButtonWidget extends StatelessWidget {
  final Map<String, dynamic> attendanceData;
  final VoidCallback onPunch;

  const PunchButtonWidget({
    Key? key,
    required this.attendanceData,
    required this.onPunch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final attendanceLogs =
        attendanceData['attendanceLogsId'] as List<dynamic>? ?? [];
    final lastLog = attendanceLogs.isNotEmpty ? attendanceLogs.last : null;
    final lastPunchType = lastLog?['punchType'] ?? 'PunchOut';

    // Determine next action
    final nextAction = lastPunchType == 'PunchIn' ? 'PunchOut' : 'PunchIn';
    final buttonColor = nextAction == 'PunchIn'
        ? AppTheme.successColor
        : AppTheme.errorColor;
    final buttonIcon = nextAction == 'PunchIn'
        ? Icons.login_rounded
        : Icons.logout_rounded;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [buttonColor.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: buttonColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.flash_on_rounded,
                      color: buttonColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.quickAction,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: onPunch,
                  icon: Icon(buttonIcon, size: 24),
                  label: Text(
                    nextAction,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: buttonColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (lastLog != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${AppStrings.lastPunch}: $lastPunchType at ${lastLog['date']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
