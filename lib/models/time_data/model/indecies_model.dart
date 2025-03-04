import 'time_point.dart';

class Indices {
  final int today;
  final List<int> weekIndices;
  final List<int> monthIndices;

  const Indices({
    this.today = 0,
    this.weekIndices = const [0],
    this.monthIndices = const [0],
  });

  Map<String, dynamic> toJson() {
    return {
      'today': today,
      'weekIndices': weekIndices,
      'monthIndices': monthIndices,
    };
  }

  factory Indices.fromJson(Map<String, dynamic> json) {
    return Indices(
      today: json['today'],
      weekIndices: List<int>.from(json['weekIndices']),
      monthIndices: List<int>.from(json['monthIndices']),
    );
  }

  Indices copyWith({
    int? today,
    List<int>? weekIndices,
    List<int>? monthIndices,
  }) {
    return Indices(
      today: today ?? this.today,
      weekIndices: weekIndices != null
          ? List<int>.from(weekIndices) // Create new list from provided value
          : List<int>.from(
              this.weekIndices,
            ), // Create new list from existing value
      monthIndices: monthIndices != null
          ? List<int>.from(monthIndices) // Create new list from provided value
          : List<int>.from(
              this.monthIndices,
            ), // Create new list from existing value
    );
  }
}

class IndicesServices {
  const IndicesServices._();

  static Indices updateIndices({
    required List<DateTime> dayDates,
  }) {
    if (dayDates.isEmpty) {
      return const Indices();
    }
    final now = DateTime.now();
    int todayIndex = -1;
    final weekIndices = <int>[];
    final monthIndices = <int>[];
    final startOfWeekDay = now.subtract(
      Duration(days: now.weekday - 1),
    );
    final weekEndDay = now.add(
      Duration(days: DateTime.daysPerWeek - now.weekday),
    );
    final startOfWeek = DtHelper.dayStartDt(startOfWeekDay);
    final endOfWeek = DtHelper.dayEndDt(weekEndDay);

    for (int i = 0; i < dayDates.length; i++) {
      final day = dayDates[i];
      if (day.year == now.year && day.month == now.month) {
        monthIndices.add(i);
      }
      if (day.isBefore(startOfWeek)) {
        continue;
      }
      if (day.isBefore(endOfWeek)) {
        weekIndices.add(i);
      }
      if (DtHelper.dayStartDt(day) == DtHelper.dayStartDt(now)) {
        todayIndex = i;
      }
    }

    return Indices(
      today: todayIndex,
      weekIndices: weekIndices,
      monthIndices: monthIndices,
    );
  }

  static List<int> getWeekIndices({
    required List<DateTime> dates,
  }) {
    if (dates.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    final weekIndices = <int>[];
    final startOfWeek = now.subtract(
      Duration(days: now.weekday - 1),
    );
    final endOfWeek = now.add(
      Duration(days: DateTime.daysPerWeek - now.weekday),
    );

    for (int i = 0; i < dates.length; i++) {
      final day = dates[i];
      if (day.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          day.isBefore(endOfWeek.add(const Duration(days: 1)))) {
        weekIndices.add(i);
      }
    }

    return weekIndices;
  }
}
