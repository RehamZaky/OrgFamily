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
  String get drawerSettings => 'Settings';

  @override
  String get drawerAbout => 'About';

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
  String get allCategories => 'All categories';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get notSet => 'Not set';

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
}
