import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../utils/app_theme.dart';
import '../common/stat_card.dart';

/// Widget for displaying quick stats cards
class QuickStatsWidget extends StatelessWidget {
  const QuickStatsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total Days',
            value: '30',
            icon: Icons.calendar_today_rounded,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: StatCard(
            title: 'Present',
            value: '28',
            icon: Icons.check_circle_rounded,
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: StatCard(
            title: 'Leaves',
            value: '2',
            icon: Icons.event_busy_rounded,
            color: AppTheme.warningColor,
          ),
        ),
      ],
    );
  }
}
