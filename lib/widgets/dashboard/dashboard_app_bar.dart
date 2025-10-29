import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_values.dart';
import '../../utils/app_theme.dart';

/// Widget for dashboard app bar
class DashboardAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onMenuPressed;

  const DashboardAppBar({
    Key? key,
    required this.title,
    required this.onMenuPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= AppValues.mobileBreakpoint;

    // Responsive padding - reduced to prevent system UI overlap
    final horizontalPadding = isMobile ? 12.0 : 20.0;
    final verticalPadding = isMobile ? 8.0 : 12.0;

    // Responsive icon sizes
    final iconSize = isMobile ? 18.0 : 24.0;
    final menuIconSize = isMobile ? 20.0 : 24.0;

    // Responsive spacing
    final spacing = isMobile ? 8.0 : 16.0;
    final titleSpacing = isMobile ? 8.0 : 12.0;

    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Menu Button - Hamburger icon
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: AppTheme.primaryColor,
                  size: menuIconSize,
                ),
                onPressed: onMenuPressed,
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                constraints: BoxConstraints(
                  minWidth: isMobile ? 36 : 48,
                  minHeight: isMobile ? 36 : 48,
                ),
              ),
            ),

            SizedBox(width: spacing),

            // Title with icon
            Expanded(
              child: Row(
                children: [
                  Image.asset(
                    AppConstants.companyLogoAsset,
                    height: iconSize + (isMobile ? 6 : 8),
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: titleSpacing),
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: 0.5,
                            fontSize: isMobile ? 16 : 20,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
