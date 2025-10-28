import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../features/auth/data/models/user_model.dart';

class Sidebar extends StatefulWidget {
  final UserModel? user;
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
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roleId = widget.user?.role?.id ?? 4; // Default to employee role

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F2937), Color(0xFF111827)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Enhanced Header with user info
              _buildHeader(),

              // Navigation Menu with improved design
              Expanded(child: _buildNavigationMenu(roleId)),

              // Enhanced Logout Button
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Enhanced Company Logo with animation
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'HRMS Mobile',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.user != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.user!.fullName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.user!.role?.name ?? 'Employee',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationMenu(int roleId) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        // Add section headers for better organization
        _buildSectionHeader('Main'),
        ..._buildMenuItems(roleId).take(1), // Dashboard

        const SizedBox(height: 8),
        _buildSectionHeader('Management'),
        ..._buildMenuItems(roleId).skip(1),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white.withOpacity(0.6),
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          onTap: widget.onLogout,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          hoverColor: Colors.red.withOpacity(0.1),
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems(int roleId) {
    List<SidebarItem> items = [];

    // Common items for all roles
    items.addAll([
      SidebarItem(icon: Icons.dashboard, title: 'Dashboard', index: 0),
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
    final isSelected = widget.selectedIndex == item.index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onItemSelected(item.index),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.2),
                        AppTheme.primaryColor.withOpacity(0.1),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Enhanced Icon with background
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: isSelected ? AppTheme.primaryColor : Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // Enhanced Text
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                // Selection indicator
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String title;
  final int index;

  SidebarItem({required this.icon, required this.title, required this.index});
}
