import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';

/// Reusable status badge widget
class StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const StatusBadge({Key? key, required this.status, required this.color})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
