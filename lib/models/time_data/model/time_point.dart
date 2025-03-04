import 'package:flutter/material.dart';

enum TimePointTyp {
  pause,
  resume,
}

class TimePoint {
  final DateTime dt;
  final Duration dur;
  final TimePointTyp typ;

  const TimePoint({
    required this.dt,
    required this.dur,
    required this.typ,
  });

  Map<String, dynamic> toJson() {
    return {
      'dt': dt.toIso8601String(),
      'dur': dur.inMilliseconds,
      'typ': typ.toString().split('.').last,
    };
  }

  factory TimePoint.fromJson(Map<String, dynamic> json) {
    return TimePoint(
      dt: DateTime.parse(json['dt']),
      dur: Duration(milliseconds: json['dur']),
      typ: TimePointTyp.values.firstWhere(
        (e) => e.toString().split('.').last == json['typ'],
      ),
    );
  }

  @override
  String toString() {
    return '(${dt.hour}:${dt.minute}:${dt.second}, ${dur.inMinutes}sec), ${typ.toString().split('.').last}';
  }
}

class TPService {
  const TPService._();

  /// Generates coordinates based on time points
  /// date is corrected.
  static List<Offset> generateCoordinates({
    required List<TimePoint> timePoints,
    required DateTime sessionStartTime,
    required DateTime sessionEndTime,
    required Duration maxSessionDur,
    required Duration minSessionDur,
    bool debug = false,
  }) {
    final sessionStartDt = DtHelper.correctDt(
      sessionStartTime,
      timePoints.isNotEmpty ? timePoints.first.dt : DateTime.now(),
    );
    final sessionDur = sessionEndTime.difference(sessionStartTime);
    final sessionDurInMilliseconds = sessionDur.inMilliseconds;
    if (debug) {
      debugPrint('## -- sessionDurInMilliseconds: $sessionDurInMilliseconds');
    }

    return timePoints
        .map((point) => _generateCoordinate(
              point: point,
              sessionStartDt: sessionStartDt,
              sessionDurInMilliseconds: sessionDurInMilliseconds > 0
                  ? sessionDurInMilliseconds
                  : const Duration(seconds: 1)
                      .inMilliseconds, // Prevent division by zero
              maxDur: maxSessionDur,
              minDur: minSessionDur,
              debug: debug,
            ))
        .whereType<Offset>() // Filter out null values
        .toList();
  }

  /// Generates a single coordinate for visualization
  static Offset? _generateCoordinate({
    required TimePoint point,
    required DateTime sessionStartDt,
    required int sessionDurInMilliseconds,
    required Duration maxDur,
    required Duration minDur,
    bool debug = false,
  }) {
    if (debug) {
      debugPrint('## -- at: ${point.dt}');
    }
    final timeDiffInMilliseconds =
        point.dt.difference(sessionStartDt).inMilliseconds;
    if (debug) {
      debugPrint('## -- timeDiffInMilliseconds: $timeDiffInMilliseconds');
    }

    final x = timeDiffInMilliseconds / sessionDurInMilliseconds;
    if (debug) {
      debugPrint('## -- x: $x');
    }
    // Only generate coordinates within the session timeframe
    if (x >= 0 && x <= 1) {
      // Prevent division by zero and handle edge cases
      final denominator = (maxDur - minDur).inSeconds;
      if (debug) {
        debugPrint(
            '## -- maxDur: $maxDur, minDur: $minDur, denominator: $denominator');
      }
      if (debug) {
        debugPrint('## -- point.dur.inSeconds: ${point.dur}');
      }
      final y = denominator > 0
          ? point.dur.inSeconds / denominator
          : point.dur.inSeconds > 0
              ? 1.0
              : 0.0;

      if (debug) {
        debugPrint('## -- : [$x, $y]');
      }
      return Offset(x, y);
    }
    if (debug) {
      debugPrint('## -- [null]');
    }
    return null;
  }

  /// retrun new sorted list with target timePoint.
  /// date is correctd.
  static List<TimePoint> addTimePoint(
    List<TimePoint> points,
    DateTime dt,
    bool active,
  ) {
    if (points.isEmpty) {
      return [
        TimePoint(
          dt: dt,
          dur: const Duration(),
          typ: active ? TimePointTyp.resume : TimePointTyp.pause,
        ),
      ];
    }

    final correctedDt = DtHelper.correctDt(dt, points.first.dt);
    for (int i = points.length - 1; i >= 0; i--) {
      final p = points[i];
      if (p.dt.isAtSameMomentAs(correctedDt)) {
        return points;
      }
      if (correctedDt.isAfter(p.dt)) {
        Duration dur = p.typ == TimePointTyp.resume
            ? p.dur + correctedDt.difference(p.dt)
            : p.dur;
        TimePointTyp typ = p.typ;
        if (active) {
          typ = typ == TimePointTyp.resume
              ? TimePointTyp.pause
              : TimePointTyp.resume;
        }
        final newPoint = TimePoint(
          dt: correctedDt,
          dur: dur,
          typ: typ,
        );
        points = List.from(points)..insert(i + 1, newPoint);
        points.sort((a, b) => a.dt.compareTo(b.dt));
        return points;
      }
    }
    return points;
  }

  /// Calculates the duration at a specific time
  /// date is corrected.
  static Duration calculateDuration(DateTime timeAt, List<TimePoint> events) {
    if (events.isEmpty) return Duration.zero;
    timeAt = DtHelper.correctDt(timeAt, events.first.dt);

    // Search for the appropriate time point to calculate duration
    for (int i = events.length - 1; i >= 0; i--) {
      if (timeAt.isAfter(events[i].dt)) {
        final dur = events[i].dur;
        return events[i].typ == TimePointTyp.resume
            ? dur + timeAt.difference(events[i].dt)
            : dur;
      }
      if (timeAt.isAtSameMomentAs(events[i].dt)) {
        return events[i].dur;
      }
    }
    return Duration.zero;
  }
}

class DtHelper {
  const DtHelper._();

  static bool sameHourMinute(DateTime dt1, DateTime dt2) {
    return dt1.hour == dt2.hour && dt1.minute == dt2.minute;
  }

  static bool isDayStartDt(DateTime dt) {
    final bool not = dt.hour != 0 || dt.minute != 0 || dt.second != 0;
    return !not;
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
}
