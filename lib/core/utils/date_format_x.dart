import 'package:intl/intl.dart';

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

  String get relativeDay {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    return DateFormat('EEEE').format(this);
  }

  String get timeLabel => DateFormat('h:mm a').format(this);

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
