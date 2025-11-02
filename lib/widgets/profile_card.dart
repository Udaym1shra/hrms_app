import 'package:flutter/material.dart';
import '../models/employee_models.dart';
import '../utils/app_theme.dart';

class ProfileCard extends StatelessWidget {
  final Employee employee;

  const ProfileCard({Key? key, required this.employee}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug: log key employee fields when ProfileCard builds
    // ignore: avoid_print

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor,
                  backgroundImage: employee.photoPath != null
                      ? NetworkImage(employee.photoPath!)
                      : null,
                  child: employee.photoPath == null
                      ? Text(
                          employee.firstName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 16),

                // Employee Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.designationModel?.name ?? 'Employee',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.departmentModel?.name ?? 'Department',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      employee.workStatus,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(
                        employee.workStatus,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    employee.workStatus,
                    style: TextStyle(
                      color: _getStatusColor(employee.workStatus),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Employee Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Employee Code',
                    employee.empCode,
                    Icons.badge,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Email',
                    employee.email,
                    Icons.email,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Mobile',
                    employee.mobile ?? 'N/A',
                    Icons.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    context,
                    'Join Date',
                    _formatDate(employee.joinDate),
                    Icons.calendar_today,
                  ),
                  if (employee.manager != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      'Reporting Manager',
                      employee.manager!.fullName,
                      Icons.person,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.successColor;
      case 'inactive':
        return AppTheme.errorColor;
      case 'pending':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
