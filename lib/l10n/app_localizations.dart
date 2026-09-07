import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OrgFamily'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get navLists;

  /// No description provided for @navFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get navFamily;

  /// No description provided for @drawerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get drawerProfile;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get drawerAbout;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingWithName.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name} 👋'**
  String greetingWithName(Object greeting, Object name);

  /// No description provided for @greetingFallbackName.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get greetingFallbackName;

  /// No description provided for @statTasksToday.
  ///
  /// In en, this message translates to:
  /// **'Tasks today'**
  String get statTasksToday;

  /// No description provided for @statEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get statEvent;

  /// No description provided for @statEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get statEvents;

  /// No description provided for @statList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get statList;

  /// No description provided for @statLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get statLists;

  /// No description provided for @sectionTodaysPriorities.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get sectionTodaysPriorities;

  /// No description provided for @sectionUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get sectionUpcomingEvents;

  /// No description provided for @sectionFamilyActivity.
  ///
  /// In en, this message translates to:
  /// **'Family activity'**
  String get sectionFamilyActivity;

  /// No description provided for @sectionShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get sectionShopping;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @emptyNothingDueToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today 🎉'**
  String get emptyNothingDueToday;

  /// No description provided for @emptyNoTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get emptyNoTasksYet;

  /// No description provided for @emptyNoTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Try: Buy groceries, Pay electricity bill, Clean the kitchen'**
  String get emptyNoTasksHint;

  /// No description provided for @emptyNoUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get emptyNoUpcomingEvents;

  /// No description provided for @emptyNoEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get emptyNoEventsYet;

  /// No description provided for @emptyNoEventsHint.
  ///
  /// In en, this message translates to:
  /// **'Try: Family dinner, School meeting'**
  String get emptyNoEventsHint;

  /// No description provided for @emptyNoListsYet.
  ///
  /// In en, this message translates to:
  /// **'No lists yet'**
  String get emptyNoListsYet;

  /// No description provided for @emptyNoListsHint.
  ///
  /// In en, this message translates to:
  /// **'Try: Groceries list, Packing list'**
  String get emptyNoListsHint;

  /// No description provided for @emptyNoItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get emptyNoItemsYet;

  /// No description provided for @emptyNoItemsHint.
  ///
  /// In en, this message translates to:
  /// **'Try: Milk, Eggs, Bread'**
  String get emptyNoItemsHint;

  /// No description provided for @emptyAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done ✓'**
  String get emptyAllDone;

  /// No description provided for @emptyNoActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get emptyNoActivityYet;

  /// No description provided for @actionAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get actionAddEvent;

  /// No description provided for @actionAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAddItem;

  /// No description provided for @taskStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskStatusDone;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, one{item} other{items}}'**
  String itemsCount(num count);

  /// No description provided for @activityCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed \"{title}\"'**
  String activityCompleted(Object title);

  /// No description provided for @activityAdded.
  ///
  /// In en, this message translates to:
  /// **'added \"{item}\" to {list}'**
  String activityAdded(Object item, Object list);

  /// No description provided for @activitySomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get activitySomeone;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @tasksTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tasksTabAll;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(num count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(num count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(num count);

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingAddYourself.
  ///
  /// In en, this message translates to:
  /// **'Add yourself'**
  String get onboardingAddYourself;

  /// No description provided for @onboardingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get onboardingComingSoon;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Keep your family organized'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Manage tasks, events, lists and more — all in one place.'**
  String get onboardingPage1Body;

  /// No description provided for @onboardingFeatureTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get onboardingFeatureTasks;

  /// No description provided for @onboardingFeatureEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get onboardingFeatureEvents;

  /// No description provided for @onboardingFeatureLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get onboardingFeatureLists;

  /// No description provided for @onboardingFeatureProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get onboardingFeatureProgress;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Share and stay connected'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Assign tasks, plan together and keep everyone in sync.'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingFeedTaskAdded.
  ///
  /// In en, this message translates to:
  /// **'Added a new task'**
  String get onboardingFeedTaskAdded;

  /// No description provided for @onboardingFeedListUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated the groceries list'**
  String get onboardingFeedListUpdated;

  /// No description provided for @onboardingFeedTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed her task!'**
  String get onboardingFeedTaskCompleted;

  /// No description provided for @onboardingFeedEventAdded.
  ///
  /// In en, this message translates to:
  /// **'Added an event'**
  String get onboardingFeedEventAdded;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Manage money together'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Track expenses, plan budgets and reach your family goals.'**
  String get onboardingPage3Body;

  /// No description provided for @onboardingBudgetGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get onboardingBudgetGroceries;

  /// No description provided for @onboardingBudgetHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get onboardingBudgetHousehold;

  /// No description provided for @onboardingBudgetDining.
  ///
  /// In en, this message translates to:
  /// **'Dining'**
  String get onboardingBudgetDining;

  /// No description provided for @onboardingBudgetTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get onboardingBudgetTransport;

  /// No description provided for @onboardingPage4Title.
  ///
  /// In en, this message translates to:
  /// **'Build a happier tomorrow'**
  String get onboardingPage4Title;

  /// No description provided for @onboardingPage4Body.
  ///
  /// In en, this message translates to:
  /// **'Small steps today make a big difference.'**
  String get onboardingPage4Body;

  /// No description provided for @onboardingChecklistQualityTime.
  ///
  /// In en, this message translates to:
  /// **'More quality time'**
  String get onboardingChecklistQualityTime;

  /// No description provided for @onboardingChecklistLessStress.
  ///
  /// In en, this message translates to:
  /// **'Less stress'**
  String get onboardingChecklistLessStress;

  /// No description provided for @onboardingChecklistGetThingsDone.
  ///
  /// In en, this message translates to:
  /// **'Get things done'**
  String get onboardingChecklistGetThingsDone;

  /// No description provided for @onboardingChecklistHappierFamily.
  ///
  /// In en, this message translates to:
  /// **'A happier family'**
  String get onboardingChecklistHappierFamily;

  /// No description provided for @onboardingPage5Title.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your family'**
  String get onboardingPage5Title;

  /// No description provided for @onboardingPage5Body.
  ///
  /// In en, this message translates to:
  /// **'Add yourself first — you can bring in the rest of the family right after.'**
  String get onboardingPage5Body;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeSystemHint.
  ///
  /// In en, this message translates to:
  /// **'System follows your device\'s appearance setting.'**
  String get settingsThemeSystemHint;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get settingsLanguageArabic;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutAppName.
  ///
  /// In en, this message translates to:
  /// **'OrgFamily'**
  String get aboutAppName;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0 · V1 MVP'**
  String get aboutVersion;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A shared family organizer: tasks, calendar, and shopping lists that every family member sees and updates together.'**
  String get aboutDescription;

  /// No description provided for @aboutBuiltWith.
  ///
  /// In en, this message translates to:
  /// **'Built with'**
  String get aboutBuiltWith;

  /// No description provided for @aboutTechStack.
  ///
  /// In en, this message translates to:
  /// **'Flutter, Riverpod, and Drift (local SQLite).'**
  String get aboutTechStack;

  /// No description provided for @aboutLocalNote.
  ///
  /// In en, this message translates to:
  /// **'This is a local-only V1 — your family\'s data stays on this device. Cloud sync across devices is planned for a later version.'**
  String get aboutLocalNote;

  /// No description provided for @taskPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get taskPriorityLow;

  /// No description provided for @taskPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get taskPriorityNormal;

  /// No description provided for @taskPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get taskPriorityHigh;

  /// No description provided for @taskPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get taskPriorityUrgent;

  /// No description provided for @taskCategoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get taskCategoryHome;

  /// No description provided for @taskCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get taskCategoryShopping;

  /// No description provided for @taskCategoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get taskCategoryFinance;

  /// No description provided for @taskCategorySchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get taskCategorySchool;

  /// No description provided for @taskCategoryCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get taskCategoryCar;

  /// No description provided for @taskCategoryChores.
  ///
  /// In en, this message translates to:
  /// **'Chores'**
  String get taskCategoryChores;

  /// No description provided for @taskCategoryFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get taskCategoryFamily;

  /// No description provided for @taskCategoryEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get taskCategoryEvents;

  /// No description provided for @taskCategoryAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get taskCategoryAppointments;

  /// No description provided for @taskCategoryErrands.
  ///
  /// In en, this message translates to:
  /// **'Errands'**
  String get taskCategoryErrands;

  /// No description provided for @taskCategoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get taskCategoryWork;

  /// No description provided for @taskCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get taskCategoryOther;

  /// No description provided for @taskRecurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get taskRecurrenceNone;

  /// No description provided for @taskRecurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get taskRecurrenceDaily;

  /// No description provided for @taskRecurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get taskRecurrenceWeekly;

  /// No description provided for @taskRecurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get taskRecurrenceMonthly;

  /// No description provided for @eventCategoryBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get eventCategoryBirthday;

  /// No description provided for @eventCategorySchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get eventCategorySchool;

  /// No description provided for @eventCategoryAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get eventCategoryAppointment;

  /// No description provided for @eventCategoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get eventCategoryWork;

  /// No description provided for @eventCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get eventCategoryTravel;

  /// No description provided for @eventCategoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get eventCategoryHome;

  /// No description provided for @eventCategoryFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get eventCategoryFamily;

  /// No description provided for @eventCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get eventCategoryOther;

  /// No description provided for @labelTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get labelTitle;

  /// No description provided for @labelCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get labelCategory;

  /// No description provided for @labelPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get labelPriority;

  /// No description provided for @labelDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get labelDueDate;

  /// No description provided for @labelRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get labelRepeat;

  /// No description provided for @labelAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get labelAssignedTo;

  /// No description provided for @labelWho.
  ///
  /// In en, this message translates to:
  /// **'Who'**
  String get labelWho;

  /// No description provided for @labelDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get labelDateTime;

  /// No description provided for @labelNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get labelNotes;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get unassigned;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @closeSearch.
  ///
  /// In en, this message translates to:
  /// **'Close search'**
  String get closeSearch;

  /// No description provided for @addItemScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItemScreenTitle;

  /// No description provided for @addItemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get addItemNameLabel;

  /// No description provided for @addItemNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter item name'**
  String get addItemNameHint;

  /// No description provided for @addItemAddToListLabel.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get addItemAddToListLabel;

  /// No description provided for @addItemNewListValue.
  ///
  /// In en, this message translates to:
  /// **'New \"Shopping\" list'**
  String get addItemNewListValue;

  /// No description provided for @addItemButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItemButtonLabel;

  /// No description provided for @taskDetailsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetailsScreenTitle;

  /// No description provided for @taskDetailsNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Write a notes or task description…'**
  String get taskDetailsNotesHint;

  /// No description provided for @taskDetailsNotesSaved.
  ///
  /// In en, this message translates to:
  /// **'Notes saved'**
  String get taskDetailsNotesSaved;

  /// No description provided for @eventFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Event'**
  String get eventFormNewTitle;

  /// No description provided for @eventFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get eventFormEditTitle;

  /// No description provided for @eventFormSubtitleNew.
  ///
  /// In en, this message translates to:
  /// **'Add the details of your event'**
  String get eventFormSubtitleNew;

  /// No description provided for @eventFormSubtitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Update the details of your event'**
  String get eventFormSubtitleEdit;

  /// No description provided for @eventFormTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get eventFormTitleHint;

  /// No description provided for @eventFormLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location (optional)'**
  String get eventFormLocationLabel;

  /// No description provided for @eventFormLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Add location'**
  String get eventFormLocationHint;

  /// No description provided for @eventFormWhoHint.
  ///
  /// In en, this message translates to:
  /// **'Add people who are part of this event.'**
  String get eventFormWhoHint;

  /// No description provided for @eventFormSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Event'**
  String get eventFormSaveButton;

  /// No description provided for @eventFormSaveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get eventFormSaveChangesButton;

  /// No description provided for @eventFormDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get eventFormDeleteTitle;

  /// No description provided for @eventFormDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be removed.'**
  String eventFormDeleteBody(Object title);

  /// No description provided for @listsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search lists…'**
  String get listsSearchHint;

  /// No description provided for @newList.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get newList;

  /// No description provided for @noListsMatch.
  ///
  /// In en, this message translates to:
  /// **'No lists match your search'**
  String get noListsMatch;

  /// No description provided for @itemsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, one{item} other{items}} left'**
  String itemsLeft(num count);

  /// No description provided for @itemsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} completed'**
  String itemsCompleted(Object done, Object total);

  /// No description provided for @tasksSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks…'**
  String get tasksSearchHint;

  /// No description provided for @noTasksMatch.
  ///
  /// In en, this message translates to:
  /// **'No tasks match'**
  String get noTasksMatch;

  /// No description provided for @calendarSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search events…'**
  String get calendarSearchHint;

  /// No description provided for @noEventsMatch.
  ///
  /// In en, this message translates to:
  /// **'No events match'**
  String get noEventsMatch;

  /// No description provided for @noEventsThisDay.
  ///
  /// In en, this message translates to:
  /// **'No events this day'**
  String get noEventsThisDay;

  /// No description provided for @taskFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get taskFormNewTitle;

  /// No description provided for @taskFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskFormEditTitle;

  /// No description provided for @taskFormQuestion.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get taskFormQuestion;

  /// No description provided for @taskFormTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Buy groceries'**
  String get taskFormTitleHint;

  /// No description provided for @taskFormAssignTo.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get taskFormAssignTo;

  /// No description provided for @taskFormTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get taskFormTimeLabel;

  /// No description provided for @taskFormNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get taskFormNotesLabel;

  /// No description provided for @taskFormNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note…'**
  String get taskFormNoteHint;

  /// No description provided for @taskFormReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get taskFormReminder;

  /// No description provided for @taskFormChecklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get taskFormChecklist;

  /// No description provided for @taskFormAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get taskFormAttachment;

  /// No description provided for @taskFormSubtask.
  ///
  /// In en, this message translates to:
  /// **'Subtask'**
  String get taskFormSubtask;

  /// No description provided for @taskFormComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} is coming soon'**
  String taskFormComingSoon(Object feature);

  /// No description provided for @taskFormCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get taskFormCreateButton;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @tasksEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add something the family needs to do.'**
  String get tasksEmptyHint;

  /// No description provided for @sectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get sectionNotes;

  /// No description provided for @notesSortByDate.
  ///
  /// In en, this message translates to:
  /// **'Sort by date'**
  String get notesSortByDate;

  /// No description provided for @notesSortByColor.
  ///
  /// In en, this message translates to:
  /// **'Sort by color'**
  String get notesSortByColor;

  /// No description provided for @notesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No notes yet — tap + and choose Note to add one.'**
  String get notesEmptyHint;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Write a note…'**
  String get noteHint;

  /// No description provided for @quickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to add?'**
  String get quickAddTitle;

  /// No description provided for @quickAddTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get quickAddTask;

  /// No description provided for @quickAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get quickAddEvent;

  /// No description provided for @quickAddShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get quickAddShopping;

  /// No description provided for @quickAddNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get quickAddNote;

  /// No description provided for @quickAddTaskMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get quickAddTaskMoreOptions;

  /// No description provided for @quickAddTaskAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get quickAddTaskAdd;

  /// No description provided for @quickAddTaskVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input isn\'t available on this device'**
  String get quickAddTaskVoiceUnavailable;

  /// No description provided for @quickAddTaskDateShort.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get quickAddTaskDateShort;

  /// No description provided for @quickAddTaskAssignShort.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get quickAddTaskAssignShort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
