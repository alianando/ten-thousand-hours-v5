import 'package:ten_thousands_hours/models/time_data/day_entry/day_model.dart';
import 'package:ten_thousands_hours/models/time_data/time_point/time_point.dart';
import 'package:ten_thousands_hours/root/root.dart';

class StatData {
  final Duration maxDurReleventDays;
  final Duration minDurReleventDays;
  final Duration totalDur;
  final Duration todayDur;

  const StatData({
    this.maxDurReleventDays = Duration.zero,
    this.minDurReleventDays = Duration.zero,
    this.totalDur = Duration.zero,
    this.todayDur = Duration.zero,
  });

  Map<String, dynamic> toJson() {
    return {
      'maxDurReleventDays': maxDurReleventDays.inMilliseconds,
      'minDurReleventDays': minDurReleventDays.inMilliseconds,
      'totalDur': totalDur.inMilliseconds,
      'todayDur': todayDur.inMilliseconds, // Add to serialization
    };
  }

  factory StatData.fromJson(Map<String, dynamic> json) {
    return StatData(
      maxDurReleventDays: Duration(milliseconds: json['maxDurReleventDays']),
      minDurReleventDays: Duration(milliseconds: json['minDurReleventDays']),
      totalDur: Duration(milliseconds: json['totalDur']),
      todayDur: json['todayDur'] != null
          ? Duration(milliseconds: json['todayDur'])
          : Duration.zero, // Add deserialization with fallback
    );
  }

  StatData copyWith({
    Duration? maxDurReleventDays,
    Duration? minDurReleventDays,
    Duration? totalDur,
    Duration? todayDur, // Add to copyWith method
  }) {
    return StatData(
      maxDurReleventDays: maxDurReleventDays ?? this.maxDurReleventDays,
      minDurReleventDays: minDurReleventDays ?? this.minDurReleventDays,
      totalDur: totalDur ?? this.totalDur,
      todayDur: todayDur ?? this.todayDur, // Include in new instance
    );
  }
}

class StatServices {
  const StatServices._();

  static const Duration _maxDur = Duration(hours: 10);

  /// Creates default stat data
  static StatData createDefaultStat() {
    return const StatData(
      maxDurReleventDays: _maxDur,
      minDurReleventDays: Duration.zero,
      totalDur: Duration.zero,
      todayDur: Duration.zero, // Initialize today's duration
    );
  }

  static StatData refreshTodayDuration({
    required StatData oldStats,
    required DayEntry today,
  }) {
    return oldStats.copyWith(
      todayDur: today.durPoint.dur,
      totalDur: oldStats.totalDur + today.durPoint.dur - oldStats.todayDur,
    );
  }

  static StatData handelSessionChange({
    required StatData oldStat,
    required DateTime sessionStartDt,
    required DateTime sessionEndDt,
    required List<DayEntry> days,
    required int todayIndex,
    required List<int> allSessionIndecies,
  }) {
    Duration newSessionMaxDur = Duration.zero;
    Duration newSessionMinDur = Duration.zero;
    Duration newTotalDur = oldStat.totalDur;
    Duration newTodayDur = oldStat.todayDur;
    for (int i = 0; i < allSessionIndecies.length; i++) {
      final day = days[allSessionIndecies[i]];
      final sessionStartDuration = TPService.calculateDuration(
        sessionEndDt,
        day.events,
      );
      final sessionEndDuration = _getSessionEndDur(
        events: day.events,
        sessionEndDt: sessionEndDt,
        today: allSessionIndecies[i] == todayIndex,
      );
      newSessionMaxDur = _checkSessionMaxDur(
        current: oldStat.maxDurReleventDays,
        potential: sessionEndDuration,
      );
      newSessionMinDur = _checkSessionMinDur(
        current: oldStat.minDurReleventDays,
        potential: sessionStartDuration,
      );
      if (allSessionIndecies[i] == todayIndex) {
        final durIncreased = day.durPoint.dur - oldStat.todayDur;
        newTotalDur += durIncreased;
        newTotalDur += durIncreased;
      }
    }
    return oldStat.copyWith(
      maxDurReleventDays: newSessionMaxDur,
      minDurReleventDays: newSessionMinDur,
      totalDur: newTotalDur,
      todayDur: newTodayDur,
    );
  }

  static StatData calculateStatistics({
    required List<DayEntry> days,
    required DateTime sessionStartDt,
    required DateTime sessionEndDt,
    required int todayIndex,
    required List<int> allSessionIndices,
    bool debug = false,
  }) {
    pout('calculateStatistics <- StatServices class', debug);
    pout(' days', debug);
    pout('    length ${days.length}', debug);
    pout(' sessionStartDt $sessionStartDt', debug);
    pout(' sessionEndDt $sessionEndDt', debug);
    pout(' todayIndex $todayIndex', debug);
    pout(' sessionIndecies $allSessionIndices', debug);

    Duration maxSessionDur = Duration.zero;
    Duration minSessionDur = Duration.zero;
    Duration totalDur = Duration.zero;
    Duration todayDur = Duration.zero;
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final currentDuration = day.durPoint.dur;
      totalDur += currentDuration;
      if (allSessionIndices.contains(i)) {
        final sessionStartDuration = TPService.calculateDuration(
          sessionEndDt,
          day.events,
        );
        final sessionEndDuration = _getSessionEndDur(
          events: day.events,
          sessionEndDt: sessionEndDt,
          today: i == todayIndex,
        );
        maxSessionDur = _checkSessionMaxDur(
          current: maxSessionDur,
          potential: sessionEndDuration,
        );
        minSessionDur = _checkSessionMinDur(
          current: minSessionDur,
          potential: sessionStartDuration,
        );
        if (i == todayIndex) {
          todayDur = currentDuration;
        }
      }
    }
    return StatData(
      maxDurReleventDays: maxSessionDur,
      minDurReleventDays: minSessionDur,
      totalDur: totalDur,
      todayDur: todayDur,
    );
  }

  static Duration _getSessionEndDur({
    required List<TimePoint> events,
    required DateTime sessionEndDt,
    required bool today,
  }) {
    if (today) {
      return TPService.calculateDuration(DateTime.now(), events);
    }
    return TPService.calculateDuration(sessionEndDt, events);
  }

  static Duration _checkSessionMaxDur({
    required Duration current,
    required Duration potential,
    // Duration sessionDur = const Duration(hours: 24),
  }) {
    if (potential > current) {
      // potential = potential > sessionDur ? sessionDur : potential;
      return potential + const Duration(minutes: 30);
    }

    return current;
  }

  static Duration _checkSessionMinDur({
    required Duration current,
    required Duration potential,
  }) {
    // if (potential < current) {
    //   return potential - const Duration(minutes: 30);
    // }
    // return current;
    return Duration.zero;
  }
}
