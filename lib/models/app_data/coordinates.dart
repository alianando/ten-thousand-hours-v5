import 'package:flutter/material.dart';
import 'package:ten_thousands_hours/root/root.dart';

import '../time_data/day_entry/day_model.dart';
import '../time_data/time_point/time_point.dart';
import 'coordinates/hourly_dur_distribution.dart';
import 'session_data.dart';
import 'stat_data.dart';

class Coordinates {
  final SessionOffsets session;
  final HourlyDurDistributionModel hourlyDurDistribution;

  const Coordinates({
    this.session = const SessionOffsets(),
    this.hourlyDurDistribution = const HourlyDurDistributionModel(),
  });

  Coordinates copyWith({
    SessionOffsets? session,
    HourlyDurDistributionModel? hourlyDurDistribution,
  }) {
    return Coordinates(
      session: session ?? this.session,
      hourlyDurDistribution:
          hourlyDurDistribution ?? this.hourlyDurDistribution,
    );
  }
}

class SessionOffsets {
  final List<Offset> today;
  final List<List<Offset>> allDays;

  // List<Offset> get all => today + allDays.expand((element) => element).toList();
  List<List<Offset>> get unactiveObjects {
    return List<List<Offset>>.from(allDays)
      ..removeWhere(
        (element) {
          bool isToday = element == today;
          return isToday;
        },
      );
  }

  const SessionOffsets({
    this.today = const [],
    this.allDays = const [],
  });

  // static handelToday({
  //   required List<DayEntry> dayEntries,
  //   required Indices indices,
  //   required StatData statData,
  //   required SessionData sessionData,
  // }) {
  //   return calculateSession(
  //     dayEntries: dayEntries,
  //     indices: indices,
  //     statData: statData,
  //     sessionData: sessionData,
  //   ).today;
  // }
  SessionOffsets handelTodayDtUpdate({
    required List<TimePoint> corePoints,
    required DateTime sessionStartDt,
    required DateTime sessionEndDt,
    required Duration maxSessionDur,
    required Duration minSessionDur,
  }) {
    var pointsForCoordinate = _addTimePoint(corePoints, sessionStartDt, false);
    pointsForCoordinate = _addTimePoint(
      pointsForCoordinate,
      DateTime.now(),
      false,
    );
    return SessionOffsets(
      today: _generateCoordinates(
        timePoints: pointsForCoordinate,
        sessionStartTime: sessionStartDt,
        sessionEndTime: sessionEndDt,
        maxSessionDur: maxSessionDur,
        minSessionDur: minSessionDur,
      ),
      allDays: allDays,
    );
  }

  static SessionOffsets calculateSession({
    required List<DayEntry> dayEntries,
    // required Indices indices,
    required int activeSessionIndex,
    required List<int> allSessionInices,
    required StatData statData,
    required SessionData sessionData,
    bool debug = false,
  }) {
    pout('calculateSession <- SessionOffsets Class', debug);
    pout(' statData', debug);
    pout('    maxDur ${statData.maxDurReleventDays}', debug);
    pout('    minDur ${statData.minDurReleventDays}', debug);
    pout('    totalDur ${statData.totalDur}', debug);
    pout('    todayDur ${statData.todayDur}', debug);
    pout(' sessionData', debug);
    pout('    sessionStartDt ${sessionData.sessionStartDt}', debug);
    pout('    sessionEndDt ${sessionData.sessionEndDt}', debug);
    pout(' activeSessionIndex $activeSessionIndex', debug);
    pout(' allSessionInices $allSessionInices', debug);
    pout(' dayEntries', debug);
    pout('    length ${dayEntries.length}', debug);
    pout('    first ${dayEntries.first}', debug);

    // output objects
    List<Offset> activeObject = [];
    List<List<Offset>> allObjects = [];

    if (dayEntries.isEmpty) {
      return const SessionOffsets();
    }
    for (int i in allSessionInices) {
      List<TimePoint> points = _addTimePoint(
        dayEntries[i].events,
        sessionData.sessionStartDt,
        false,
      );
      points = _addTimePoint(points, DateTime.now(), false);
      if (i == activeSessionIndex) {
        activeObject = _generateCoordinates(
          timePoints: points,
          sessionStartTime: sessionData.sessionStartDt,
          sessionEndTime: sessionData.sessionEndDt,
          maxSessionDur: statData.maxDurReleventDays,
          minSessionDur: statData.minDurReleventDays,
        );
      } else {
        points = _addTimePoint(points, sessionData.sessionEndDt, false);
        allObjects.add(_generateCoordinates(
          timePoints: points,
          sessionStartTime: sessionData.sessionStartDt,
          sessionEndTime: sessionData.sessionEndDt,
          maxSessionDur: statData.maxDurReleventDays,
          minSessionDur: statData.minDurReleventDays,
        ));
      }
    }
    return SessionOffsets(
      today: activeObject,
      allDays: allObjects,
    );
  }

  /// Generates coordinates based on time points
  /// date is corrected.
  static List<Offset> _generateCoordinates({
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
  static List<TimePoint> _addTimePoint(
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
}

class CoordinateHelper {
  const CoordinateHelper._();

  static Coordinates generateCoordinates({
    required List<DayEntry> dayEntries,
    required int activeSessionIndex,
    required List<int> allSessionInices,
    required StatData statData,
    required SessionData sessionData,
    bool debug = false,
  }) {
    final sessionOffsets = SessionOffsets.calculateSession(
      dayEntries: dayEntries,
      activeSessionIndex: activeSessionIndex,
      allSessionInices: allSessionInices,
      statData: statData,
      sessionData: sessionData,
      debug: debug,
    );
    final avgSet = HourlyDurDistributionModel.calAvgSet(
      dayEntries,
      allSessionInices,
      debug: debug,
    );
    final hourlyDurDistribution = HourlyDurDistributionModel(
      avgDurSet: avgSet,
    );
    return Coordinates(
      session: sessionOffsets,
      hourlyDurDistribution: hourlyDurDistribution,
    );
  }

  static Coordinates handelTodayDtUpdate({
    required Coordinates coordinates,
    required List<TimePoint> corePoints,
    required DateTime sessionStartDt,
    required DateTime sessionEndDt,
    required Duration maxSessionDur,
    required Duration minSessionDur,
  }) {
    final newSession = coordinates.session.handelTodayDtUpdate(
      corePoints: corePoints,
      sessionStartDt: sessionStartDt,
      sessionEndDt: sessionEndDt,
      maxSessionDur: maxSessionDur,
      minSessionDur: minSessionDur,
    );
    return coordinates.copyWith(session: newSession);
  }
}
