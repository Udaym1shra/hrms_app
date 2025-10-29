import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../utils/app_theme.dart';
import '../common/detail_row.dart';

/// Widget for displaying attendance details card
class AttendanceDetailsCard extends StatelessWidget {
  final Map<String, dynamic> attendanceData;

  const AttendanceDetailsCard({Key? key, required this.attendanceData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final punchInTime = attendanceData['punchInTime'];
    final punchOutTime = attendanceData['punchOutTime'];
    final earlyDepartureMinutes = attendanceData['earlyDepartureMinutes'] ?? 0;
    final lateDepartureMinutes = attendanceData['lateDepartureMinutes'] ?? 0;

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
                      Icons.info_outline_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppStrings.attendanceDetails,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
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
                child: Column(
                  children: [
                    DetailRow(
                      label: AppStrings.punchInTime,
                      value: punchInTime ?? AppStrings.notAvailable,
                      icon: Icons.login_rounded,
                    ),
                    const Divider(height: AppDimensions.spacingL),
                    DetailRow(
                      label: AppStrings.punchOutTime,
                      value: punchOutTime ?? AppStrings.notAvailable,
                      icon: Icons.logout_rounded,
                    ),
                    const Divider(height: AppDimensions.spacingL),
                    DetailRow(
                      label: AppStrings.earlyDeparture,
                      value: '$earlyDepartureMinutes ${AppStrings.minutes}',
                      icon: Icons.trending_up_rounded,
                    ),
                    const Divider(height: AppDimensions.spacingL),
                    DetailRow(
                      label: AppStrings.lateDeparture,
                      value: '$lateDepartureMinutes ${AppStrings.minutes}',
                      icon: Icons.trending_down_rounded,
                    ),
                    if (attendanceData['remark'] != null) ...[
                      const Divider(height: AppDimensions.spacingL),
                      DetailRow(
                        label: AppStrings.remark,
                        value: attendanceData['remark'],
                        icon: Icons.note_rounded,
                      ),
                    ],
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
