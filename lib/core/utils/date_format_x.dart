import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// How times are shown app-wide: 12/24-hour and the language's numerals.
/// Kept current by `OrgFamilyApp` (from the time-format setting and the
/// app language) so context-free helpers like [DateFormatX.timeLabel]
/// format the same way as [formatTime].
abstract final class TimeFormatting {
  static bool use24Hour = false;
  static String? locale;

  static DateFormat get _format =>
      use24Hour ? DateFormat.Hm(locale) : DateFormat.jm(locale);

  static String format(DateTime dt) => _format.format(dt);
}

/// A time of day in the app's time format — "3:30 PM" / "15:30", or
/// "٣:٣٠ م" / "١٥:٣٠" in Arabic. Reads the 24-hour choice from [context]
/// (set from the time-format setting in `OrgFamilyApp`).
String formatTime(BuildContext context, DateTime dt) {
  final locale = Localizations.maybeLocaleOf(context)?.toString() ?? TimeFormatting.locale;
  final use24 = MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? TimeFormatting.use24Hour;
  return (use24 ? DateFormat.Hm(locale) : DateFormat.jm(locale)).format(dt.toLocal());
}

extension DateFormatX on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  String get relativeDay {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    return DateFormat('EEEE').format(this);
  }

  String get timeLabel => TimeFormatting.format(this);

  String get shortDate => DateFormat('MMM d').format(this);

  String get fullDate => DateFormat('EEEE, MMMM d').format(this);

  String get relativeDayAndTime => '$relativeDay • $timeLabel';

  /// Age in whole years as of today, treating this DateTime as a birthdate.
  int get ageInYears {
    final now = DateTime.now();
    var age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) age--;
    return age;
  }

  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return shortDate;
  }
}

/// Formats a task's `dueTimeMinutes` (minutes since midnight) the same way
/// [DateFormatX.timeLabel] formats a full [DateTime].
extension MinutesSinceMidnightX on int {
  String get timeOfDayLabel =>
      TimeFormatting.format(DateTime(2000, 1, 1, this ~/ 60, this % 60));
}
