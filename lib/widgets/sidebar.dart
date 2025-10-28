import 'package:flutter/material.dart';
import '../features/auth/data/models/user_model.dart';

class Sidebar extends StatefulWidget {
  final UserModel? user;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback? onLogout;
  final VoidCallback? onClose;

  const Sidebar({
    Key? key,
    this.user,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onLogout,
    this.onClose,
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
          decoration: const BoxDecoration(
            color: Color(0xFF2C3E50), // Dark blue-grey background
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with logo and close button
              _buildHeader(),

              // Navigation Menu
              Expanded(child: _buildNavigationMenu(roleId)),

              // Logout Button
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Close button and logo row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button
              if (widget.onClose != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF343A40), // Dark grey
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onClose,
                      borderRadius: BorderRadius.circular(8),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              // Logo with orange background
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA500), // Orange
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'GGen',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationMenu(int roleId) {
    final items = _getMenuItemsList(roleId);
    final List<Widget> menuWidgets = [];

    // Overview section
    final overviewItems = items
        .where(
          (item) => item.title == 'Dashboard' || item.title == 'My Profile',
        )
        .toList();

    if (overviewItems.isNotEmpty) {
      menuWidgets.add(_buildSectionHeader('OVERVIEW'));
      for (var item in overviewItems) {
        menuWidgets.add(_buildMenuItem(item));
      }
      menuWidgets.add(const SizedBox(height: 12));
    }

    // Time & Attendance section
    final attendanceItems = items
        .where(
          (item) =>
              item.title == 'Attendance' ||
              item.title == 'My Attendance' ||
              item.title == 'Time Sheet' ||
              item.title == 'Overtime',
        )
        .toList();

    if (attendanceItems.isNotEmpty) {
      menuWidgets.add(_buildSectionHeader('TIME & ATTENDANCE'));
      for (var item in attendanceItems) {
        menuWidgets.add(_buildMenuItem(item));
      }
      menuWidgets.add(const SizedBox(height: 12));
    }

    // Leave Management section
    final leaveItems = items
        .where((item) => item.title == 'Leaves' || item.title == 'My Leaves')
        .toList();

    if (leaveItems.isNotEmpty) {
      menuWidgets.add(_buildSectionHeader('LEAVE MANAGEMENT'));
      for (var item in leaveItems) {
        menuWidgets.add(_buildMenuItem(item));
      }
      menuWidgets.add(const SizedBox(height: 12));
    }

    // Other items
    final otherItems = items
        .where(
          (item) =>
              item.title != 'Dashboard' &&
              item.title != 'My Profile' &&
              item.title != 'Attendance' &&
              item.title != 'My Attendance' &&
              item.title != 'Time Sheet' &&
              item.title != 'Overtime' &&
              item.title != 'Leaves' &&
              item.title != 'My Leaves',
        )
        .toList();

    if (otherItems.isNotEmpty) {
      menuWidgets.add(_buildSectionHeader('OTHER'));
      for (var item in otherItems) {
        menuWidgets.add(_buildMenuItem(item));
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: menuWidgets,
    );
  }

  List<SidebarItem> _getMenuItemsList(int roleId) {
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

    return items;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFFE0E0E0), // Light grey
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
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
      SidebarItem(icon: Icons.person, title: 'My Profile', index: 11),
      SidebarItem(icon: Icons.schedule, title: 'Attendance', index: 6),
      SidebarItem(
        icon: Icons.description_rounded,
        title: 'Time Sheet',
        index: 12,
      ),
      SidebarItem(
        icon: Icons.access_time_rounded,
        title: 'Overtime',
        index: 13,
      ),
      SidebarItem(
        icon: Icons.calendar_today_rounded,
        title: 'My Leaves',
        index: 7,
      ),
      SidebarItem(icon: Icons.description, title: 'Documents', index: 12),
      SidebarItem(icon: Icons.book, title: 'Modules', index: 14),
      SidebarItem(icon: Icons.quiz, title: 'Assessments', index: 15),
    ];
  }

  Widget _buildMenuItem(SidebarItem item) {
    final isSelected = widget.selectedIndex == item.index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onItemSelected(item.index);
            // Close sidebar on mobile after selection
            if (widget.onClose != null &&
                MediaQuery.of(context).size.width <= 768) {
              widget.onClose?.call();
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF34688C) : Colors.transparent,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(isSelected ? 8 : 0),
                bottomRight: Radius.circular(isSelected ? 8 : 0),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Icon(item.icon, color: Colors.white, size: 22),
                const SizedBox(width: 14),
                // Text
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
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
