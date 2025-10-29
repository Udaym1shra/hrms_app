import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../utils/app_theme.dart';
import '../common/stat_item.dart';
import '../common/status_badge.dart';

/// Widget for displaying attendance status card
class AttendanceStatusCard extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const AttendanceStatusCard({Key? key, required this.attendanceData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = attendanceData['status'] ?? 'Unknown';
    final attendanceDate = attendanceData['attendanceDate'] ?? 'N/A';
    final productionHour = attendanceData['productionHour'] ?? 0;

    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'present':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'absent':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'late':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.schedule_rounded;
        break;
      default:
        statusColor = AppTheme.textSecondary;
        statusIcon = Icons.help_outline_rounded;
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
            colors: [statusColor.withOpacity(0.05), Colors.white],
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.attendanceStatus,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppStrings.date}: $attendanceDate',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: StatusBadge(status: status, color: statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: StatItem(
                        label: AppStrings.productionHours,
                        value: '${productionHour.toStringAsFixed(1)} hrs',
                        icon: Icons.access_time_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: StatItem(
                        label: AppStrings.earlyComing,
                        value:
                            '${attendanceData['earlyComingMinutes'] ?? 0} ${AppStrings.minutes}',
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.successColor,
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    Expanded(
                      child: StatItem(
                        label: AppStrings.lateComing,
                        value:
                            '${attendanceData['lateComingMinutes'] ?? 0} ${AppStrings.minutes}',
                        icon: Icons.trending_down_rounded,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
