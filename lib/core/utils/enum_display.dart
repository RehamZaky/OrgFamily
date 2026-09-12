import 'package:flutter/material.dart';

import '../../data/local/database.dart' show BudgetTransaction, Event;
import '../../data/local/tables/budget_table.dart';
import '../../data/local/tables/events_table.dart';
import '../../data/local/tables/family_members_table.dart';
import '../../data/local/tables/savings_goals_table.dart';
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

extension EventColorX on Event {
  /// The custom color if one was picked, otherwise the category's default —
  /// the single place every screen should read an event's color from.
  Color get displayColor => colorValue != null ? Color(colorValue!) : category.color;
}

extension BudgetTransactionDisplayX on BudgetTransaction {
  /// Only expenses get a real category breakdown (Groceries, Bills, …) —
  /// [TransactionCategory] doesn't meaningfully apply to money coming in or
  /// moving between accounts. Income shows its [incomeSource] instead (e.g.
  /// "Salary" rather than a generic "Income"), and a transfer shows the
  /// account it moved between. The single place every screen (Overview,
  /// Transactions) should read a transaction's icon/color/label from.
  IconData get displayIcon => switch (type) {
        TransactionType.expense => category.icon,
        TransactionType.income => incomeSource.icon,
        TransactionType.transfer => Icons.swap_horiz,
      };

  Color get displayColor => switch (type) {
        TransactionType.expense => category.color,
        TransactionType.income => AppColors.success,
        TransactionType.transfer => AppColors.info,
      };

  String displayLabel(AppLocalizations l10n) => switch (type) {
        TransactionType.expense => category.label(l10n),
        TransactionType.income => incomeSource.label(l10n),
        TransactionType.transfer =>
          '${account.label(l10n)} → ${toAccount.label(l10n)}',
      };
}

extension FamilyRoleX on FamilyRole {
  String get label => switch (this) {
        FamilyRole.owner => 'Owner',
        FamilyRole.adult => 'Adult',
        FamilyRole.child => 'Child',
      };
}

extension TransactionTypeX on TransactionType {
  String label(AppLocalizations l10n) => switch (this) {
        TransactionType.expense => l10n.transactionTypeExpense,
        TransactionType.income => l10n.transactionTypeIncome,
        TransactionType.transfer => l10n.transactionTypeTransfer,
      };
}

extension TransactionCategoryX on TransactionCategory {
  String label(AppLocalizations l10n) => switch (this) {
        TransactionCategory.groceries => l10n.transactionCategoryGroceries,
        TransactionCategory.transport => l10n.transactionCategoryTransport,
        TransactionCategory.bills => l10n.transactionCategoryBills,
        TransactionCategory.shopping => l10n.transactionCategoryShopping,
        TransactionCategory.health => l10n.transactionCategoryHealth,
        TransactionCategory.education => l10n.transactionCategoryEducation,
        TransactionCategory.foodDrinks => l10n.transactionCategoryFoodDrinks,
        TransactionCategory.other => l10n.transactionCategoryOther,
      };

  IconData get icon => switch (this) {
        TransactionCategory.groceries => Icons.shopping_cart_outlined,
        TransactionCategory.transport => Icons.directions_car_outlined,
        TransactionCategory.bills => Icons.bolt_outlined,
        TransactionCategory.shopping => Icons.shopping_bag_outlined,
        TransactionCategory.health => Icons.favorite_outline,
        TransactionCategory.education => Icons.school_outlined,
        TransactionCategory.foodDrinks => Icons.coffee_outlined,
        TransactionCategory.other => Icons.folder_outlined,
      };

  Color get color =>
      AppColors.budgetCategoryPalette[index % AppColors.budgetCategoryPalette.length];
}

extension IncomeSourceX on IncomeSource {
  String label(AppLocalizations l10n) => switch (this) {
        IncomeSource.salary => l10n.incomeSourceSalary,
        IncomeSource.freelance => l10n.incomeSourceFreelance,
        IncomeSource.business => l10n.incomeSourceBusiness,
        IncomeSource.bonus => l10n.incomeSourceBonus,
        IncomeSource.gift => l10n.incomeSourceGift,
        IncomeSource.refund => l10n.incomeSourceRefund,
        IncomeSource.other => l10n.incomeSourceOther,
      };

  IconData get icon => switch (this) {
        IncomeSource.salary => Icons.work_outline,
        IncomeSource.freelance => Icons.laptop_mac_outlined,
        IncomeSource.business => Icons.storefront_outlined,
        IncomeSource.bonus => Icons.card_giftcard_outlined,
        IncomeSource.gift => Icons.redeem_outlined,
        IncomeSource.refund => Icons.replay_outlined,
        IncomeSource.other => Icons.more_horiz,
      };
}

extension AccountX on Account {
  String label(AppLocalizations l10n) => switch (this) {
        Account.cash => l10n.accountCash,
        Account.bank => l10n.accountBank,
        Account.wallet => l10n.accountWallet,
        Account.other => l10n.accountOther,
      };

  IconData get icon => switch (this) {
        Account.cash => Icons.payments_outlined,
        Account.bank => Icons.account_balance_outlined,
        Account.wallet => Icons.account_balance_wallet_outlined,
        Account.other => Icons.more_horiz,
      };
}

extension SavingsGoalIconX on SavingsGoalIcon {
  String label(AppLocalizations l10n) => switch (this) {
        SavingsGoalIcon.vacation => l10n.savingsGoalIconVacation,
        SavingsGoalIcon.gadget => l10n.savingsGoalIconGadget,
        SavingsGoalIcon.emergency => l10n.savingsGoalIconEmergency,
        SavingsGoalIcon.education => l10n.savingsGoalIconEducation,
        SavingsGoalIcon.home => l10n.savingsGoalIconHome,
        SavingsGoalIcon.car => l10n.savingsGoalIconCar,
        SavingsGoalIcon.gift => l10n.savingsGoalIconGift,
        SavingsGoalIcon.other => l10n.savingsGoalIconOther,
      };

  IconData get icon => switch (this) {
        SavingsGoalIcon.vacation => Icons.beach_access_outlined,
        SavingsGoalIcon.gadget => Icons.laptop_mac_outlined,
        SavingsGoalIcon.emergency => Icons.shield_outlined,
        SavingsGoalIcon.education => Icons.school_outlined,
        SavingsGoalIcon.home => Icons.home_outlined,
        SavingsGoalIcon.car => Icons.directions_car_outlined,
        SavingsGoalIcon.gift => Icons.card_giftcard_outlined,
        SavingsGoalIcon.other => Icons.star_outline,
      };

  Color get color => AppColors.avatarPalette[index % AppColors.avatarPalette.length];
}
