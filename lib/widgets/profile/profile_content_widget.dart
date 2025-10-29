import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/employee_models.dart';
import '../../utils/app_theme.dart';
import '../common/info_row.dart';

/// Widget for displaying profile content
class ProfileContentWidget extends StatelessWidget {
  final Employee employee;

  const ProfileContentWidget({Key? key, required this.employee})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.05),
                    Colors.white,
                  ],
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
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppStrings.personalInfo,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
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
                          InfoRow(
                            label: AppStrings.name,
                            value: employee.fullName,
                            icon: Icons.person_outline_rounded,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.employeeCode,
                            value: employee.empCode,
                            icon: Icons.badge_outlined,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.emailLabel,
                            value: employee.email,
                            icon: Icons.email_outlined,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.mobileLabel,
                            value: employee.mobile ?? AppStrings.notAvailable,
                            icon: Icons.phone_outlined,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.department,
                            value:
                                employee.departmentModel?.name ??
                                AppStrings.notAvailable,
                            icon: Icons.business_outlined,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.designation,
                            value:
                                employee.designationModel?.name ??
                                AppStrings.notAvailable,
                            icon: Icons.work_outline_rounded,
                          ),
                          const Divider(height: AppDimensions.spacingL),
                          InfoRow(
                            label: AppStrings.joinDateLabel,
                            value: employee.joinDate ?? AppStrings.notAvailable,
                            icon: Icons.calendar_today_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
