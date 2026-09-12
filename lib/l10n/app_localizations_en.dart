// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OrgFamily';

  @override
  String get navHome => 'Home';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navLists => 'Lists';

  @override
  String get navFamily => 'Family';

  @override
  String get drawerProfile => 'Profile';

  @override
  String get drawerSwitchProfile => 'Switch profile';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerAbout => 'About';

  @override
  String get ourFamily => 'Our Family';

  @override
  String get ourFamilyTagline => 'Together we organize, plan and grow 💜';

  @override
  String get familySummaryMembers => 'Members';

  @override
  String get familySummaryDoneThisWeek => 'Done this week';

  @override
  String get familySummaryPointsThisWeek => 'Points this week';

  @override
  String get familyMembersHeading => 'Family Members';

  @override
  String get addMember => 'Add member';

  @override
  String get noFamilyMembersYet => 'No family members yet';

  @override
  String tasksTodayCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tasks',
      one: 'task',
    );
    return '$count $_temp0 today';
  }

  @override
  String tasksTodayAllDone(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tasks',
      one: 'task',
    );
    return '$count $_temp0 done today';
  }

  @override
  String pointsShort(Object count) {
    return '$count pts';
  }

  @override
  String get removeMemberTitle => 'Remove family member?';

  @override
  String removeMemberBody(Object name) {
    return '$name will be removed from your family.';
  }

  @override
  String get remove => 'Remove';

  @override
  String get you => 'You';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting, $name 👋';
  }

  @override
  String get greetingFallbackName => 'there';

  @override
  String get statTasksToday => 'Tasks today';

  @override
  String get statEvent => 'Event';

  @override
  String get statEvents => 'Events';

  @override
  String get statList => 'List';

  @override
  String get statLists => 'Lists';

  @override
  String get sectionTodaysPriorities => 'Today';

  @override
  String get sectionUpcomingEvents => 'Upcoming';

  @override
  String get sectionFamilyActivity => 'Family activity';

  @override
  String get sectionShopping => 'Shopping';

  @override
  String get viewAll => 'View all';

  @override
  String get emptyNothingDueToday => 'Nothing due today 🎉';

  @override
  String get emptyNoTasksYet => 'No tasks yet';

  @override
  String get emptyNoTasksHint =>
      'Try: Buy groceries, Pay electricity bill, Clean the kitchen';

  @override
  String get emptyNoUpcomingEvents => 'No upcoming events';

  @override
  String get emptyNoEventsYet => 'No events yet';

  @override
  String get emptyNoEventsHint => 'Try: Family dinner, School meeting';

  @override
  String get emptyNoListsYet => 'No lists yet';

  @override
  String get emptyNoListsHint => 'Try: Groceries list, Packing list';

  @override
  String get emptyNoItemsYet => 'No items yet';

  @override
  String get emptyNoItemsHint => 'Try: Milk, Eggs, Bread';

  @override
  String get emptyAllDone => 'All done ✓';

  @override
  String get emptyNoActivityYet => 'No activity yet';

  @override
  String get actionAddEvent => 'Add event';

  @override
  String get actionAddItem => 'Add';

  @override
  String get taskStatusDone => 'Done';

  @override
  String get overdue => 'Overdue';

  @override
  String get overdueToday => 'Overdue today';

  @override
  String get overdueYesterday => 'Overdue since yesterday';

  @override
  String get yesterday => 'Yesterday';

  @override
  String overdueByDays(num count) {
    return 'Overdue by $count days';
  }

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get actionTomorrow => 'Tomorrow';

  @override
  String get taskTimeOptional => 'Time (optional)';

  @override
  String get notificationOverdueFollowupTitle => 'Still needs attention';

  @override
  String notificationOverdueFollowupBody(Object title) {
    return '$title is overdue';
  }

  @override
  String itemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count $_temp0';
  }

  @override
  String activityCompleted(Object title) {
    return 'completed \"$title\"';
  }

  @override
  String activityAdded(Object item, Object list) {
    return 'added \"$item\" to $list';
  }

  @override
  String get activitySomeone => 'Someone';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get later => 'Later';

  @override
  String get tasksTabAll => 'All';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(num count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgo(num count) {
    return '$count hours ago';
  }

  @override
  String daysAgo(num count) {
    return '$count days ago';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingAddYourself => 'Add yourself';

  @override
  String get onboardingComingSoon => 'Coming soon';

  @override
  String get onboardingPage1Title => 'Keep your family organized';

  @override
  String get onboardingPage1Body =>
      'Manage tasks, events, lists and more — all in one place.';

  @override
  String get onboardingFeatureTasks => 'Tasks';

  @override
  String get onboardingFeatureEvents => 'Events';

  @override
  String get onboardingFeatureLists => 'Lists';

  @override
  String get onboardingFeatureProgress => 'Progress';

  @override
  String get onboardingPage2Title => 'Share and stay connected';

  @override
  String get onboardingPage2Body =>
      'Assign tasks, plan together and keep everyone in sync.';

  @override
  String get onboardingFeedTaskAdded => 'Added a new task';

  @override
  String get onboardingFeedListUpdated => 'Updated the groceries list';

  @override
  String get onboardingFeedTaskCompleted => 'Completed her task!';

  @override
  String get onboardingFeedEventAdded => 'Added an event';

  @override
  String get onboardingPage3Title => 'Manage money together';

  @override
  String get onboardingPage3Body =>
      'Track expenses, plan budgets and reach your family goals.';

  @override
  String get onboardingBudgetGroceries => 'Groceries';

  @override
  String get onboardingBudgetHousehold => 'Household';

  @override
  String get onboardingBudgetDining => 'Dining';

  @override
  String get onboardingBudgetTransport => 'Transport';

  @override
  String get onboardingPage4Title => 'Build a happier tomorrow';

  @override
  String get onboardingPage4Body => 'Small steps today make a big difference.';

  @override
  String get onboardingChecklistQualityTime => 'More quality time';

  @override
  String get onboardingChecklistLessStress => 'Less stress';

  @override
  String get onboardingChecklistGetThingsDone => 'Get things done';

  @override
  String get onboardingChecklistHappierFamily => 'A happier family';

  @override
  String get onboardingPage5Title => 'Let\'s set up your family';

  @override
  String get onboardingPage5Body =>
      'Add yourself first — you can bring in the rest of the family right after.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeSystemHint =>
      'System follows your device\'s appearance setting.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsMoneyGuide => 'Income & Accounts Guide';

  @override
  String get settingsMoneyGuideHint =>
      'What Income Source, Account, and Transfer mean';

  @override
  String get moneyGuideTitle => 'Income & Accounts Guide';

  @override
  String get moneyGuideIntro =>
      'Every Money transaction tracks two separate things: why the money moved, and where it physically is.';

  @override
  String get moneyGuideIncomeSourceHeading =>
      'Income Source — why money came in';

  @override
  String get moneyGuideIncomeSourceBody =>
      'When you log income, pick what it\'s for: Salary, Freelance, Business, Bonus, Gift, Refund, or Other.';

  @override
  String get moneyGuideAccountHeading => 'Account — where the money is';

  @override
  String get moneyGuideAccountBody =>
      'Every transaction also has an Account: Cash, Bank, Wallet, or Other. For an expense, it\'s what you paid from. For income, it\'s what you received into.';

  @override
  String get moneyGuideTransferHeading =>
      'Transfer — moving money between your own accounts';

  @override
  String get moneyGuideTransferBody =>
      'Use Transfer when money moves between your own accounts without being new income or a real expense — like depositing cash into the bank. Pick a From account and a To account; your total balance doesn\'t change.';

  @override
  String get moneyGuideExamplesHeading => 'Examples';

  @override
  String get moneyGuideExample1 => 'E£25,000 Salary → received into Bank';

  @override
  String get moneyGuideExample2 => 'E£2,000 Freelance → received as Cash';

  @override
  String get moneyGuideExample3 =>
      'Cash → Bank (Transfer): total balance unchanged';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutAppName => 'OrgFamily';

  @override
  String get aboutVersion => 'Version 1.0.0 · V1 MVP';

  @override
  String get aboutDescription =>
      'A shared family organizer: tasks, calendar, and shopping lists that every family member sees and updates together.';

  @override
  String get aboutBuiltWith => 'Built with';

  @override
  String get aboutTechStack => 'Flutter, Riverpod, and Drift (local SQLite).';

  @override
  String get aboutLocalNote =>
      'This is a local-only V1 — your family\'s data stays on this device. Cloud sync across devices is planned for a later version.';

  @override
  String get taskPriorityLow => 'Low';

  @override
  String get taskPriorityNormal => 'Normal';

  @override
  String get taskPriorityHigh => 'High';

  @override
  String get taskPriorityUrgent => 'Urgent';

  @override
  String get taskCategoryHome => 'Home';

  @override
  String get taskCategoryShopping => 'Shopping';

  @override
  String get taskCategoryFinance => 'Finance';

  @override
  String get taskCategorySchool => 'School';

  @override
  String get taskCategoryCar => 'Car';

  @override
  String get taskCategoryChores => 'Chores';

  @override
  String get taskCategoryFamily => 'Family';

  @override
  String get taskCategoryEvents => 'Events';

  @override
  String get taskCategoryAppointments => 'Appointments';

  @override
  String get taskCategoryErrands => 'Errands';

  @override
  String get taskCategoryWork => 'Work';

  @override
  String get taskCategoryOther => 'Other';

  @override
  String get taskRecurrenceNone => 'Does not repeat';

  @override
  String get taskRecurrenceDaily => 'Daily';

  @override
  String get taskRecurrenceWeekly => 'Weekly';

  @override
  String get taskRecurrenceMonthly => 'Monthly';

  @override
  String get eventCategoryBirthday => 'Birthday';

  @override
  String get eventCategorySchool => 'School';

  @override
  String get eventCategoryAppointment => 'Appointment';

  @override
  String get eventCategoryWork => 'Work';

  @override
  String get eventCategoryTravel => 'Travel';

  @override
  String get eventCategoryHome => 'Home';

  @override
  String get eventCategoryFamily => 'Family';

  @override
  String get eventCategoryOther => 'Other';

  @override
  String get labelTitle => 'Title';

  @override
  String get labelCategory => 'Category';

  @override
  String get labelPriority => 'Priority';

  @override
  String get labelDueDate => 'Due date';

  @override
  String get labelRepeat => 'Repeat';

  @override
  String get labelAssignedTo => 'Assigned to';

  @override
  String get labelWho => 'Who';

  @override
  String get labelDateTime => 'Date & Time';

  @override
  String get labelNotes => 'Notes';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get everyone => 'Everyone';

  @override
  String get calendarSharedSection => 'Shared';

  @override
  String peopleCount(Object count) {
    return '$count people';
  }

  @override
  String get allCategories => 'All categories';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get notSet => 'Not set';

  @override
  String permissionDenied(String role) {
    return 'You don\'t have permission to do that as $role.';
  }

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get filter => 'Filter';

  @override
  String get search => 'Search';

  @override
  String get closeSearch => 'Close search';

  @override
  String get addItemScreenTitle => 'Add Item';

  @override
  String get addItemNameLabel => 'Item name';

  @override
  String get addItemNameHint => 'Enter item name';

  @override
  String get addItemAddToListLabel => 'Add to list';

  @override
  String get addItemNewListValue => 'New \"Shopping\" list';

  @override
  String get addItemButtonLabel => 'Add Item';

  @override
  String get taskDetailsScreenTitle => 'Task Details';

  @override
  String get taskDetailsNotesHint => 'Write a notes or task description…';

  @override
  String get taskDetailsNotesSaved => 'Notes saved';

  @override
  String get eventFormNewTitle => 'New Event';

  @override
  String get eventFormEditTitle => 'Edit Event';

  @override
  String get eventFormSubtitleNew => 'Add the details of your event';

  @override
  String get eventFormSubtitleEdit => 'Update the details of your event';

  @override
  String get eventFormTitleHint => 'Event title';

  @override
  String get eventFormLocationLabel => 'Location (optional)';

  @override
  String get eventFormLocationHint => 'Add location';

  @override
  String get eventFormWhoHint => 'Add people who are part of this event.';

  @override
  String get eventFormDescriptionHint => 'Add a description';

  @override
  String get labelColor => 'Color';

  @override
  String get eventFormColorDefaultHint => 'Default (matches category)';

  @override
  String get eventFormAttachmentLabel => 'Attachment';

  @override
  String get eventFormAddAttachment => 'Add attachment';

  @override
  String get eventFormSaveButton => 'Save Event';

  @override
  String get eventFormSaveChangesButton => 'Save changes';

  @override
  String get eventFormDeleteTitle => 'Delete event?';

  @override
  String eventFormDeleteBody(Object title) {
    return '\"$title\" will be removed.';
  }

  @override
  String get listsSearchHint => 'Search lists…';

  @override
  String get newList => 'New list';

  @override
  String get noListsMatch => 'No lists match your search';

  @override
  String itemsLeft(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'items',
      one: 'item',
    );
    return '$count $_temp0 left';
  }

  @override
  String itemsCompleted(Object done, Object total) {
    return '$done of $total completed';
  }

  @override
  String get tasksSearchHint => 'Search tasks…';

  @override
  String get noTasksMatch => 'No tasks match';

  @override
  String get calendarSearchHint => 'Search events…';

  @override
  String get noEventsMatch => 'No events match';

  @override
  String get noEventsThisDay => 'No events this day';

  @override
  String get taskFormNewTitle => 'New task';

  @override
  String get taskFormEditTitle => 'Edit task';

  @override
  String get taskFormQuestion => 'What needs to be done?';

  @override
  String get taskFormTitleHint => 'e.g. Buy groceries';

  @override
  String get taskFormAssignTo => 'Assign to';

  @override
  String get taskFormTimeLabel => 'Time';

  @override
  String get taskFormNotesLabel => 'Notes (optional)';

  @override
  String get taskFormNoteHint => 'Add a note…';

  @override
  String get taskFormReminder => 'Reminder';

  @override
  String get taskFormChecklist => 'Checklist';

  @override
  String get taskFormAttachment => 'Attachment';

  @override
  String get taskFormSubtask => 'Subtask';

  @override
  String taskFormComingSoon(Object feature) {
    return '$feature is coming soon';
  }

  @override
  String get taskFormCreateButton => 'Create Task';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get completed => 'Completed';

  @override
  String get tasksEmptyHint => 'Tap + to add something the family needs to do.';

  @override
  String get sectionNotes => 'Notes';

  @override
  String get notesSortByDate => 'Sort by date';

  @override
  String get notesSortByColor => 'Sort by color';

  @override
  String get notesEmptyHint =>
      'No notes yet — tap + and choose Note to add one.';

  @override
  String get noteHint => 'Write a note…';

  @override
  String get quickAddTitle => 'What do you want to add?';

  @override
  String get quickAddTask => 'Task';

  @override
  String get quickAddEvent => 'Event';

  @override
  String get quickAddShopping => 'Shopping';

  @override
  String get quickAddNote => 'Note';

  @override
  String get quickAddTaskMoreOptions => 'More options';

  @override
  String get quickAddTaskAdd => 'Add Task';

  @override
  String get quickAddTaskVoiceUnavailable =>
      'Voice input isn\'t available on this device';

  @override
  String get quickAddTaskDateShort => 'Date';

  @override
  String get quickAddTaskAssignShort => 'Assign';

  @override
  String get navBudget => 'Money';

  @override
  String get quickAddTransaction => 'Transaction';

  @override
  String get moneyOverviewTitle => 'Family Finances';

  @override
  String get moneyOverviewTagline => 'Together for a brighter tomorrow';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get income => 'Income';

  @override
  String get expenses => 'Expenses';

  @override
  String get savings => 'Savings';

  @override
  String netThisMonth(Object amount) {
    return 'Net: $amount';
  }

  @override
  String get moneyTileBudget => 'Budget';

  @override
  String get moneyTileGoals => 'Goals';

  @override
  String noBudgetSetForMonth(Object month) {
    return 'No budget set for $month';
  }

  @override
  String budgetRemainingAmount(Object amount) {
    return '$amount remaining';
  }

  @override
  String goalsSavedSummary(Object amount, Object count) {
    return '$amount saved across $count goals';
  }

  @override
  String get spendingByCategory => 'Spending by Category';

  @override
  String get thisMonth => 'This month';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get transactionsSearchHint => 'Search transactions...';

  @override
  String get transactionFilterAll => 'All';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get transactionsEmptyHint =>
      'Tap + and choose Transaction to add one.';

  @override
  String get budgetTitle => 'Monthly Budget';

  @override
  String budgetUsedPercent(Object percent) {
    return '$percent%';
  }

  @override
  String get budgetUsedLabel => 'Used';

  @override
  String get budgetRemaining => 'Remaining';

  @override
  String get categoryBudgets => 'Category Budgets';

  @override
  String get budgetLimitPlaceholder => 'Limit';

  @override
  String get setBudget => 'Set Budget';

  @override
  String get setTotalBudget => 'Total monthly budget';

  @override
  String get setCategoryBudget => 'Category limit';

  @override
  String get noBudgetSet => 'No budget set';

  @override
  String get currency => 'Currency';

  @override
  String budgetUnallocatedLabel(Object amount) {
    return 'Flexible / unallocated: $amount';
  }

  @override
  String budgetOverTotalWarning(Object amount) {
    return '$amount over your monthly budget';
  }

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get transactionAmount => 'Amount';

  @override
  String get transactionTitleHint => 'e.g. Groceries';

  @override
  String get transactionTypeLabel => 'Type';

  @override
  String get transactionCategoryLabel => 'Category';

  @override
  String get transactionIncomeSourceLabel => 'Income Source';

  @override
  String get transactionPaidFromLabel => 'Paid From';

  @override
  String get transactionReceivedIntoLabel => 'Received Into';

  @override
  String get transactionFromAccountLabel => 'From';

  @override
  String get transactionToAccountLabel => 'To';

  @override
  String get transactionDateLabel => 'Date';

  @override
  String get transactionNoteLabel => 'Note (optional)';

  @override
  String get warningApproachingLimit => 'Approaching limit';

  @override
  String get warningOverBudget => 'Over budget';

  @override
  String get transactionTypeExpense => 'Expense';

  @override
  String get transactionTypeIncome => 'Income';

  @override
  String get transactionTypeTransfer => 'Transfer';

  @override
  String get transactionCategoryGroceries => 'Groceries';

  @override
  String get transactionCategoryTransport => 'Transport';

  @override
  String get transactionCategoryBills => 'Bills';

  @override
  String get transactionCategoryShopping => 'Shopping';

  @override
  String get transactionCategoryHealth => 'Health';

  @override
  String get transactionCategoryEducation => 'Education';

  @override
  String get transactionCategoryFoodDrinks => 'Food & Drinks';

  @override
  String get transactionCategoryOther => 'Other';

  @override
  String get incomeSourceSalary => 'Salary';

  @override
  String get incomeSourceFreelance => 'Freelance';

  @override
  String get incomeSourceBusiness => 'Business';

  @override
  String get incomeSourceBonus => 'Bonus';

  @override
  String get incomeSourceGift => 'Gift';

  @override
  String get incomeSourceRefund => 'Refund';

  @override
  String get incomeSourceOther => 'Other';

  @override
  String get accountCash => 'Cash';

  @override
  String get accountBank => 'Bank';

  @override
  String get accountWallet => 'Wallet';

  @override
  String get accountOther => 'Other';

  @override
  String get goalsTitle => 'Savings Goals';

  @override
  String get goalsBanner => 'Big dreams start with small steps';

  @override
  String get goalsBannerSubtitle => 'Save today for a brighter tomorrow 💜';

  @override
  String get goalCompleted => 'Completed';

  @override
  String goalCelebrationMessage(Object amount) {
    return '$amount saved!';
  }

  @override
  String goalOfTarget(Object amount) {
    return 'of $amount';
  }

  @override
  String goalTargetDateLabel(Object date) {
    return 'Target: $date';
  }

  @override
  String get addGoal => 'Add Goal';

  @override
  String get editGoal => 'Edit Goal';

  @override
  String get goalNameHint => 'e.g. Family Vacation';

  @override
  String get goalTargetAmount => 'Target amount';

  @override
  String get goalTargetDateOptional => 'Target date (optional)';

  @override
  String get contribute => 'Contribute';

  @override
  String get contributeAmount => 'Amount to add';

  @override
  String get noGoalsYet => 'No savings goals yet';

  @override
  String get goalsEmptyHint => 'Tap + to start a new goal.';

  @override
  String get savingsGoalIconVacation => 'Vacation';

  @override
  String get savingsGoalIconGadget => 'Gadget';

  @override
  String get savingsGoalIconEmergency => 'Emergency Fund';

  @override
  String get savingsGoalIconEducation => 'Education';

  @override
  String get savingsGoalIconHome => 'Home';

  @override
  String get savingsGoalIconCar => 'Car';

  @override
  String get savingsGoalIconGift => 'Gift';

  @override
  String get savingsGoalIconOther => 'Other';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsSpendingTab => 'Spending';

  @override
  String get reportsIncomeTab => 'Income';

  @override
  String get reportsSavingsTab => 'Savings';

  @override
  String get monthlySpending => 'Monthly Spending';

  @override
  String get monthlyIncome => 'Monthly Income';

  @override
  String get topCategories => 'Top Categories';

  @override
  String insightLessSpending(Object percent) {
    return 'You spent $percent% less this month. Great job!';
  }

  @override
  String insightMoreSpending(Object percent) {
    return 'You spent $percent% more this month than last.';
  }

  @override
  String get insightNoChange => 'About the same as last month.';
}
