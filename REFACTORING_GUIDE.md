# HRMS App Refactoring Guide

## Overview
This document outlines the refactoring plan for improving code organization, maintainability, and reusability.

## Folder Structure

### Current Structure
```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   └── network/
├── features/
│   └── auth/
│       ├── data/
│       └── domain/
├── models/
├── providers/
├── screens/
├── services/
├── utils/
└── widgets/
```

### Recommended Structure (Feature-Based)
```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   └── theme/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── services/
│   ├── dashboard/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── services/
│   ├── attendance/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── services/
│   └── profile/
│       ├── data/
│       ├── domain/
│       ├── presentation/
│       │   ├── providers/
│       │   ├── screens/
│       │   └── widgets/
│       └── services/
├── shared/
│   ├── widgets/
│   │   └── common/
│   ├── utils/
│   └── models/
└── main.dart
```

## Naming Conventions

### Files
- **Screens**: `{feature}_screen.dart` (e.g., `employee_dashboard_screen.dart`)
- **Widgets**: `{name}_widget.dart` (e.g., `punch_button_widget.dart`)
- **Services**: `{name}_service.dart` (e.g., `geofence_service.dart`)
- **Providers**: `{name}_provider.dart` (e.g., `employee_provider.dart`)
- **Models**: `{name}_model.dart` (e.g., `employee_model.dart`)
- **Constants**: `app_{type}.dart` (e.g., `app_colors.dart`)

### Classes
- **Screens**: `{Feature}Screen` (e.g., `EmployeeDashboardScreen`)
- **Widgets**: `{Name}Widget` (e.g., `PunchButtonWidget`)
- **Services**: `{Name}Service` (e.g., `GeofenceService`)
- **Providers**: `{Name}Provider` (e.g., `EmployeeProvider`)

### Variables
- **Private**: `_variableName` (e.g., `_isLoading`)
- **Public**: `variableName` (e.g., `isLoading`)
- **Constants**: `CONSTANT_NAME` (e.g., `MAX_RETRIES`)

## Widget Breakdown Strategy

### Large Widgets to Refactor

#### 1. employee_dashboard.dart (1811 lines)
**Break into:**
- `dashboard_screen.dart` - Main screen
- `dashboard_app_bar.dart` - Top app bar
- `dashboard_content.dart` - Main content area
- `quick_stats_section.dart` - Stats cards
- `attendance_status_card.dart` - Attendance status display
- `attendance_details_card.dart` - Attendance details
- `attendance_logs_section.dart` - Attendance logs list
- `profile_section.dart` - Profile content

#### 2. punch_in_out_widget.dart (1827 lines)
**Break into:**
- `punch_in_out_widget.dart` - Main widget (orchestrator)
- `punch_header.dart` - Header section
- `working_duration_display.dart` - Duration circle
- `punch_status_indicator.dart` - Status display
- `punch_button.dart` - Punch action button
- `geofence_warning.dart` - Geofence restrictions
- `attendance_logs_section.dart` - Logs display
- `location_map_section.dart` - Map display

#### 3. geofence_map_widget.dart (836 lines)
**Break into:**
- `geofence_map_widget.dart` - Main widget
- `geofence_status_header.dart` - Status header
- `geofence_map_view.dart` - Map display
- `geofence_status_indicator.dart` - Status badge

## Constants Centralization

### Completed
- ✅ `app_constants.dart` - App-wide constants
- ✅ `app_strings.dart` - All UI strings
- ✅ `app_colors.dart` - Color definitions
- ✅ `app_dimensions.dart` - Spacing and sizing
- ✅ `app_values.dart` - Magic numbers and defaults

### Usage Rules
1. **Never hardcode strings** - Use `AppStrings.*`
2. **Never hardcode colors** - Use `AppColors.*` or `AppTheme.*`
3. **Never hardcode dimensions** - Use `AppDimensions.*`
4. **Never hardcode magic numbers** - Use `AppValues.*`

## Reusable Widgets Created

### Common Widgets
- ✅ `StatCard` - Display metrics
- ✅ `InfoRow` - Key-value pairs
- ✅ `StatusBadge` - Status indicators
- ✅ `DetailRow` - Detail rows with icons
- ✅ `StatItem` - Small stat items

### Attendance Widgets
- ✅ `WorkingDurationDisplay` - Duration circle
- ✅ `AttendanceLogItem` - Log item display

## Utilities Created

### Date/Time Utilities
- ✅ `DateFormatter` - Date formatting helpers
- ✅ `TimezoneHelper` - Timezone utilities
- ✅ `DurationHelper` - Duration calculations

## Code Cleanup Checklist

- [ ] Remove all `print()` statements (use proper logging)
- [ ] Extract repeated code patterns
- [ ] Simplify complex methods
- [ ] Add proper error handling
- [ ] Add documentation comments
- [ ] Ensure consistent formatting

## Migration Steps

1. **Phase 1**: Extract constants (✅ Completed)
2. **Phase 2**: Create reusable widgets (🔄 In Progress)
3. **Phase 3**: Break down large widgets
4. **Phase 4**: Reorganize folder structure
5. **Phase 5**: Clean up code

## Best Practices

1. **Single Responsibility**: Each widget should do one thing
2. **Composition over Inheritance**: Build complex widgets from simple ones
3. **DRY Principle**: Don't repeat yourself - extract common patterns
4. **Constants First**: Always use constants instead of magic values
5. **Type Safety**: Use proper types, avoid `dynamic` where possible
6. **Error Handling**: Always handle errors gracefully
7. **Documentation**: Document complex logic

