import 'dart:math';

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
    return '(${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}, ${dur.inSeconds}s), ${typ.toString().split('.').last}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimePoint &&
        other.dt.isAtSameMomentAs(dt) &&
        other.dur == dur &&
        other.typ == typ;
  }

  @override
  int get hashCode => Object.hash(
        dt.millisecondsSinceEpoch,
        dur.inMicroseconds,
        typ,
      );

  factory TimePoint.pause(DateTime dt, Duration dur) {
    return TimePoint(dt: dt, dur: dur, typ: TimePointTyp.pause);
  }

  factory TimePoint.resume(DateTime dt, Duration dur) {
    return TimePoint(dt: dt, dur: dur, typ: TimePointTyp.resume);
  }

  factory TimePoint.atTime(DateTime dt) {
    return TimePoint(dt: dt, dur: Duration.zero, typ: TimePointTyp.pause);
  }

  /// Creates a copy of this TimePoint with optional field overrides
  TimePoint copyWith({
    DateTime? dt,
    Duration? dur,
    TimePointTyp? typ,
  }) {
    return TimePoint(
      dt: dt ?? this.dt,
      dur: dur ?? this.dur,
      typ: typ ?? this.typ,
    );
  }

  /// Returns true if this point represents active time tracking
  bool get isActive => typ == TimePointTyp.resume;

  /// Returns a formatted string of the duration in HH:MM:SS format
  String get formattedDuration {
    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;
    final seconds = dur.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns the time of day in HH:MM format
  String get timeOfDay {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class TPService {
  const TPService._();

  static List<Offset> generateCoordinates({
    required List<TimePoint> timePoints,
    required DateTime sessionStartTime,
    required DateTime sessionEndTime,
    required Duration maxSessionDur,
    required Duration minSessionDur,
    bool debug = false,
  }) {
    if (timePoints.isEmpty) {
      return [];
    }

    // Ensure session end is after start
    if (sessionEndTime.isBefore(sessionStartTime)) {
      final temp = sessionStartTime;
      sessionStartTime = sessionEndTime;
      sessionEndTime = temp;
    }

    final sessionStartDt = DtHelper.correctDt(
      sessionStartTime,
      timePoints.isNotEmpty ? timePoints.first.dt : DateTime.now(),
    );

    // Ensure there's at least a minimum duration
    final sessionDur = sessionEndTime.difference(sessionStartTime);
    final sessionDurInMilliseconds = sessionDur.inMilliseconds <= 0
        ? const Duration(seconds: 1).inMilliseconds
        : sessionDur.inMilliseconds;

    if (debug) {
      debugPrint('## -- sessionDurInMilliseconds: $sessionDurInMilliseconds');
    }

    return timePoints
        .map((point) => _generateCoordinate(
              point: point,
              correctedSesStartDt: sessionStartDt,
              sessionDurInMillisec: sessionDurInMilliseconds,
              maxDur: maxSessionDur,
              minDur: minSessionDur,
              debug: debug,
            ))
        .whereType<Offset>()
        .toList();
  }

  /// Generates a single coordinate for visualization
  static Offset? _generateCoordinate({
    required TimePoint point,
    required DateTime correctedSesStartDt,
    required int sessionDurInMillisec,
    required Duration maxDur,
    required Duration minDur,
    bool debug = false,
  }) {
    if (debug) {
      debugPrint('## -- at: ${point.dt}');
    }
    final timeDiffInMillisec =
        point.dt.difference(correctedSesStartDt).inMilliseconds;
    if (debug) {
      debugPrint('## -- timeDiffInMilliseconds: $timeDiffInMillisec');
    }

    final x = timeDiffInMillisec / sessionDurInMillisec;
    if (debug) {
      debugPrint('## -- x: $x');
    }
    // Only generate coordinates within the session timeframe
    if (x >= 0 && x <= 1) {
      // Prevent division by zero and handle edge cases
      final denominator = (maxDur - minDur).inMilliseconds.abs();
      if (debug) {
        debugPrint(
            '## -- maxDur: $maxDur, minDur: $minDur, denominator: $denominator');
      }
      if (debug) {
        debugPrint('## -- point.dur.inSeconds: ${point.dur}');
      }
      final y = denominator > 0
          ? point.dur.inMilliseconds / denominator
          : point.dur.inMilliseconds > 0
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

  /// Returns a new sorted list with the target TimePoint inserted.
  /// The date part of timeAt is corrected to match the reference date from points.
  ///
  /// @param points The existing list of time points
  /// @param timeAt The time at which to insert a new point
  /// @param isActivePoint Whether to toggle the activity type from the previous point
  /// @return A new list with the time point inserted in the correct position
  static List<TimePoint> insertTimePoint(
    List<TimePoint> points,
    DateTime timeAt,
    bool isActivePoint,
  ) {
    // Handle empty list case
    if (points.isEmpty) {
      return [TimePoint.pause(timeAt, Duration.zero)];
    }

    // Correct the date part of timeAt to match the reference date
    final correctedDt = DtHelper.correctDt(timeAt, points.first.dt);

    // Early return if this time already exists in the list
    final existingPoint = points.firstWhere(
      (p) => p.dt.isAtSameMomentAs(correctedDt),
      orElse: () => TimePoint(
        dt: DateTime(1970),
        dur: Duration.zero,
        typ: TimePointTyp.pause,
      ),
    );

    if (existingPoint.dt.year != 1970) {
      return points;
    }

    // Find the insertion point (the latest point before correctedDt)
    final insertAfterIndex = points.lastIndexWhere(
      (p) => correctedDt.isAfter(p.dt),
    );

    // If no suitable insertion point found, return original list
    if (insertAfterIndex < 0) {
      return points;
    }

    final previousPoint = points[insertAfterIndex];

    // Calculate new duration based on previous point
    final newDuration = previousPoint.typ == TimePointTyp.resume
        ? previousPoint.dur + correctedDt.difference(previousPoint.dt)
        : previousPoint.dur;

    // Determine type based on previous point and isActivePoint flag
    final newType = isActivePoint
        ? (previousPoint.typ == TimePointTyp.resume
            ? TimePointTyp.pause
            : TimePointTyp.resume)
        : previousPoint.typ;

    // Create new point with calculated values
    final newPoint = TimePoint(
      dt: correctedDt,
      dur: newDuration,
      typ: newType,
    );

    // Create new list and insert at the correct position
    final result = List<TimePoint>.from(points);
    result.insert(insertAfterIndex + 1, newPoint);

    // Return the sorted list
    return result;
  }

  /// Calculates the duration at a specific time
  /// The date part of timeAt is corrected to match the reference date from events.
  ///
  /// @param timeAt The time to calculate duration for
  /// @param events The list of time points to use for calculation
  /// @return The accumulated duration at the specified time
  static Duration calculateDuration(DateTime timeAt, List<TimePoint> events) {
    // Handle empty list case
    if (events.isEmpty) {
      return Duration.zero;
    }

    // Correct date part to match reference date
    final correctedDt = DtHelper.correctDt(timeAt, events.first.dt);

    // Use binary search to find the closest point before or at the given time
    // This is more efficient than linear search for large lists
    int low = 0;
    int high = events.length - 1;
    int result = -1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final point = events[mid];

      if (point.dt.isAtSameMomentAs(correctedDt)) {
        // Exact match found
        return point.dur;
      } else if (point.dt.isBefore(correctedDt)) {
        // This point is before our target time, might be the one we want
        result = mid;
        low = mid + 1;
      } else {
        // This point is after our target time, look earlier
        high = mid - 1;
      }
    }

    // If we didn't find any point before the target time
    if (result == -1) {
      return Duration.zero;
    }

    // Get the last point before the target time
    final latestPoint = events[result];

    // If this was a resume point, add elapsed time since the point
    return latestPoint.typ == TimePointTyp.resume
        ? latestPoint.dur + correctedDt.difference(latestPoint.dt)
        : latestPoint.dur;
  }

  static TimePoint determineTimePoint(List<TimePoint> events, DateTime timeAt) {
    if (events.isEmpty) {
      return TimePoint(
        dt: timeAt,
        dur: const Duration(),
        typ: TimePointTyp.pause,
      );
    }

    final correctedDt = DtHelper.correctDt(timeAt, events.first.dt);
    for (int i = events.length - 1; i >= 0; i--) {
      final p = events[i];
      if (p.dt.isAtSameMomentAs(correctedDt)) {
        return p;
      }
      if (correctedDt.isAfter(p.dt)) {
        return TimePoint(
          dt: correctedDt,
          dur: p.typ == TimePointTyp.resume
              ? p.dur + correctedDt.difference(p.dt)
              : p.dur,
          typ: p.typ,
        );
      }
    }
    return TimePoint(
      dt: correctedDt,
      dur: const Duration(),
      typ: TimePointTyp.pause,
    );
  }

  /// Computes the effective time point at a specific moment in time.
  /// If an exact match exists in the events list, that point is returned.
  /// Otherwise, a new hypothetical time point is created based on the latest event.
  ///
  /// @param events The list of time points to use for calculation
  /// @param timeAt The time at which to determine the effective time point
  /// @return The effective time point at the specified time
  static TimePoint getEffectivePointAt(
      List<TimePoint> events, DateTime timeAt) {
    // Handle empty list case
    if (events.isEmpty) {
      return TimePoint(
        dt: timeAt,
        dur: Duration.zero,
        typ: TimePointTyp.pause,
      );
    }

    // Correct date part to match reference date
    final correctedDt = DtHelper.correctDt(timeAt, events.first.dt);

    // Use binary search to find the relevant point - similar to calculateDuration
    // This is more efficient than the linear search (especially for larger lists)
    int low = 0;
    int high = events.length - 1;
    int result = -1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final point = events[mid];

      if (point.dt.isAtSameMomentAs(correctedDt)) {
        // Exact match found - return the existing point
        return point;
      } else if (point.dt.isBefore(correctedDt)) {
        // This point is before our target time, might be the one we want
        result = mid;
        low = mid + 1;
      } else {
        // This point is after our target time, look earlier
        high = mid - 1;
      }
    }

    // If we didn't find any point before the target time,
    // return a default point at the corrected time
    if (result == -1) {
      return TimePoint(
        dt: correctedDt,
        dur: Duration.zero,
        typ: TimePointTyp.pause,
      );
    }

    // Get the last point before the target time
    final latestPoint = events[result];

    // Create a new hypothetical point at the requested time with calculated duration
    return TimePoint(
      dt: correctedDt,
      dur: latestPoint.typ == TimePointTyp.resume
          ? latestPoint.dur + correctedDt.difference(latestPoint.dt)
          : latestPoint.dur,
      typ: latestPoint.typ,
    );
  }

  /// Calculates total active duration from a list of time points
  static Duration calculateTotalDuration(List<TimePoint> events) {
    if (events.isEmpty) {
      return Duration.zero;
    }

    Duration total = Duration.zero;
    TimePointTyp prevType = TimePointTyp.pause;
    DateTime prevTime = events.first.dt;

    for (final point in events) {
      if (prevType == TimePointTyp.resume) {
        total += point.dt.difference(prevTime);
      }
      prevType = point.typ;
      prevTime = point.dt;
    }

    // Account for ongoing tracking if the last point is resume
    if (events.last.typ == TimePointTyp.resume) {
      total += DateTime.now().difference(events.last.dt);
    }

    return total;
  }

  /// Merges two lists of time points, maintaining chronological order
  static List<TimePoint> mergeTimePointLists(
      List<TimePoint> list1, List<TimePoint> list2) {
    if (list1.isEmpty) return List.from(list2);
    if (list2.isEmpty) return List.from(list1);

    final merged = <TimePoint>[...list1, ...list2];
    merged.sort((a, b) => a.dt.compareTo(b.dt));

    // Remove duplicates (points at exact same time)
    final result = <TimePoint>[];
    TimePoint? lastPoint;

    for (final point in merged) {
      if (lastPoint == null || !lastPoint.dt.isAtSameMomentAs(point.dt)) {
        result.add(point);
        lastPoint = point;
      }
    }

    return result;
  }

  /// Groups time points by day
  static Map<DateTime, List<TimePoint>> groupByDay(List<TimePoint> points) {
    final Map<DateTime, List<TimePoint>> result = {};

    for (final point in points) {
      final dayStart = DtHelper.dayStartDt(point.dt);
      if (!result.containsKey(dayStart)) {
        result[dayStart] = [];
      }
      result[dayStart]!.add(point);
    }

    return result;
  }

  /// Splits a continuous session at day boundaries
  /// Useful for analyzing multi-day sessions
  static List<List<TimePoint>> splitByDayBoundary(List<TimePoint> points) {
    if (points.isEmpty) return [];

    final result = <List<TimePoint>>[];
    var currentDay = <TimePoint>[];
    DateTime? lastDate;

    for (final point in points) {
      final currentDate = DateTime(point.dt.year, point.dt.month, point.dt.day);

      if (lastDate != null && currentDate != lastDate) {
        // Day boundary detected
        result.add(currentDay);
        currentDay = [];
      }

      currentDay.add(point);
      lastDate = currentDate;
    }

    if (currentDay.isNotEmpty) {
      result.add(currentDay);
    }

    return result;
  }

  /// Extracts sessions from time points
  /// A session is defined as the time between resume and pause
  static List<(TimePoint start, TimePoint end, Duration duration)>
      extractSessions(List<TimePoint> points) {
    final sessions = <(TimePoint, TimePoint, Duration)>[];
    TimePoint? sessionStart;

    for (final point in points) {
      if (point.typ == TimePointTyp.resume) {
        sessionStart = point;
      } else if (point.typ == TimePointTyp.pause && sessionStart != null) {
        final duration = point.dt.difference(sessionStart.dt);
        sessions.add((sessionStart, point, duration));
        sessionStart = null;
      }
    }

    // Handle ongoing session
    if (sessionStart != null) {
      final now = DateTime.now();
      final correctedNow = DtHelper.correctDt(now, points.first.dt);
      final ongoingEnd = TimePoint(
        dt: correctedNow,
        dur: sessionStart.dur + correctedNow.difference(sessionStart.dt),
        typ: TimePointTyp.pause,
      );
      sessions.add(
        (sessionStart, ongoingEnd, correctedNow.difference(sessionStart.dt)),
      );
    }

    return sessions;
  }
}

extension TPServiceAnalytics on TPService {
  /// Analyzes time patterns and returns statistics about time usage
  static Map<String, dynamic> analyzeTimePatterns(List<TimePoint> points) {
    if (points.isEmpty) return {};

    final sessions = TPService.extractSessions(points);
    if (sessions.isEmpty) return {};

    // Calculate statistics
    final durations = sessions.map((s) => s.$3).toList();
    durations.sort();

    final totalTime = durations.fold(Duration.zero, (a, b) => a + b);
    final averageDuration = durations.isEmpty
        ? Duration.zero
        : Duration(microseconds: totalTime.inMicroseconds ~/ durations.length);

    final medianDuration =
        durations.isEmpty ? Duration.zero : durations[durations.length ~/ 2];

    // Analyze session start times
    final startTimes = sessions.map((s) => s.$1.dt.hour).toList();
    Map<int, int> startTimeDistribution = {};
    for (final hour in startTimes) {
      startTimeDistribution[hour] = (startTimeDistribution[hour] ?? 0) + 1;
    }

    // Find most productive time (hour with longest total duration)
    Map<int, Duration> hourlyDurations = {};
    for (final session in sessions) {
      final startHour = session.$1.dt.hour;
      final duration = session.$3;
      hourlyDurations[startHour] =
          (hourlyDurations[startHour] ?? Duration.zero) + duration;
    }

    int? mostProductiveHour;
    Duration mostProductiveTime = Duration.zero;
    hourlyDurations.forEach((hour, duration) {
      if (duration > mostProductiveTime) {
        mostProductiveHour = hour;
        mostProductiveTime = duration;
      }
    });

    return {
      'totalSessionTime': totalTime,
      'sessionCount': sessions.length,
      'averageSessionDuration': averageDuration,
      'medianSessionDuration': medianDuration,
      'shortestSession': durations.first,
      'longestSession': durations.last,
      'startTimeDistribution': startTimeDistribution,
      'mostProductiveHour': mostProductiveHour,
      'mostProductiveTime': mostProductiveTime,
    };
  }
}

extension TPServiceInterruptions on TPService {
  /// Identifies interruptions (short pauses) in work sessions
  static List<(TimePoint start, TimePoint end, Duration duration)>
      detectInterruptions(
    List<TimePoint> points, {
    Duration maxInterruptionLength = const Duration(minutes: 15),
  }) {
    final interruptions = <(TimePoint, TimePoint, Duration)>[];
    TimePoint? pausePoint;

    for (final point in points) {
      // Start of potential interruption
      if (point.typ == TimePointTyp.pause) {
        pausePoint = point;
      }
      // End of potential interruption
      else if (point.typ == TimePointTyp.resume && pausePoint != null) {
        final duration = point.dt.difference(pausePoint.dt);
        // Only consider it an interruption if it's shorter than maxInterruptionLength
        if (duration <= maxInterruptionLength) {
          interruptions.add((pausePoint, point, duration));
        }
        pausePoint = null;
      }
    }

    return interruptions;
  }
}

extension TPServiceGoals on TPService {
  /// Calculates progress toward time goals
  static Map<String, dynamic> calculateGoalProgress({
    required List<TimePoint> points,
    required Duration goalDuration,
    DateTime? startDate,
    DateTime? targetDate,
  }) {
    final totalDuration = TPService.calculateTotalDuration(points);
    final percentComplete =
        totalDuration.inMicroseconds / goalDuration.inMicroseconds;

    // Calculate time remaining
    final remainingDuration = goalDuration - totalDuration;

    // Calculate projected completion date if we have both dates
    DateTime? projectedCompletionDate;
    if (startDate != null && points.isNotEmpty) {
      final elapsed = DateTime.now().difference(startDate);
      final rate = totalDuration.inMicroseconds / elapsed.inMicroseconds;

      // Avoid division by zero
      if (rate > 0) {
        final projectedRemainingTime = Duration(
            microseconds: (remainingDuration.inMicroseconds / rate).round());
        projectedCompletionDate = DateTime.now().add(projectedRemainingTime);
      }
    }

    // Calculate if on track to meet target date
    bool? onTrack;
    if (targetDate != null && projectedCompletionDate != null) {
      onTrack = !projectedCompletionDate.isAfter(targetDate);
    }

    return {
      'totalDuration': totalDuration,
      'goalDuration': goalDuration,
      'percentComplete': percentComplete,
      'remainingDuration': remainingDuration,
      'projectedCompletionDate': projectedCompletionDate,
      'onTrack': onTrack,
    };
  }
}

extension TPServiceExport on TPService {
  /// Exports time points to CSV format
  static String exportToCsv(List<TimePoint> points) {
    if (points.isEmpty) return '';

    // CSV header
    final buffer = StringBuffer('Date,Time,Type,Duration\n');

    // Format each point as a CSV row
    for (final point in points) {
      final date =
          '${point.dt.year}-${point.dt.month.toString().padLeft(2, '0')}-${point.dt.day.toString().padLeft(2, '0')}';
      final time =
          '${point.dt.hour.toString().padLeft(2, '0')}:${point.dt.minute.toString().padLeft(2, '0')}:${point.dt.second.toString().padLeft(2, '0')}';
      final type = point.typ.toString().split('.').last;
      final duration = point.dur.inMilliseconds;

      buffer.writeln('$date,$time,$type,$duration');
    }

    return buffer.toString();
  }

  /// Imports time points from CSV format
  static List<TimePoint> importFromCsv(String csv) {
    final points = <TimePoint>[];
    final lines = csv.split('\n');

    // Skip header
    if (lines.length <= 1) return points;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length < 4) continue;

      try {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');

        final dt = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
          int.parse(timeParts[2]),
        );

        final type =
            parts[2] == 'resume' ? TimePointTyp.resume : TimePointTyp.pause;
        final duration = Duration(milliseconds: int.parse(parts[3]));

        points.add(TimePoint(dt: dt, dur: duration, typ: type));
      } catch (e) {
        // Skip invalid lines
        debugPrint('Error parsing CSV line: $line');
      }
    }

    return points;
  }
}

extension TPServiceDayModel on TPService {
  /// Creates TimePoints for standard day boundaries
  static List<TimePoint> createDayBoundaryPoints(DateTime date) {
    final midnight = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return [
      TimePoint.pause(midnight, Duration.zero),
      TimePoint.pause(endOfDay, Duration.zero),
    ];
  }

  /// Ensures a day has boundary points at start and end
  static List<TimePoint> ensureDayBoundaries(
      List<TimePoint> points, DateTime date) {
    if (points.isEmpty) {
      return createDayBoundaryPoints(date);
    }

    // Deep copy the list
    final result = List<TimePoint>.from(points);
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Check if we need to add a start point
    if (result.first.dt.hour != 0 || result.first.dt.minute != 0) {
      result.insert(0, TimePoint.pause(dayStart, Duration.zero));
    }

    // Check if we need to add an end point
    final lastPoint = result.last;
    if (lastPoint.dt.hour != 23 || lastPoint.dt.minute != 59) {
      result.add(TimePoint.pause(dayEnd, lastPoint.dur));
    }

    return result;
  }
}

extension TPServiceStreaks on TPService {
  /// Calculates streaks (consecutive days with activity)
  static Map<String, dynamic> calculateStreaks(
      Map<DateTime, List<TimePoint>> dailyPoints) {
    if (dailyPoints.isEmpty) return {};

    // Sort days chronologically
    final sortedDays = dailyPoints.keys.toList()..sort();

    // Find days with actual activity (more than 5 minutes of work)
    final activeDays = sortedDays.where((date) {
      final points = dailyPoints[date]!;
      final duration = TPService.calculateTotalDuration(points);
      return duration.inMinutes > 5;
    }).toList();

    if (activeDays.isEmpty) return {'currentStreak': 0, 'longestStreak': 0};

    // Calculate streaks
    int currentStreak = 1;
    int maxStreak = 1;
    final streaks = <List<DateTime>>[];
    List<DateTime> currentStreakDays = [activeDays[0]];

    for (int i = 1; i < activeDays.length; i++) {
      final yesterday = DateTime(
          activeDays[i].year, activeDays[i].month, activeDays[i].day - 1);

      // Check if this day continues the streak
      if (activeDays[i - 1].year == yesterday.year &&
          activeDays[i - 1].month == yesterday.month &&
          activeDays[i - 1].day == yesterday.day) {
        currentStreak++;
        currentStreakDays.add(activeDays[i]);
      } else {
        // Streak broken
        streaks.add(List.from(currentStreakDays));
        currentStreakDays = [activeDays[i]];
        currentStreak = 1;
      }

      maxStreak = max(maxStreak, currentStreak);
    }

    // Add the final streak
    streaks.add(currentStreakDays);

    // Check if current streak is active (includes today)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final isCurrentStreakActive = activeDays.last.isAtSameMomentAs(todayDate);

    return {
      'currentStreak': isCurrentStreakActive ? currentStreak : 0,
      'longestStreak': maxStreak,
      'allStreaks': streaks,
    };
  }
}

extension TPServiceHeatmap on TPService {
  /// Generates heatmap data for visualization
  static Map<DateTime, double> generateHeatmapData(
    Map<DateTime, List<TimePoint>> dailyPoints, {
    Duration? maxDuration,
  }) {
    final heatmapData = <DateTime, double>{};

    if (dailyPoints.isEmpty) return heatmapData;

    // Find maximum duration across all days if not provided
    final actualMaxDuration = maxDuration ??
        dailyPoints.entries
            .map((e) => TPService.calculateTotalDuration(e.value))
            .reduce((a, b) => a > b ? a : b);

    // Calculate intensity for each day (0.0 to 1.0)
    for (final entry in dailyPoints.entries) {
      final dailyDuration = TPService.calculateTotalDuration(entry.value);
      final intensity = actualMaxDuration.inMilliseconds > 0
          ? dailyDuration.inMilliseconds / actualMaxDuration.inMilliseconds
          : 0.0;

      heatmapData[entry.key] = intensity.clamp(0.0, 1.0);
    }

    return heatmapData;
  }
}

extension TPServiceFocus on TPService {
  /// Analyzes focus sessions with Pomodoro-style metrics
  static Map<String, dynamic> analyzeFocusSessions(
    List<TimePoint> points, {
    Duration standardSessionLength = const Duration(minutes: 25),
    Duration standardBreakLength = const Duration(minutes: 5),
  }) {
    final sessions = TPService.extractSessions(points);
    if (sessions.isEmpty) return {};

    int completePomodoros = 0;
    int incompletePomodoros = 0;
    int longSessions = 0;

    for (final session in sessions) {
      final duration = session.$3;

      if (duration >= standardSessionLength * 0.9 &&
          duration <= standardSessionLength * 1.1) {
        // Standard pomodoro completed
        completePomodoros++;
      } else if (duration < standardSessionLength * 0.9) {
        // Incomplete pomodoro
        incompletePomodoros++;
      } else {
        // Longer than standard session
        longSessions++;
        // Calculate equivalent number of pomodoros
        completePomodoros +=
            (duration.inMinutes / standardSessionLength.inMinutes).floor();
      }
    }

    // Analyze breaks between sessions
    final breaks = <Duration>[];
    for (int i = 1; i < sessions.length; i++) {
      final previousEnd = sessions[i - 1].$2.dt;
      final currentStart = sessions[i].$1.dt;
      final breakDuration = currentStart.difference(previousEnd);

      if (breakDuration > Duration.zero &&
          breakDuration < const Duration(hours: 3)) {
        breaks.add(breakDuration);
      }
    }

    // Calculate break statistics
    final standardBreaks = breaks
        .where((b) =>
            b >= standardBreakLength * 0.8 && b <= standardBreakLength * 1.2)
        .length;

    final longBreaks = breaks
        .where((b) =>
            b > standardBreakLength * 1.2 && b < const Duration(minutes: 30))
        .length;

    return {
      'completePomodoros': completePomodoros,
      'incompletePomodoros': incompletePomodoros,
      'longSessions': longSessions,
      'totalSessions': sessions.length,
      'standardBreaks': standardBreaks,
      'longBreaks': longBreaks,
      'averageBreakDuration': breaks.isEmpty
          ? Duration.zero
          : breaks.fold<Duration>(Duration.zero, (a, b) => a + b) ~/
              breaks.length,
      'focusRatio':
          sessions.isEmpty ? 0.0 : completePomodoros / sessions.length,
    };
  }
}

extension TimePointPrediction on TimePoint {
  /// Returns the predicted end time if this is a resume point
  DateTime? get predictedEndTime {
    if (typ != TimePointTyp.resume) return null;

    // Get the current day's average session length or use default
    const averageSessionLength = Duration(minutes: 45);
    return dt.add(averageSessionLength);
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
