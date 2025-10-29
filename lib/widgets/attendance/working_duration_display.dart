import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_values.dart';

/// Widget to display working duration in a circular format
class WorkingDurationDisplay extends StatelessWidget {
  final String duration;
  final String startTime;

  const WorkingDurationDisplay({
    Key? key,
    required this.duration,
    required this.startTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= AppValues.mobileBreakpoint;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final circleSize = isMobile
            ? (maxWidth * 0.45).clamp(
                AppValues.workingDurationCircleMobileMinSize,
                AppValues.workingDurationCircleMobileMaxSize,
              )
            : (maxWidth * 0.4).clamp(
                AppValues.workingDurationCircleMinSize,
                AppValues.workingDurationCircleMaxSize,
              );

        final titleSize = circleSize < 150
            ? (circleSize * 0.09).clamp(10.0, 14.0)
            : (circleSize * 0.1).clamp(12.0, 16.0);
        final durationSize = circleSize < 150
            ? (circleSize * 0.12).clamp(14.0, 20.0)
            : (circleSize * 0.15).clamp(18.0, 24.0);
        final startTimeSize = circleSize < 150
            ? (circleSize * 0.07).clamp(8.0, 11.0)
            : (circleSize * 0.08).clamp(10.0, 13.0);

        final spacing1 = circleSize < 150
            ? circleSize * 0.04
            : circleSize * 0.06;
        final spacing2 = circleSize < 150
            ? circleSize * 0.02
            : circleSize * 0.03;

        final innerPadding = circleSize * 0.1;

        return Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFE0B2), width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(innerPadding),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.productionHours,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing1),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: durationSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing2),
                    Text(
                      '${AppStrings.startTime}: $startTime',
                      style: TextStyle(
                        fontSize: startTimeSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
