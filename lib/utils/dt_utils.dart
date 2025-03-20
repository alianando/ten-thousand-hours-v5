class DtHelper {
  const DtHelper._();

  static bool sameHourMinute(DateTime dt1, DateTime dt2) {
    return dt1.hour == dt2.hour && dt1.minute == dt2.minute;
  }

  static bool isDayStartDt(DateTime dt) {
    final bool not = dt.hour != 0 || dt.minute != 0 || dt.second != 0;
    return !not;
  }

  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  static DateTime dayStartDt(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime dayEndDt(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 999);
  }

  static DateTime correctDt(DateTime dt, DateTime refDate) {
    return DateTime(
      refDate.year,
      refDate.month,
      refDate.day,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond,
      dt.microsecond,
    );
  }

  /// Returns the week number (1-53) for a given date
  static int getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Returns the first day of the week containing the given date
  /// (Monday is considered the first day of the week)
  static DateTime getFirstDayOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysToSubtract);
  }

  /// Returns the last day of the week containing the given date
  /// (Sunday is considered the last day of the week)
  static DateTime getLastDayOfWeek(DateTime date) {
    final daysToAdd = 7 - date.weekday;
    return DateTime(date.year, date.month, date.day + daysToAdd);
  }

  /// Returns the first day of the month containing the given date
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Returns the last day of the month containing the given date
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Returns a human-readable string describing the time difference
  /// e.g. "2 days ago", "3 hours ago", "just now"
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  /// Formats date as a string in the format "Mon, 5 Mar"
  static String formatDateShort(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dayOfWeek = days[date.weekday - 1];
    final month = months[date.month - 1];
    return '$dayOfWeek, ${date.day} $month';
  }
}

/// Add this at the top of the file, above your classes
class TimeConstants {
  static const Duration minSessionTime = Duration(minutes: 1);
  static const Duration defaultSessionTime = Duration(hours: 1);
  static const Duration maxDefaultSessionTime = Duration(hours: 8);

  static const int defaultStartHour = 9;
  static const int defaultEndHour = 17;

  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  static const String dbDateTimeFormat = 'yyyy-MM-ddTHH:mm:ss.SSS';
}

/// Utility for time format conversions
class TimeFormatter {
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  static String formatDurationCompact(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    } else {
      return '0:${minutes.toString().padLeft(2, '0')}';
    }
  }

  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
