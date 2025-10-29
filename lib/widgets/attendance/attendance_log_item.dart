import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_values.dart';
import '../../utils/app_theme.dart';

/// Widget to display a single attendance log item
class AttendanceLogItem extends StatelessWidget {
  final Map<String, dynamic> log;
  final int index;

  const AttendanceLogItem({Key? key, required this.log, required this.index})
    : super(key: key);

  String _getPunchType() {
    return log['punchType']?.toString() ?? 'Unknown';
  }

  String _getDate() {
    return log['date']?.toString() ?? 'N/A';
  }

  String _getRecordType() {
    return log['recordType']?.toString() ?? AppValues.recordTypeManual;
  }

  String _getLat() {
    return log['lat']?.toString() ?? 'N/A';
  }

  String _getLon() {
    return log['lon']?.toString() ?? 'N/A';
  }

  Color _getPunchColor() {
    return _getPunchType() == AppValues.punchIn
        ? AppTheme.successColor
        : AppTheme.errorColor;
  }

  IconData _getPunchIcon() {
    return _getPunchType() == AppValues.punchIn
        ? Icons.login_rounded
        : Icons.logout_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final punchColor = _getPunchColor();
    final punchIcon = _getPunchIcon();
    final punchType = _getPunchType();
    final date = _getDate();
    final recordType = _getRecordType();
    final lat = _getLat();
    final lon = _getLon();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: punchColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: punchColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  punchColor.withOpacity(0.2),
                  punchColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Icon(
              punchIcon,
              color: punchColor,
              size: AppDimensions.iconM,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingS,
                        vertical: AppDimensions.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: punchColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusS,
                        ),
                      ),
                      child: Text(
                        '#$index $punchType',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: punchColor,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingS,
                        vertical: AppDimensions.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.spacingS,
                        ),
                      ),
                      child: Text(
                        recordType,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingS),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: AppDimensions.iconXS,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.paddingXS),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: AppDimensions.iconXS,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: AppDimensions.paddingXS),
                    Expanded(
                      child: Text(
                        '$lat, $lon',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
