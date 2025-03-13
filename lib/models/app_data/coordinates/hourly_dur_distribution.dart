import 'package:ten_thousands_hours/models/time_data/time_point/time_point.dart';

import '../../../root/root.dart';
import '../../time_data/day_entry/day_model.dart';

class HourlyDurDistributionModel {
  final Map<int, Duration> avgDurSet;

  const HourlyDurDistributionModel({this.avgDurSet = _emptySet});

  static const Map<int, Duration> _emptySet = {
    0: Duration.zero,
    1: Duration.zero,
    2: Duration.zero,
    3: Duration.zero,
    4: Duration.zero,
    5: Duration.zero,
    6: Duration.zero,
    7: Duration.zero,
    8: Duration.zero,
    9: Duration.zero,
    10: Duration.zero,
    11: Duration.zero,
    12: Duration.zero,
    13: Duration.zero,
    14: Duration.zero,
    15: Duration.zero,
    16: Duration.zero,
    17: Duration.zero,
    18: Duration.zero,
    19: Duration.zero,
    20: Duration.zero,
    21: Duration.zero,
    22: Duration.zero,
    23: Duration.zero,
  };

  static HourlyDurDistributionModel empty() {
    return HourlyDurDistributionModel(
      avgDurSet: {
        0: Duration.zero,
        1: Duration.zero,
        2: Duration.zero,
        3: Duration.zero,
        4: Duration.zero,
        5: Duration.zero,
        6: Duration.zero,
        7: Duration.zero,
        8: Duration.zero,
        9: Duration.zero,
        10: Duration.zero,
        11: Duration.zero,
        12: Duration.zero,
        13: Duration.zero,
        14: Duration.zero,
        15: Duration.zero,
        16: Duration.zero,
        17: Duration.zero,
        18: Duration.zero,
        19: Duration.zero,
        20: Duration.zero,
        21: Duration.zero,
        22: Duration.zero,
        23: Duration.zero,
      },
    );
  }

  /// not used.
  static generateHourlyDurDistribution({
    required List<DayEntry> days,
  }) {
    final Map<int, Duration> avgDurSet = {
      0: Duration.zero,
      1: Duration.zero,
      2: Duration.zero,
      3: Duration.zero,
      4: Duration.zero,
      5: Duration.zero,
      6: Duration.zero,
      7: Duration.zero,
      8: Duration.zero,
      9: Duration.zero,
      10: Duration.zero,
      11: Duration.zero,
      12: Duration.zero,
      13: Duration.zero,
      14: Duration.zero,
      15: Duration.zero,
      16: Duration.zero,
      17: Duration.zero,
      18: Duration.zero,
      19: Duration.zero,
      20: Duration.zero,
      21: Duration.zero,
      22: Duration.zero,
      23: Duration.zero,
    };
    for (final day in days) {
      Duration totalDur = Duration.zero;
      for (int i = 0; i <= 24; i++) {
        var dur = TPService.calculateDuration(
          DateTime(day.dt.year, day.dt.month, day.dt.day, i),
          day.events,
        );
        if (dur == Duration.zero) {
          continue;
        }
        var hourDur = avgDurSet[i];
        // totalDur += day.durPoint.dur;
      }
    }
    for (final key in avgDurSet.keys) {
      avgDurSet[key] = (avgDurSet[key]! ~/ days.length);
    }
    return HourlyDurDistributionModel(avgDurSet: avgDurSet);
  }

  /// use this.
  static Map<int, Duration> calAvgSet(
    List<DayEntry> days,
    List<int> excludeIndices, {
    bool debug = false,
  }) {
    final hourlyData = <int, Duration>{};
    int numberOfDays = 0;
    for (int i = 0; i < days.length; i++) {
      if (excludeIndices.contains(i)) {
        continue;
      }
      numberOfDays++;
      final day = days[i];
      // pout(day.toString(), debug);
      // pout(day.events.toString(), debug);
      Duration previousDuration = Duration.zero;
      for (int j = 1; j <= 24; j++) {
        final targetTime = DateTime(
          day.dt.year,
          day.dt.month,
          day.dt.day,
          j,
        );
        final dur = TPService.calculateDuration(targetTime, day.events);
        if (dur == Duration.zero) {
          continue;
        }
        final hourDur = dur - previousDuration;
        previousDuration = dur;
        if (hourDur == Duration.zero) {
          continue;
        }
        if (hourlyData.containsKey(j)) {
          hourlyData[j] = hourlyData[j]! + hourDur;
        } else {
          hourlyData[j] = hourDur;
        }
      }
    }
    for (int j = 1; j <= 24; j++) {
      if (hourlyData.containsKey(j)) {
        hourlyData[j] = hourlyData[j]! ~/ numberOfDays;
      } else {
        hourlyData[j] = Duration.zero;
      }
    }
    pout(hourlyData.toString(), debug);
    return hourlyData;
  }
}
