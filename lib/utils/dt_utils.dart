import 'dart:math';

class DtUtils {
  const DtUtils._();

  static String dtToHM(DateTime dt) {
    int hour = dt.hour;
    String h = hour.toString();
    if (hour < 10) {
      h = '0$h';
    }
    int minute = dt.minute;
    String m = minute.toString();
    if (minute < 10) {
      m = '0$m';
    }
    return '$h:$m';
  }

  static String durToLabel(Duration dur) {
    String hms = '';
    int h = dur.inHours;
    // if (h < 10) {
    //   hms = '${hms}0$h';
    // } else {
    //   hms = '$hms$h';
    // }
    hms = '$hms${h}h';
    int m = (dur - Duration(hours: h)).inMinutes;
    if (m < 10) {
      hms = '$hms.0${m}m';
    } else {
      hms = '$hms.${m}m';
    }
    // int s = (dur - Duration(hours: h, minutes: m)).inSeconds;
    // if (s < 10) {
    //   hms = '$hms.0$s';
    // } else {
    //   hms = '$hms.$s';
    // }
    return hms;
  }

  static String durToHM(Duration dur) {
    String hms = '';
    int h = dur.inHours;
    if (h < 10) {
      hms = '${hms}0$h';
    } else {
      hms = '$hms$h';
    }
    int m = (dur - Duration(hours: h)).inMinutes;
    if (m < 10) {
      hms = '$hms.0$m';
    } else {
      hms = '$hms.$m';
    }
    // int s = (dur - Duration(hours: h, minutes: m)).inSeconds;
    // if (s < 10) {
    //   hms = '$hms.0$s';
    // } else {
    //   hms = '$hms.$s';
    // }
    return hms;
  }

  static String durToHMS(Duration dur) {
    String hms = '';
    int h = dur.inHours;
    if (h < 10) {
      hms = '${hms}0${h}h';
    } else {
      hms = '$hms${h}h';
    }
    int m = (dur - Duration(hours: h)).inMinutes;
    if (m < 10) {
      hms = '$hms.0${m}m';
    } else {
      hms = '$hms.${m}m';
    }
    int s = (dur - Duration(hours: h, minutes: m)).inSeconds;
    if (s < 10) {
      hms = '$hms.0${s}s';
    } else {
      hms = '$hms.${s}s';
    }
    return hms;
  }

  static DateTime generateRandomDt() {
    const int year = 2024;
    final random = Random();
    final month = random.nextInt(12) + 1;
    final numberOfDays = getDaysInMonth(year, month);
    final day = random.nextInt(numberOfDays) + 1;
    final hour = random.nextInt(24) + 1;
    final minute = random.nextInt(60) + 1;
    final sec = random.nextInt(60) + 1;
    return DateTime(year, month, day, hour, minute, sec);
  }

  static int getDaysInMonth(int year, int month) {
    // Create a DateTime object for the first day of the next month
    final nextMonthFirstDay = DateTime(year, month + 1, 1);

    // Subtract one day to get the last day of the current month
    final lastDayOfMonth = nextMonthFirstDay.subtract(const Duration(days: 1));

    // Return the day of the last day of the month
    return lastDayOfMonth.day;
  }

  static bool sameDay(DateTime dt1, DateTime dt2) {
    bool dayMatch = dt1.day == dt2.day;
    if (!dayMatch) return false;
    bool monthMatch = dt1.month == dt2.month;
    if (!monthMatch) return false;
    bool yrMatch = dt1.year == dt2.year;
    if (!yrMatch) return false;
    return true;
  }

  static DateTime getDayStartdt(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, 0, 0, 0, 0, 0);
  }

  static DateTime getDayEnddt(DateTime dt) {
    return DateTime(
      dt.year,
      dt.month,
      dt.day,
      23,
      59,
      59,
      59,
      59,
    );
  }

  static DateTime getSessionStartTime({
    required DateTime refDt,
    required Duration viewWidth,
  }) {
    if (viewWidth == const Duration(hours: 1)) {
      return DateTime(
        refDt.year,
        refDt.month,
        refDt.day,
        refDt.hour,
        0,
        0,
        0,
      );
    }
    if (viewWidth == const Duration(hours: 12)) {
      int hour = 0;

      if (refDt.hour >= 12) {
        hour = 12;
      }
      return DateTime(
        refDt.year,
        refDt.month,
        refDt.day,
        hour,
        0,
        0,
        0,
      );
    }
    if (viewWidth == const Duration(days: 1)) {
      return DateTime(refDt.year, refDt.month, refDt.day, 0, 0, 0, 0);
    }
    if (viewWidth == const Duration(minutes: 1)) {
      return DateTime(
        refDt.year,
        refDt.month,
        refDt.day,
        refDt.hour,
        refDt.minute,
        0,
        0,
      );
    }
    return refDt;
  }

  static DateTime getRefDt({
    required DateTime nowDt,
    required DateTime targetDayDt,
    required bool today,
  }) {
    if (today) {
      return nowDt;
    }
    return DateTime(
      targetDayDt.year,
      targetDayDt.month,
      targetDayDt.day,
      nowDt.hour,
      nowDt.minute,
      nowDt.second,
    );
  }

  static String dtToHMS(DateTime dt) {
    int hour = dt.hour;
    String identifier = 'am';
    if (hour > 12) {
      hour = hour - 12;
      identifier = 'pm';
    }
    String hString = '$hour';
    if (hour < 10) {
      hString = '0$hour';
    }
    String mString = dt.minute.toString();
    if (dt.minute < 10) {
      mString = '0$mString';
    }
    String sString = dt.second.toString();
    if (dt.second < 10) {
      sString = '0$sString';
    }
    return '$hString:$mString:$sString $identifier';
  }

  static String dateString(DateTime dt) {
    String month = 'Jan';
    switch (dt.month) {
      case 2:
        month = 'Feb';
        break;
      case 3:
        month = 'Mar';
        break;
      case 4:
        month = 'Apr';
        break;
      case 5:
        month = 'May';
        break;
      case 6:
        month = 'Jun';
        break;
      case 7:
        month = 'Jul';
        break;
      case 8:
        month = 'Aug';
        break;
      case 9:
        month = 'Sep';
        break;
      case 10:
        month = 'Oct';
        break;
      case 11:
        month = 'Nov';
        break;
      default:
        month = 'Dec';
        break;
    }
    return '$month ${dt.day}, ${dt.year}';
  }

  static String dateToDM(DateTime dt) {
    int day = dt.day;
    String d = day.toString();
    if (day < 10) {
      d = '0$d';
    }
    int month = dt.month;
    String m = month.toString();
    if (month < 10) {
      m = '0$m';
    }
    return '$d / $m';
  }

  static DateTime combineDateAndTime({
    required DateTime date,
    required DateTime time,
  }) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      time.second,
      time.millisecond,
      time.microsecond,
    );
  }
}
