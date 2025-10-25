import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/auth_models.dart';

class Sidebar extends StatelessWidget {
  final User? user;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback? onLogout;

  const Sidebar({
    Key? key,
    this.user,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final roleId = user?.role?.id ?? 4; // Default to employee role
    
    return Container(
      width: 280,
      color: const Color(0xFF1F2937), // Dark gray background
      child: Column(
        children: [
          // Header with user info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF374151),
              border: Border(
                bottom: BorderSide(color: Color(0xFF4B5563), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Company Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'HRMS Mobile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (user != null) ...[
                  Text(
                    user!.fullName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user!.role?.name ?? 'Employee',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: _buildMenuItems(roleId),
            ),
          ),
          
          // Logout Button
          Container(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: onLogout,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hoverColor: Colors.red.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(int roleId) {
    List<SidebarItem> items = [];

    // Common items for all roles
    items.addAll([
      SidebarItem(
        icon: Icons.dashboard,
        title: 'Dashboard',
        index: 0,
      ),
    ]);

    // Role-specific items
    switch (roleId) {
      case 1: // Super Admin
        items.addAll(_getSuperAdminItems());
        break;
      case 2: // Admin
        items.addAll(_getAdminItems());
        break;
      case 3: // HR
        items.addAll(_getHRItems());
        break;
      case 4: // Manager
        items.addAll(_getManagerItems());
        break;
      case 5: // Employee
      default:
        items.addAll(_getEmployeeItems());
        break;
    }

    return items.map((item) => _buildMenuItem(item)).toList();
  }

  List<SidebarItem> _getSuperAdminItems() {
    return [
      SidebarItem(icon: Icons.people, title: 'Employees', index: 1),
      SidebarItem(icon: Icons.business, title: 'Companies', index: 2),
      SidebarItem(icon: Icons.location_on, title: 'Branches', index: 3),
      SidebarItem(icon: Icons.account_tree, title: 'Departments', index: 4),
      SidebarItem(icon: Icons.work, title: 'Designations', index: 5),
      SidebarItem(icon: Icons.schedule, title: 'Attendance', index: 6),
      SidebarItem(icon: Icons.event, title: 'Leaves', index: 7),
      SidebarItem(icon: Icons.assessment, title: 'Reports', index: 8),
      SidebarItem(icon: Icons.settings, title: 'Settings', index: 9),
    ];
  }

  List<SidebarItem> _getAdminItems() {
    return [
      SidebarItem(icon: Icons.people, title: 'Employees', index: 1),
      SidebarItem(icon: Icons.business, title: 'Companies', index: 2),
      SidebarItem(icon: Icons.location_on, title: 'Branches', index: 3),
      SidebarItem(icon: Icons.account_tree, title: 'Departments', index: 4),
      SidebarItem(icon: Icons.work, title: 'Designations', index: 5),
      SidebarItem(icon: Icons.schedule, title: 'Attendance', index: 6),
      SidebarItem(icon: Icons.event, title: 'Leaves', index: 7),
      SidebarItem(icon: Icons.assessment, title: 'Reports', index: 8),
    ];
  }

  List<SidebarItem> _getHRItems() {
    return [
      SidebarItem(icon: Icons.people, title: 'Employees', index: 1),
      SidebarItem(icon: Icons.schedule, title: 'Attendance', index: 6),
      SidebarItem(icon: Icons.event, title: 'Leaves', index: 7),
      SidebarItem(icon: Icons.assessment, title: 'Reports', index: 8),
      SidebarItem(icon: Icons.person_add, title: 'Recruitment', index: 10),
    ];
  }

  List<SidebarItem> _getManagerItems() {
    return [
      SidebarItem(icon: Icons.people, title: 'Team Members', index: 1),
      SidebarItem(icon: Icons.schedule, title: 'Attendance', index: 6),
      SidebarItem(icon: Icons.event, title: 'Leaves', index: 7),
      SidebarItem(icon: Icons.assessment, title: 'Team Reports', index: 8),
    ];
  }

  List<SidebarItem> _getEmployeeItems() {
    return [
      SidebarItem(icon: Icons.schedule, title: 'My Attendance', index: 6),
      SidebarItem(icon: Icons.event, title: 'My Leaves', index: 7),
      SidebarItem(icon: Icons.person, title: 'My Profile', index: 11),
      SidebarItem(icon: Icons.description, title: 'Documents', index: 12),
      SidebarItem(icon: Icons.book, title: 'Modules', index: 13),
      SidebarItem(icon: Icons.quiz, title: 'Assessments', index: 14),
    ];
  }

  Widget _buildMenuItem(SidebarItem item) {
    final isSelected = selectedIndex == item.index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected ? AppTheme.primaryColor : Colors.white70,
          size: 22,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () => onItemSelected(item.index),
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String title;
  final int index;

  SidebarItem({
    required this.icon,
    required this.title,
    required this.index,
  });
}
