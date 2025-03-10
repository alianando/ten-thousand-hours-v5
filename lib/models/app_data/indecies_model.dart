import '../time_data/model/time_point/time_point.dart';

class Indices {
  final int today;
  final List<int> weekIndices;
  final List<int> monthIndices;

  const Indices({
    this.today = -1,
    this.weekIndices = const [],
    this.monthIndices = const [],
  });

  List<int> get unactiveDays => List<int>.from(monthIndices)
    ..removeWhere(
      (element) => element == today,
    );

  List<int> get allSessionIndices => monthIndices;

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
              this.weekIndices), // Create new list from existing value
      monthIndices: monthIndices != null
          ? List<int>.from(monthIndices) // Create new list from provided value
          : List<int>.from(
              this.monthIndices), // Create new list from existing value
    );
  }

  @override
  String toString() {
    return 'Indices(today: $today, weekIndices: $weekIndices, monthIndices: $monthIndices)';
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
    final today = DtHelper.dayStartDt(now);
    // final startOfMonth = DateTime(now.year, now.month, 1);

    // Calculate week boundaries once
    final startOfWeekDay = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DtHelper.dayStartDt(startOfWeekDay);
    final endOfWeek = DtHelper.dayEndDt(
      now.add(Duration(days: DateTime.daysPerWeek - now.weekday)),
    );

    int todayIndex = -1;
    final weekIndices = <int>[];
    final monthIndices = <int>[];

    // Single-pass iteration through dates
    for (int i = 0; i < dayDates.length; i++) {
      final day = dayDates[i];

      // Check month (only need to compare against start of month)
      // final insideMonth = day.isAtSameMomentAs(startOfMonth) ||
      //     (day.isAfter(startOfMonth) &&
      //         day.year == now.year &&
      //         day.month == now.month);
      if (day.year == now.year && day.month == now.month) {
        monthIndices.add(i);
      }

      // Check week
      if (!day.isBefore(startOfWeek) && day.isBefore(endOfWeek)) {
        weekIndices.add(i);
      }

      // Check today
      if (DtHelper.dayStartDt(day) == today) {
        todayIndex = i;
      }
    }

    return Indices(
      today: todayIndex,
      weekIndices: weekIndices,
      monthIndices: monthIndices,
    );
  }

  // static List<int> getWeekIndices({
  //   required List<DateTime> dates,
  // }) {
  //   if (dates.isEmpty) {
  //     return [];
  //   }

  //   final now = DateTime.now();
  //   final weekIndices = <int>[];
  //   final startOfWeek = now.subtract(
  //     Duration(days: now.weekday - 1),
  //   );
  //   final endOfWeek = now.add(
  //     Duration(days: DateTime.daysPerWeek - now.weekday),
  //   );

  //   for (int i = 0; i < dates.length; i++) {
  //     final day = dates[i];
  //     if (day.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
  //         day.isBefore(endOfWeek.add(const Duration(days: 1)))) {
  //       weekIndices.add(i);
  //     }
  //   }

  //   return weekIndices;
  // }
}
