import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../utils/app_theme.dart';

/// Reusable info row widget for displaying key-value pairs
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool showDivider;

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    this.showDivider = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        if (showDivider) const Divider(height: AppDimensions.spacingL),
      ],
    );
  }
}
