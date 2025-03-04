import 'package:ten_thousands_hours/models/time_data/model/day_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/time_point.dart';

class StatData {
  final Duration maxDurReleventDays;
  final Duration minDurReleventDays;
  final Duration totalDur;

  const StatData({
    required this.maxDurReleventDays,
    required this.minDurReleventDays,
    required this.totalDur,
  });

  Map<String, dynamic> toJson() {
    return {
      'maxDurReleventDays': maxDurReleventDays.inMilliseconds,
      'minDurReleventDays': minDurReleventDays.inMilliseconds,
      'totalDur': totalDur.inMilliseconds,
    };
  }

  factory StatData.fromJson(Map<String, dynamic> json) {
    return StatData(
      maxDurReleventDays: Duration(milliseconds: json['maxDurReleventDays']),
      minDurReleventDays: Duration(milliseconds: json['minDurReleventDays']),
      totalDur: Duration(milliseconds: json['totalDur']),
    );
  }

  StatData copyWith({
    Duration? maxDurReleventDays,
    Duration? minDurReleventDays,
    Duration? totalDur,
  }) {
    return StatData(
      maxDurReleventDays: maxDurReleventDays ?? this.maxDurReleventDays,
      minDurReleventDays: minDurReleventDays ?? this.minDurReleventDays,
      totalDur: totalDur ?? this.totalDur,
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
    );
  }

  /// Updates the statistics
  static StatData updateMaxMin({
    required StatData oldStats,
    required List<DayModel> days,
    required DateTime sessionStartDt,
    required DateTime sessionEndDt,
    required int todayIndex,
    required List<int> releventIndecies,
  }) {
    // Duration totalDur = Duration.zero;
    Duration maxDurReleventDays = Duration.zero;
    // Duration durIncreased = Duration.zero;
    // Duration minDurReleventDays = Duration.zero;
    for (int i = 0; i < releventIndecies.length; i++) {
      final day = days[i];
      if (i == todayIndex) {
        maxDurReleventDays = _checkMaxDur(
          current: maxDurReleventDays,
          potential: day.durPoint.dur,
          sessionDur: sessionEndDt.difference(sessionStartDt),
        );
      } else {
        maxDurReleventDays = _checkMaxDur(
          current: maxDurReleventDays,
          potential: TPService.calculateDuration(sessionEndDt, day.events),
          sessionDur: sessionEndDt.difference(sessionStartDt),
        );
      }
    }
    return oldStats.copyWith(
      maxDurReleventDays: maxDurReleventDays,
    );
  }

  static StatData updateStatistics({
    required StatData oldStat,
    required Duration durIncreased,
    required Duration potentialMaxDur,
    required Duration potentialMinDur,
  }) {
    return oldStat.copyWith(
      maxDurReleventDays: _checkMaxDur(
        current: oldStat.maxDurReleventDays,
        potential: potentialMaxDur,
      ),
      minDurReleventDays: potentialMinDur > oldStat.maxDurReleventDays
          ? oldStat.maxDurReleventDays
          : potentialMinDur,
      totalDur: oldStat.totalDur + durIncreased,
    );
  }

  static _checkMaxDur({
    required Duration current,
    required Duration potential,
    Duration sessionDur = const Duration(hours: 24),
  }) {
    if (potential > current) {
      return potential + const Duration(minutes: 30);
    }
    // if (sessionDur < const Duration(hours: 5)) {
    //   if (potential < sessionDur) {
    //     return sessionDur;
    //   }
    //   if (potential < sessionDur * 2) {
    //     return sessionDur * 2;
    //   }
    // }
    // if (potential > current) {
    //   if (potential < const Duration(hours: 3)) {
    //     return potential + const Duration(minutes: 30);
    //   }
    //   return potential + const Duration(hours: 1);
    // }
    return current;
  }
}
