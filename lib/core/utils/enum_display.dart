import 'package:flutter/material.dart';

import '../../data/local/tables/events_table.dart';
import '../../data/local/tables/family_members_table.dart';
import '../../data/local/tables/tasks_table.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

extension TaskPriorityX on TaskPriority {
  String label(AppLocalizations l10n) => switch (this) {
        TaskPriority.low => l10n.taskPriorityLow,
        TaskPriority.normal => l10n.taskPriorityNormal,
        TaskPriority.high => l10n.taskPriorityHigh,
        TaskPriority.urgent => l10n.taskPriorityUrgent,
      };

  Color get color => switch (this) {
        TaskPriority.low => AppColors.priorityLow,
        TaskPriority.normal => AppColors.taskPriorityNormal,
        TaskPriority.high => AppColors.taskPriorityHigh,
        TaskPriority.urgent => AppColors.priorityUrgent,
      };

  IconData get icon => switch (this) {
        TaskPriority.low => Icons.south_rounded,
        TaskPriority.normal => Icons.remove_rounded,
        TaskPriority.high => Icons.north_rounded,
        TaskPriority.urgent => Icons.keyboard_double_arrow_up_rounded,
      };

  /// Family points awarded for completing a task of this priority.
  int get points => switch (this) {
        TaskPriority.low => 5,
        TaskPriority.normal => 10,
        TaskPriority.high => 15,
        TaskPriority.urgent => 20,
      };
}

extension TaskCategoryX on TaskCategory {
  String label(AppLocalizations l10n) => switch (this) {
        TaskCategory.home => l10n.taskCategoryHome,
        TaskCategory.shopping => l10n.taskCategoryShopping,
        TaskCategory.finance => l10n.taskCategoryFinance,
        TaskCategory.school => l10n.taskCategorySchool,
        TaskCategory.car => l10n.taskCategoryCar,
        TaskCategory.chores => l10n.taskCategoryChores,
        TaskCategory.family => l10n.taskCategoryFamily,
        TaskCategory.events => l10n.taskCategoryEvents,
        TaskCategory.appointments => l10n.taskCategoryAppointments,
        TaskCategory.errands => l10n.taskCategoryErrands,
        TaskCategory.work => l10n.taskCategoryWork,
        TaskCategory.other => l10n.taskCategoryOther,
      };

  IconData get icon => switch (this) {
        TaskCategory.home => Icons.home_outlined,
        TaskCategory.shopping => Icons.shopping_cart_outlined,
        TaskCategory.finance => Icons.attach_money,
        TaskCategory.school => Icons.school_outlined,
        TaskCategory.car => Icons.directions_car_outlined,
        TaskCategory.chores => Icons.cleaning_services_outlined,
        TaskCategory.family => Icons.family_restroom,
        TaskCategory.events => Icons.celebration_outlined,
        TaskCategory.appointments => Icons.medical_services_outlined,
        TaskCategory.errands => Icons.local_shipping_outlined,
        TaskCategory.work => Icons.work_outline,
        TaskCategory.other => Icons.folder_outlined,
      };

  Color get color => switch (this) {
        TaskCategory.home => AppColors.avatarPalette[3],
        TaskCategory.shopping => AppColors.avatarPalette[4],
        TaskCategory.finance => AppColors.avatarPalette[3],
        TaskCategory.school => AppColors.avatarPalette[2],
        TaskCategory.car => AppColors.avatarPalette[5],
        TaskCategory.chores => AppColors.avatarPalette[0],
        TaskCategory.family => AppColors.avatarPalette[1],
        TaskCategory.events => AppColors.avatarPalette[4],
        TaskCategory.appointments => AppColors.avatarPalette[1],
        TaskCategory.errands => AppColors.avatarPalette[2],
        TaskCategory.work => AppColors.avatarPalette[0],
        TaskCategory.other => AppColors.priorityLow,
      };
}

extension TaskRecurrenceX on TaskRecurrence {
  String label(AppLocalizations l10n) => switch (this) {
        TaskRecurrence.none => l10n.taskRecurrenceNone,
        TaskRecurrence.daily => l10n.taskRecurrenceDaily,
        TaskRecurrence.weekly => l10n.taskRecurrenceWeekly,
        TaskRecurrence.monthly => l10n.taskRecurrenceMonthly,
      };
}

extension EventCategoryX on EventCategory {
  String label(AppLocalizations l10n) => switch (this) {
        EventCategory.birthday => l10n.eventCategoryBirthday,
        EventCategory.school => l10n.eventCategorySchool,
        EventCategory.appointment => l10n.eventCategoryAppointment,
        EventCategory.work => l10n.eventCategoryWork,
        EventCategory.travel => l10n.eventCategoryTravel,
        EventCategory.home => l10n.eventCategoryHome,
        EventCategory.family => l10n.eventCategoryFamily,
        EventCategory.other => l10n.eventCategoryOther,
      };

  IconData get icon => switch (this) {
        EventCategory.birthday => Icons.cake_outlined,
        EventCategory.school => Icons.school_outlined,
        EventCategory.appointment => Icons.medical_services_outlined,
        EventCategory.work => Icons.work_outline,
        EventCategory.travel => Icons.flight_takeoff,
        EventCategory.home => Icons.home_outlined,
        EventCategory.family => Icons.family_restroom,
        EventCategory.other => Icons.event_outlined,
      };

  Color get color => switch (this) {
        EventCategory.birthday => AppColors.eventPalette[1], // pink
        EventCategory.school => AppColors.eventPalette[2], // blue
        EventCategory.appointment => AppColors.eventPalette[3], // green
        EventCategory.work => AppColors.eventPalette[4], // orange
        EventCategory.travel => AppColors.eventPalette[5], // cyan
        EventCategory.home => AppColors.eventPalette[0], // purple
        EventCategory.family => AppColors.eventPalette[1], // pink
        EventCategory.other => AppColors.priorityLow, // neutral
      };
}

extension FamilyRoleX on FamilyRole {
  String get label => switch (this) {
        FamilyRole.owner => 'Owner',
        FamilyRole.adult => 'Adult',
        FamilyRole.child => 'Child',
      };
}
