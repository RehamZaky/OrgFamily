// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'OrgFamily';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navTasks => 'المهام';

  @override
  String get navCalendar => 'التقويم';

  @override
  String get navLists => 'القوائم';

  @override
  String get navFamily => 'العائلة';

  @override
  String get drawerProfile => 'الملف الشخصي';

  @override
  String get drawerSettings => 'الإعدادات';

  @override
  String get drawerAbout => 'حول التطبيق';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingAfternoon => 'طاب نهارك';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String greetingWithName(Object greeting, Object name) {
    return '$greeting، $name 👋';
  }

  @override
  String get greetingFallbackName => 'صديقي';

  @override
  String get statTasksToday => 'مهام اليوم';

  @override
  String get statEvent => 'حدث';

  @override
  String get statEvents => 'أحداث';

  @override
  String get statList => 'قائمة';

  @override
  String get statLists => 'قوائم';

  @override
  String get sectionTodaysPriorities => 'اليوم';

  @override
  String get sectionUpcomingEvents => 'القادمة';

  @override
  String get sectionFamilyActivity => 'نشاط العائلة';

  @override
  String get sectionShopping => 'التسوق';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get emptyNothingDueToday => 'لا شيء مستحق اليوم 🎉';

  @override
  String get emptyNoTasksYet => 'لا توجد مهام بعد';

  @override
  String get emptyNoTasksHint =>
      'جرّب: شراء البقالة، دفع فاتورة الكهرباء، تنظيف المطبخ';

  @override
  String get emptyNoUpcomingEvents => 'لا توجد أحداث قادمة';

  @override
  String get emptyNoEventsYet => 'لا توجد أحداث بعد';

  @override
  String get emptyNoEventsHint => 'جرّب: عشاء عائلي، اجتماع مدرسي';

  @override
  String get emptyNoListsYet => 'لا توجد قوائم بعد';

  @override
  String get emptyNoListsHint => 'جرّب: قائمة تسوق، قائمة سفر';

  @override
  String get emptyNoItemsYet => 'لا توجد عناصر بعد';

  @override
  String get emptyNoItemsHint => 'جرّب: حليب، بيض، خبز';

  @override
  String get emptyAllDone => 'تم إنجاز الكل ✓';

  @override
  String get emptyNoActivityYet => 'لا يوجد نشاط بعد';

  @override
  String get actionAddEvent => 'إضافة حدث';

  @override
  String get actionAddItem => 'إضافة عنصر';

  @override
  String get taskStatusDone => 'تم';

  @override
  String itemsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصرًا',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا عناصر',
    );
    return '$_temp0';
  }

  @override
  String activityCompleted(Object title) {
    return 'أكمل \"$title\"';
  }

  @override
  String activityAdded(Object item, Object list) {
    return 'أضاف \"$item\" إلى $list';
  }

  @override
  String get activitySomeone => 'شخص ما';

  @override
  String get today => 'اليوم';

  @override
  String get tomorrow => 'غدًا';

  @override
  String get later => 'لاحقًا';

  @override
  String get tasksTabAll => 'الكل';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingAddYourself => 'أضف نفسك';

  @override
  String get onboardingComingSoon => 'قريبًا';

  @override
  String get onboardingPage1Title => 'حافظ على تنظيم عائلتك';

  @override
  String get onboardingPage1Body =>
      'أدر المهام والأحداث والقوائم وغير ذلك — كل ذلك في مكان واحد.';

  @override
  String get onboardingFeatureTasks => 'المهام';

  @override
  String get onboardingFeatureEvents => 'الأحداث';

  @override
  String get onboardingFeatureLists => 'القوائم';

  @override
  String get onboardingFeatureProgress => 'التقدّم';

  @override
  String get onboardingPage2Title => 'شارك وابقَ على تواصل';

  @override
  String get onboardingPage2Body =>
      'وزّع المهام، خططوا معًا، وابقوا جميعًا على تناغم.';

  @override
  String get onboardingFeedTaskAdded => 'أضاف مهمة جديدة';

  @override
  String get onboardingFeedListUpdated => 'حدّثت قائمة البقالة';

  @override
  String get onboardingFeedTaskCompleted => 'أكملت مهمتها!';

  @override
  String get onboardingFeedEventAdded => 'أضاف حدثًا';

  @override
  String get onboardingPage3Title => 'أدِر الأموال معًا';

  @override
  String get onboardingPage3Body =>
      'تتبّع المصروفات، وخطط للميزانيات، وحقق أهداف عائلتك.';

  @override
  String get onboardingBudgetGroceries => 'البقالة';

  @override
  String get onboardingBudgetHousehold => 'المنزل';

  @override
  String get onboardingBudgetDining => 'المطاعم';

  @override
  String get onboardingBudgetTransport => 'المواصلات';

  @override
  String get onboardingPage4Title => 'ابنِ غدًا أكثر سعادة';

  @override
  String get onboardingPage4Body => 'خطوات صغيرة اليوم تصنع فرقًا كبيرًا.';

  @override
  String get onboardingChecklistQualityTime => 'وقت أطول معًا';

  @override
  String get onboardingChecklistLessStress => 'توتر أقل';

  @override
  String get onboardingChecklistGetThingsDone => 'إنجاز المهام';

  @override
  String get onboardingChecklistHappierFamily => 'عائلة أكثر سعادة';

  @override
  String get onboardingPage5Title => 'لنُعِدّ عائلتك';

  @override
  String get onboardingPage5Body =>
      'أضف نفسك أولًا — يمكنك إضافة بقية أفراد العائلة بعد ذلك مباشرة.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get settingsThemeLight => 'فاتح';

  @override
  String get settingsThemeDark => 'داكن';

  @override
  String get settingsThemeSystem => 'النظام';

  @override
  String get settingsThemeSystemHint =>
      'يتبع وضع \"النظام\" إعداد المظهر في جهازك.';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageSystem => 'النظام';

  @override
  String get aboutTitle => 'حول التطبيق';

  @override
  String get aboutAppName => 'OrgFamily';

  @override
  String get aboutVersion => 'الإصدار 1.0.0 · النسخة التجريبية الأولى';

  @override
  String get aboutDescription =>
      'منظّم عائلي مشترك: المهام والتقويم وقوائم التسوق التي يراها كل أفراد العائلة ويحدّثونها معًا.';

  @override
  String get aboutBuiltWith => 'بُني باستخدام';

  @override
  String get aboutTechStack =>
      'Flutter وRiverpod وDrift (قاعدة بيانات SQLite محلية).';

  @override
  String get aboutLocalNote =>
      'هذه نسخة أولى تعمل محليًا فقط — تبقى بيانات عائلتك على هذا الجهاز. المزامنة السحابية بين الأجهزة مخطط لها في نسخة لاحقة.';

  @override
  String get taskPriorityLow => 'منخفضة';

  @override
  String get taskPriorityNormal => 'عادية';

  @override
  String get taskPriorityHigh => 'مرتفعة';

  @override
  String get taskPriorityUrgent => 'عاجلة';

  @override
  String get taskCategoryHome => 'المنزل';

  @override
  String get taskCategoryShopping => 'التسوق';

  @override
  String get taskCategoryFinance => 'المالية';

  @override
  String get taskCategorySchool => 'المدرسة';

  @override
  String get taskCategoryCar => 'السيارة';

  @override
  String get taskCategoryChores => 'الأعمال المنزلية';

  @override
  String get taskCategoryFamily => 'العائلة';

  @override
  String get taskCategoryEvents => 'المناسبات';

  @override
  String get taskCategoryAppointments => 'المواعيد';

  @override
  String get taskCategoryErrands => 'المشاوير';

  @override
  String get taskCategoryWork => 'العمل';

  @override
  String get taskCategoryOther => 'أخرى';

  @override
  String get taskRecurrenceNone => 'لا يتكرر';

  @override
  String get taskRecurrenceDaily => 'يوميًا';

  @override
  String get taskRecurrenceWeekly => 'أسبوعيًا';

  @override
  String get taskRecurrenceMonthly => 'شهريًا';

  @override
  String get eventCategoryBirthday => 'عيد ميلاد';

  @override
  String get eventCategorySchool => 'المدرسة';

  @override
  String get eventCategoryAppointment => 'موعد';

  @override
  String get eventCategoryWork => 'العمل';

  @override
  String get eventCategoryTravel => 'سفر';

  @override
  String get eventCategoryHome => 'المنزل';

  @override
  String get eventCategoryFamily => 'العائلة';

  @override
  String get eventCategoryOther => 'أخرى';

  @override
  String get labelTitle => 'العنوان';

  @override
  String get labelCategory => 'الفئة';

  @override
  String get labelPriority => 'الأولوية';

  @override
  String get labelDueDate => 'تاريخ الاستحقاق';

  @override
  String get labelRepeat => 'التكرار';

  @override
  String get labelAssignedTo => 'مسندة إلى';

  @override
  String get labelWho => 'من';

  @override
  String get labelDateTime => 'التاريخ والوقت';

  @override
  String get labelNotes => 'ملاحظات';

  @override
  String get unassigned => 'غير مسندة';

  @override
  String get everyone => 'الجميع';

  @override
  String get allCategories => 'كل الفئات';

  @override
  String get clearFilters => 'مسح عوامل التصفية';

  @override
  String get notSet => 'غير محدد';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get filter => 'تصفية';

  @override
  String get search => 'بحث';

  @override
  String get closeSearch => 'إغلاق البحث';

  @override
  String get addItemScreenTitle => 'إضافة عنصر';

  @override
  String get addItemNameLabel => 'اسم العنصر';

  @override
  String get addItemNameHint => 'أدخل اسم العنصر';

  @override
  String get addItemAddToListLabel => 'الإضافة إلى قائمة';

  @override
  String get addItemNewListValue => 'قائمة \"تسوق\" جديدة';

  @override
  String get addItemButtonLabel => 'إضافة العنصر';

  @override
  String get taskDetailsScreenTitle => 'تفاصيل المهمة';

  @override
  String get taskDetailsNotesHint => 'اكتب ملاحظة أو وصفًا أطول…';

  @override
  String get taskDetailsNotesSaved => 'تم حفظ الملاحظات';

  @override
  String get eventFormNewTitle => 'حدث جديد';

  @override
  String get eventFormEditTitle => 'تعديل الحدث';

  @override
  String get eventFormSubtitleNew => 'أضف تفاصيل حدثك';

  @override
  String get eventFormSubtitleEdit => 'حدّث تفاصيل حدثك';

  @override
  String get eventFormTitleHint => 'عنوان الحدث';

  @override
  String get eventFormLocationLabel => 'الموقع (اختياري)';

  @override
  String get eventFormLocationHint => 'أضف الموقع';

  @override
  String get eventFormWhoHint => 'أضف الأشخاص المشاركين في هذا الحدث.';

  @override
  String get eventFormSaveButton => 'حفظ الحدث';

  @override
  String get eventFormSaveChangesButton => 'حفظ التغييرات';

  @override
  String get eventFormDeleteTitle => 'حذف الحدث؟';

  @override
  String eventFormDeleteBody(Object title) {
    return 'سيتم إزالة \"$title\".';
  }

  @override
  String get listsSearchHint => 'ابحث في القوائم…';

  @override
  String get newList => 'قائمة جديدة';

  @override
  String get noListsMatch => 'لا توجد قوائم مطابقة لبحثك';

  @override
  String itemsLeft(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر متبقٍ',
      many: '$count عنصرًا متبقيًا',
      few: '$count عناصر متبقية',
      two: 'عنصران متبقيان',
      one: 'عنصر واحد متبقٍ',
    );
    return '$_temp0';
  }

  @override
  String itemsCompleted(Object done, Object total) {
    return '$done من $total مكتمل';
  }

  @override
  String get tasksSearchHint => 'ابحث في المهام…';

  @override
  String get noTasksMatch => 'لا توجد مهام مطابقة';

  @override
  String get calendarSearchHint => 'ابحث في الأحداث…';

  @override
  String get noEventsMatch => 'لا توجد أحداث مطابقة';

  @override
  String get noEventsThisDay => 'لا توجد أحداث في هذا اليوم';

  @override
  String get taskFormNewTitle => 'مهمة جديدة';

  @override
  String get taskFormEditTitle => 'تعديل المهمة';

  @override
  String get taskFormQuestion => 'ما الذي يجب القيام به؟';

  @override
  String get taskFormTitleHint => 'مثال: شراء البقالة';

  @override
  String get taskFormAssignTo => 'إسناد إلى';

  @override
  String get taskFormTimeLabel => 'الوقت';

  @override
  String get taskFormNotesLabel => 'ملاحظات (اختياري)';

  @override
  String get taskFormNoteHint => 'أضف ملاحظة…';

  @override
  String get taskFormReminder => 'تذكير';

  @override
  String get taskFormChecklist => 'قائمة تحقق';

  @override
  String get taskFormAttachment => 'مرفق';

  @override
  String get taskFormSubtask => 'مهمة فرعية';

  @override
  String taskFormComingSoon(Object feature) {
    return 'ميزة $feature قادمة قريبًا';
  }

  @override
  String get taskFormCreateButton => 'إنشاء المهمة';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get completed => 'مكتملة';

  @override
  String get tasksEmptyHint => 'اضغط + لإضافة شيء تحتاجه العائلة.';

  @override
  String get sectionNotes => 'الملاحظات';

  @override
  String get notesSortByDate => 'الترتيب حسب التاريخ';

  @override
  String get notesSortByColor => 'الترتيب حسب اللون';

  @override
  String get notesEmptyHint =>
      'لا توجد ملاحظات بعد — اضغط + واختر \"ملاحظة\" لإضافة واحدة.';

  @override
  String get noteHint => 'اكتب ملاحظة…';

  @override
  String get quickAddTitle => 'ماذا تريد أن تضيف؟';

  @override
  String get quickAddTask => 'مهمة';

  @override
  String get quickAddEvent => 'حدث';

  @override
  String get quickAddShopping => 'تسوق';

  @override
  String get quickAddNote => 'ملاحظة';

  @override
  String get quickAddTaskMoreOptions => 'خيارات إضافية';

  @override
  String get quickAddTaskAdd => 'إضافة مهمة';

  @override
  String get quickAddTaskVoiceUnavailable =>
      'الإدخال الصوتي غير متاح على هذا الجهاز';

  @override
  String get quickAddTaskDateShort => 'التاريخ';

  @override
  String get quickAddTaskAssignShort => 'إسناد';
}
