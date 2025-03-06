import 'package:flutter/material.dart';
import 'dart:math' show max, min, pow, sqrt;

import '../time_point/time_point.dart';
import 'day_model.dart';

/// Service class for DayModel operations
class DayModelService {
  const DayModelService._();

  /// Creates a new day model for the specified datetime
  /// If the time is not midnight, adds both midnight and specified time points
  static DayModel createNewDay(DateTime at) {
    final dayDt = DtHelper.dayStartDt(at);

    // Create events list with appropriate starting points
    final events = <TimePoint>[];

    // Always add midnight point as the first event
    events.add(TimePoint(
      dt: dayDt,
      dur: Duration.zero,
      typ: TimePointTyp.pause,
    ));
    // if (!DtHelper.isDayStartDt(at)) {

    // }

    // Add the actual time point
    // events.add(TimePoint(
    //   dt: at,
    //   dur: Duration.zero,
    //   typ: TimePointTyp.pause,
    // ));

    return DayModel(
      dt: dayDt,
      durPoint: events.last,
      events: events,
    );
  }

  /// Finalizes a day by adding an end-of-day timepoint
  /// Useful for completed days or when crossing to a new day
  static DayModel endDay(DayModel day) {
    final events = List<TimePoint>.from(day.events);
    final dayEndDt = DtHelper.dayEndDt(day.dt);

    // Calculate the final duration at end of day
    final dur = TPService.calculateDuration(dayEndDt, events);

    // Create the last timepoint of the day
    final last = TimePoint(
      dt: dayEndDt,
      dur: dur,
      typ: TimePointTyp.pause, // Always end with pause
    );

    events.add(last);

    return DayModel(
      dt: DtHelper.dayStartDt(day.dt),
      durPoint: last,
      events: events,
    );
  }

  /// Adds a new active event to the day (toggles between pause/resume)
  /// Only works if the event is on the same day
  static DayModel addActiveEvent({
    required DayModel day,
    required DateTime dtAt,
  }) {
    // Ensure event is for the same day
    final sameDay = _checkSameDay(day.dt, dtAt);
    if (!sameDay) return day.copyWith();

    final events = List<TimePoint>.from(day.events);
    final updatedEvents = TPService.insertTimePoint(events, dtAt, true);

    return day.copyWith(
      durPoint: updatedEvents.last,
      events: updatedEvents,
    );
  }

  /// Updates the duration at a specific time without creating a new event
  /// Used for progress updates during active tracking
  static DayModel unactiveDtUpdate({
    required DayModel day,
    required DateTime dtAt,
  }) {
    // Ensure update is for the same day
    final sameDay = _checkSameDay(day.dt, dtAt);
    if (!sameDay) return day.copyWith();

    final events = List<TimePoint>.from(day.events);
    final newPoint = TPService.getEffectivePointAt(events, dtAt);

    return day.copyWith(
      durPoint: newPoint,
    );
  }

  /// Generates coordinates for visualization based on session times
  static List<Offset> updateCoordinates({
    required DayModel day,
    required DateTime timeAt,
    required DateTime sessionStartDt,
    required DateTime sessionEndDt,
    required Duration coordinateMaxDur,
    Duration coordinateMinDur = Duration.zero,
    bool isToday = false,
  }) {
    List<TimePoint> events = List.from(day.events);

    // Create points for coordinate calculation
    List<TimePoint> pointsForCo =
        TPService.insertTimePoint(events, sessionStartDt, false);

    // For today's view, use current time as endpoint; otherwise use session end
    if (isToday) {
      pointsForCo = TPService.insertTimePoint(pointsForCo, timeAt, false);
    } else {
      pointsForCo = TPService.insertTimePoint(pointsForCo, sessionEndDt, false);
    }

    // Generate coordinates for visualization
    final coordinates = TPService.generateCoordinates(
      timePoints: pointsForCo,
      sessionStartTime: sessionStartDt,
      sessionEndTime: sessionEndDt,
      maxSessionDur: coordinateMaxDur,
      minSessionDur: coordinateMinDur,
    );

    return coordinates;
  }

  /// ADDED: Merges two days that represent the same calendar day
  /// Useful when syncing data from different sources
  static DayModel mergeDays(DayModel day1, DayModel day2) {
    // Verify days are the same calendar day
    if (!_isSameDay(day1.dt, day2.dt)) {
      throw ArgumentError('Cannot merge days from different dates');
    }

    // Combine and deduplicate events
    final allEvents = [...day1.events, ...day2.events];
    allEvents.sort((a, b) => a.dt.compareTo(b.dt));

    final uniqueEvents = <TimePoint>[];
    TimePoint? lastEvent;

    for (final event in allEvents) {
      if (lastEvent == null || !event.dt.isAtSameMomentAs(lastEvent.dt)) {
        uniqueEvents.add(event);
        lastEvent = event;
      }
    }

    // Use the latest event as durPoint
    final latestPoint = uniqueEvents.isEmpty
        ? day1.durPoint
        : uniqueEvents.reduce(
            (value, element) => value.dt.isAfter(element.dt) ? value : element);

    // Merge coordinates by taking the more complete set
    // final mergedCoordinates = day1.coordinates.length > day2.coordinates.length
    //     ? day1.coordinates
    //     : day2.coordinates;

    return DayModel(
      dt: day1.dt,
      durPoint: latestPoint,
      events: uniqueEvents,
      // coordinates: mergedCoordinates,
    );
  }

  /// ADDED: Analyzes events to find productive sessions and patterns
  static Map<String, dynamic> analyzeDay(DayModel day) {
    if (day.events.isEmpty) {
      return {
        'totalDuration': Duration.zero,
        'sessionsCount': 0,
        'mostProductiveHour': null,
        'averageSessionLength': Duration.zero,
        'breakCount': 0,
        'timeDistribution': <int, double>{},
      };
    }

    // Extract sessions (periods between resume and pause)
    final sessions = day.sessions;

    // Calculate statistics
    final totalDuration = day.totalDuration;
    final sessionsCount = sessions.length;

    // Calculate average session length
    final averageSessionLength = sessions.isEmpty
        ? Duration.zero
        : Duration(
            microseconds:
                sessions.fold<int>(0, (sum, s) => sum + s.$3.inMicroseconds) ~/
                    max(1, sessions.length));

    // Calculate breaks between sessions
    final breaks = <Duration>[];
    for (int i = 1; i < sessions.length; i++) {
      final previousEnd = sessions[i - 1].$2.dt;
      final currentStart = sessions[i].$1.dt;
      breaks.add(currentStart.difference(previousEnd));
    }

    // Find most productive hour
    final hourlyWork = <int, Duration>{};
    for (final session in sessions) {
      final startHour = session.$1.dt.hour;
      final endHour = session.$2.dt.hour;
      final duration = session.$3;

      if (startHour == endHour) {
        hourlyWork[startHour] =
            (hourlyWork[startHour] ?? Duration.zero) + duration;
      } else {
        // Split across hours
        final startMinuteFraction = (60 - session.$1.dt.minute) / 60;
        final startHourDuration = Duration(
            milliseconds:
                (duration.inMilliseconds * startMinuteFraction).round());
        hourlyWork[startHour] =
            (hourlyWork[startHour] ?? Duration.zero) + startHourDuration;

        // Middle hours (if any)
        for (int h = startHour + 1; h < endHour; h++) {
          hourlyWork[h] =
              (hourlyWork[h] ?? Duration.zero) + const Duration(hours: 1);
        }

        // End hour
        final endMinuteFraction = session.$2.dt.minute / 60;
        final endHourDuration = Duration(
            milliseconds:
                (duration.inMilliseconds * endMinuteFraction).round());
        hourlyWork[endHour] =
            (hourlyWork[endHour] ?? Duration.zero) + endHourDuration;
      }
    }

    // Determine most productive hour
    int? mostProductiveHour;
    Duration maxDuration = Duration.zero;
    hourlyWork.forEach((hour, duration) {
      if (duration > maxDuration) {
        mostProductiveHour = hour;
        maxDuration = duration;
      }
    });

    // Calculate normalized time distribution (as percentage of total)
    final timeDistribution = <int, double>{};
    if (totalDuration.inMilliseconds > 0) {
      hourlyWork.forEach((hour, duration) {
        timeDistribution[hour] =
            duration.inMilliseconds / totalDuration.inMilliseconds;
      });
    }

    return {
      'totalDuration': totalDuration,
      'sessionsCount': sessionsCount,
      'mostProductiveHour': mostProductiveHour,
      'mostProductiveHourDuration': maxDuration,
      'averageSessionLength': averageSessionLength,
      'breakCount': breaks.length,
      'averageBreakLength': breaks.isEmpty
          ? Duration.zero
          : Duration(
              microseconds:
                  breaks.fold<int>(0, (sum, b) => sum + b.inMicroseconds) ~/
                      breaks.length),
      'timeDistribution': timeDistribution,
      'hasActivity': day.hasActivity,
      'startTime': day.events.first.dt,
      'endTime': day.events.last.dt,
    };
  }

  /// ADDED: Creates a corrected version of a day with consistent data
  static DayModel sanitize(DayModel day) {
    // Ensure day starts at midnight
    final date = DateTime(day.dt.year, day.dt.month, day.dt.day);

    // Sort events by time
    final sortedEvents = List<TimePoint>.from(day.events)
      ..sort((a, b) => a.dt.compareTo(b.dt));

    // Filter out events not on this day
    final filteredEvents =
        sortedEvents.where((e) => _isSameDay(e.dt, date)).toList();

    // If no events remain, create a default empty day
    if (filteredEvents.isEmpty) {
      return createNewDay(date);
    }

    // Ensure day has start and end points
    final hasStartOfDay =
        filteredEvents.any((e) => e.dt.hour == 0 && e.dt.minute == 0);

    if (!hasStartOfDay) {
      filteredEvents.insert(
          0,
          TimePoint(
            dt: date,
            dur: Duration.zero,
            typ: TimePointTyp.pause,
          ));
    }

    // Update durations for consistency
    TimePoint? prev;
    final correctedEvents = <TimePoint>[];

    for (int i = 0; i < filteredEvents.length; i++) {
      final event = filteredEvents[i];

      if (i == 0) {
        // First event always has zero duration
        correctedEvents.add(TimePoint(
          dt: event.dt,
          dur: Duration.zero,
          typ: event.typ,
        ));
      } else {
        // Calculate correct duration based on previous event
        final duration = prev!.typ == TimePointTyp.resume
            ? prev.dur + event.dt.difference(prev.dt)
            : prev.dur;

        correctedEvents.add(TimePoint(
          dt: event.dt,
          dur: duration,
          typ: event.typ,
        ));
      }
      prev = correctedEvents.last;
    }

    return DayModel(
      dt: date,
      durPoint: correctedEvents.last,
      events: correctedEvents,
    );
  }

  /// ADDED: Helper method to check if two dates represent the same day
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Helper to verify and log same day checks
  static bool _checkSameDay(DateTime dayDt, DateTime eventDt) {
    final sameDay = DtHelper.dayStartDt(eventDt).isAtSameMomentAs(
      DtHelper.dayStartDt(dayDt),
    );

    if (!sameDay) {
      debugPrint('## not same day ##');
      debugPrint('## ${DtHelper.dayStartDt(eventDt)} ##');
      debugPrint('## ${DtHelper.dayStartDt(dayDt)} ##');
    }

    return sameDay;
  }

  /// Identifies and categorizes work patterns based on time of day
  static Map<String, dynamic> analyzeWorkPatterns(DayModel day) {
    if (!day.hasActivity) {
      return {
        'pattern': 'No Activity',
        'consistency': 0.0,
        'peakTimes': <int>[],
      };
    }

    // Define time blocks
    const earlyMorning = [5, 6, 7, 8]; // 5am-9am
    const morning = [9, 10, 11, 12]; // 9am-1pm
    const afternoon = [13, 14, 15, 16]; // 1pm-5pm
    const evening = [17, 18, 19, 20]; // 5pm-9pm
    const night = [21, 22, 23, 0, 1, 2, 3, 4]; // 9pm-5am

    // Calculate activity in each time block
    final hourly = day.sessions.fold<Map<int, Duration>>({}, (map, session) {
      final startHour = session.$1.dt.hour;
      final endHour = session.$2.dt.hour;
      final duration = session.$3;

      if (startHour == endHour) {
        map[startHour] = (map[startHour] ?? Duration.zero) + duration;
      } else {
        // Distribute across hours
        final startMinuteFrac = (60 - session.$1.dt.minute) / 60;
        map[startHour] = (map[startHour] ?? Duration.zero) +
            Duration(
                milliseconds:
                    (duration.inMilliseconds * startMinuteFrac).round());

        for (int h = startHour + 1; h < endHour; h++) {
          map[h] = (map[h] ?? Duration.zero) + const Duration(hours: 1);
        }

        final endMinuteFrac = session.$2.dt.minute / 60;
        map[endHour] = (map[endHour] ?? Duration.zero) +
            Duration(
                milliseconds:
                    (duration.inMilliseconds * endMinuteFrac).round());
      }
      return map;
    });

    // Calculate durations in each time block
    final earlyMorningDur = earlyMorning.fold<Duration>(
        Duration.zero, (sum, hour) => sum + (hourly[hour] ?? Duration.zero));
    final morningDur = morning.fold<Duration>(
        Duration.zero, (sum, hour) => sum + (hourly[hour] ?? Duration.zero));
    final afternoonDur = afternoon.fold<Duration>(
        Duration.zero, (sum, hour) => sum + (hourly[hour] ?? Duration.zero));
    final eveningDur = evening.fold<Duration>(
        Duration.zero, (sum, hour) => sum + (hourly[hour] ?? Duration.zero));
    final nightDur = night.fold<Duration>(
        Duration.zero, (sum, hour) => sum + (hourly[hour] ?? Duration.zero));

    // Find the dominant pattern
    final durations = {
      'Early Bird': earlyMorningDur,
      'Morning Person': morningDur,
      'Afternoon Worker': afternoonDur,
      'Evening Person': eveningDur,
      'Night Owl': nightDur,
    };

    var pattern = 'Balanced';
    var maxDur = Duration.zero;
    durations.forEach((key, value) {
      if (value > maxDur) {
        maxDur = value;
        pattern = key;
      }
    });

    // Calculate how consistent the pattern is (as a percentage of total work)
    final totalDur = day.totalDuration;
    final consistency = totalDur.inMilliseconds > 0
        ? maxDur.inMilliseconds / totalDur.inMilliseconds
        : 0.0;

    // Identify peak working hours (top 2)
    final sortedHours = hourly.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peakHours = sortedHours.take(2).map((e) => e.key).toList();

    return {
      'pattern': pattern,
      'consistency': consistency,
      'peakTimes': peakHours,
      'distribution': {
        'earlyMorning': earlyMorningDur,
        'morning': morningDur,
        'afternoon': afternoonDur,
        'evening': eveningDur,
        'night': nightDur,
      }
    };
  }

  /// Calculates productivity metrics based on session frequency and length
  static Map<String, dynamic> calculateProductivityMetrics(DayModel day) {
    if (!day.hasActivity) {
      return {
        'productivityScore': 0.0,
        'focusScore': 0.0,
        'consistencyScore': 0.0,
      };
    }

    final sessions = day.sessions;

    // No sessions means no metrics
    if (sessions.isEmpty) {
      return {
        'productivityScore': 0.0,
        'focusScore': 0.0,
        'consistencyScore': 0.0,
      };
    }

    // Calculate focus score based on session lengths
    // Longer sessions indicate better focus (up to 2 hours, after which effectiveness diminishes)
    double calculateFocusScore(
        List<(TimePoint, TimePoint, Duration)> sessions) {
      if (sessions.isEmpty) return 0.0;

      double score = 0.0;
      for (final session in sessions) {
        final durationMinutes = session.$3.inMinutes;
        // Score increases up to 120 minutes per session, then plateaus
        if (durationMinutes <= 120) {
          score += durationMinutes / 120;
        } else {
          score += 1.0; // Full score for sessions over 2 hours
        }
      }

      // Normalize by number of sessions with a diminishing return factor
      return score / sqrt(sessions.length);
    }

    // Calculate consistency score based on how evenly spaced sessions are
    double calculateConsistencyScore(
        List<(TimePoint, TimePoint, Duration)> sessions) {
      if (sessions.length < 2)
        return 1.0; // Only one session is perfectly consistent

      final intervals = <Duration>[];
      for (int i = 1; i < sessions.length; i++) {
        intervals.add(sessions[i].$1.dt.difference(sessions[i - 1].$2.dt));
      }

      // Calculate standard deviation of intervals
      final meanInterval = intervals.fold<Duration>(
              Duration.zero, (sum, interval) => sum + interval) ~/
          intervals.length;

      final varianceSum = intervals.fold<int>(
          0,
          (sum, interval) =>
              sum +
              pow(interval.inMinutes - meanInterval.inMinutes, 2).round());

      final stdDev = sqrt(varianceSum / intervals.length);

      // Lower stdDev means more consistent spacing of sessions
      // Map to a 0-1 score (1 = perfectly consistent)
      const maxStdDev =
          240; // 4 hours standard deviation is considered maximum inconsistency
      return max(0.0, 1.0 - stdDev / maxStdDev);
    }

    // Calculate productivity score based on total time and session count
    double calculateProductivityScore(
        Duration totalDuration, int sessionCount) {
      // Base score on total duration (max score at 8 hours)
      final durationScore = min(totalDuration.inMinutes / 480, 1.0);

      // Session count factor (diminishing returns after 4 sessions)
      final sessionFactor = sessionCount >= 4 ? 1.0 : sessionCount / 4;

      return durationScore * 0.7 + sessionFactor * 0.3;
    }

    final focusScore = calculateFocusScore(sessions);
    final consistencyScore = calculateConsistencyScore(sessions);
    final productivityScore =
        calculateProductivityScore(day.totalDuration, sessions.length);

    return {
      'productivityScore': productivityScore.clamp(0.0, 1.0),
      'focusScore': focusScore.clamp(0.0, 1.0),
      'consistencyScore': consistencyScore,
      'sessionCount': sessions.length,
      'totalDuration': day.totalDuration,
    };
  }

  /// Detects potential tracking errors or anomalies in the data
  static List<Map<String, dynamic>> detectDataAnomalies(DayModel day) {
    final anomalies = <Map<String, dynamic>>[];
    final events = day.events;

    // Check for extremely short sessions (less than 30 seconds)
    for (int i = 1; i < events.length; i++) {
      if (events[i - 1].typ == TimePointTyp.resume &&
          events[i].typ == TimePointTyp.pause) {
        final sessionDuration = events[i].dt.difference(events[i - 1].dt);
        if (sessionDuration.inSeconds < 30) {
          anomalies.add({
            'type': 'VeryShortSession',
            'startTime': events[i - 1].dt,
            'endTime': events[i].dt,
            'duration': sessionDuration,
            'message': 'Very short session detected (less than 30 seconds)',
          });
        }
      }
    }

    // Check for unusually long sessions (more than 4 hours without breaks)
    for (int i = 1; i < events.length; i++) {
      if (events[i - 1].typ == TimePointTyp.resume &&
          events[i].typ == TimePointTyp.pause) {
        final sessionDuration = events[i].dt.difference(events[i - 1].dt);
        if (sessionDuration.inHours >= 4) {
          anomalies.add({
            'type': 'VeryLongSession',
            'startTime': events[i - 1].dt,
            'endTime': events[i].dt,
            'duration': sessionDuration,
            'message':
                'Unusually long session without breaks (${sessionDuration.inHours} hours)',
          });
        }
      }
    }

    // Check for type inconsistency (consecutive resume or pause events)
    for (int i = 1; i < events.length; i++) {
      if (events[i].typ == events[i - 1].typ) {
        anomalies.add({
          'type': 'InconsistentEventSequence',
          'event1': events[i - 1].dt,
          'event2': events[i].dt,
          'eventType': events[i].typ.toString().split('.').last,
          'message':
              'Consecutive ${events[i].typ.toString().split('.').last} events detected',
        });
      }
    }

    // Check for large gaps between events during active day
    if (events.length > 2) {
      final activeHours = day.events.map((e) => e.dt.hour).toSet().length;

      // If the day spans more than 6 hours but has few events
      if (activeHours >= 6 && events.length < 5) {
        anomalies.add({
          'type': 'LargeEventGaps',
          'eventCount': events.length,
          'activeHours': activeHours,
          'message':
              'Day spans $activeHours hours but has only ${events.length} events',
        });
      }
    }

    return anomalies;
  }

  /// Creates a condensed summary of a day suitable for display
  static Map<String, dynamic> createDaySummary(DayModel day) {
    final sessions = day.sessions;
    final totalDur = day.totalDuration;

    // Format active hours as a range string
    String getActiveHoursRange() {
      if (!day.hasActivity) return "No activity";

      final startHour = day.events.first.dt.hour;
      final endHour = day.events.last.dt.hour;

      final startAmPm = startHour < 12 ? 'AM' : 'PM';
      final endAmPm = endHour < 12 ? 'AM' : 'PM';

      final formattedStart = startHour % 12 == 0 ? '12' : '${startHour % 12}';
      final formattedEnd = endHour % 12 == 0 ? '12' : '${endHour % 12}';

      return '$formattedStart$startAmPm - $formattedEnd$endAmPm';
    }

    // Get the longest session
    (TimePoint, TimePoint, Duration)? longestSession;
    for (final session in sessions) {
      if (longestSession == null || session.$3 > longestSession.$3) {
        longestSession = session;
      }
    }

    // Group sessions by time of day
    int morningCount = 0; // 5am-12pm
    int afternoonCount = 0; // 12pm-5pm
    int eveningCount = 0; // 5pm-9pm
    int nightCount = 0; // 9pm-5am

    for (final session in sessions) {
      final hour = session.$1.dt.hour;

      if (hour >= 5 && hour < 12) {
        morningCount++;
      } else if (hour >= 12 && hour < 17) {
        afternoonCount++;
      } else if (hour >= 17 && hour < 21) {
        eveningCount++;
      } else {
        nightCount++;
      }
    }

    // Determine the most active period
    String mostActivePeriod = 'None';
    int maxCount = 0;

    if (morningCount > maxCount) {
      maxCount = morningCount;
      mostActivePeriod = 'Morning';
    }
    if (afternoonCount > maxCount) {
      maxCount = afternoonCount;
      mostActivePeriod = 'Afternoon';
    }
    if (eveningCount > maxCount) {
      maxCount = eveningCount;
      mostActivePeriod = 'Evening';
    }
    if (nightCount > maxCount) {
      mostActivePeriod = 'Night';
    }

    return {
      'date': day.dt,
      'totalHours': totalDur.inMinutes / 60,
      'sessionCount': sessions.length,
      'activeHoursRange': getActiveHoursRange(),
      'longestSession': longestSession == null
          ? null
          : {
              'startTime': longestSession.$1.dt,
              'endTime': longestSession.$2.dt,
              'durationMinutes': longestSession.$3.inMinutes,
            },
      'mostActivePeriod': mostActivePeriod,
      'dayOfWeek': day.dt.weekday, // 1 = Monday, 7 = Sunday
    };
  }

  /// Creates a condensed summary of a day suitable for display
  static String formatDurationForDisplay(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }

  /// Calculate progress towards goal for a specific day
  static double calculateGoalProgress(DayModel day, Duration dailyGoal) {
    if (dailyGoal.inSeconds == 0) return 0.0;
    return day.totalDuration.inSeconds / dailyGoal.inSeconds;
  }

  /// Extract tags or categories from day data
  /// This is a placeholder - in a full implementation, you'd need to
  /// have tags associated with time entries
  static List<String> extractTags(DayModel day) {
    // This is where you'd implement tag extraction based on your data model
    // For now, we'll return placeholder data

    final result = <String>[];

    // Example: Tag based on time of day
    final morningHours = day.sessions
        .where((s) => s.$1.dt.hour >= 5 && s.$1.dt.hour < 12)
        .length;
    final afternoonHours = day.sessions
        .where((s) => s.$1.dt.hour >= 12 && s.$1.dt.hour < 17)
        .length;
    final eveningHours = day.sessions
        .where((s) => s.$1.dt.hour >= 17 && s.$1.dt.hour < 21)
        .length;
    final nightHours = day.sessions
        .where((s) => s.$1.dt.hour >= 21 || s.$1.dt.hour < 5)
        .length;

    if (morningHours > 0) result.add('Morning');
    if (afternoonHours > 0) result.add('Afternoon');
    if (eveningHours > 0) result.add('Evening');
    if (nightHours > 0) result.add('Night');

    // Example: Tag based on session length
    final hasLongSessions = day.sessions.any((s) => s.$3.inMinutes > 90);
    final hasShortSessions = day.sessions.any((s) => s.$3.inMinutes < 15);

    if (hasLongSessions) result.add('Long Sessions');
    if (hasShortSessions) result.add('Short Sessions');

    // Example: Tag based on consistency
    final consistency = day.sessions.length >= 3;
    if (consistency) result.add('Consistent');

    return result;
  }

  /// Compare two days and return the differences
  static Map<String, dynamic> compareDays(DayModel day1, DayModel day2) {
    final day1Duration = day1.totalDuration;
    final day2Duration = day2.totalDuration;

    final durationDiff = day2Duration - day1Duration;
    final percentChange = day1Duration.inSeconds > 0
        ? (day2Duration.inSeconds - day1Duration.inSeconds) /
            day1Duration.inSeconds *
            100
        : double.infinity;

    final day1Sessions = day1.sessions.length;
    final day2Sessions = day2.sessions.length;

    final day1AvgSession =
        day1Sessions > 0 ? day1Duration ~/ day1Sessions : Duration.zero;

    final day2AvgSession =
        day2Sessions > 0 ? day2Duration ~/ day2Sessions : Duration.zero;

    return {
      'durationDifference': durationDiff,
      'percentChange': percentChange == double.infinity ? null : percentChange,
      'sessionCountChange': day2Sessions - day1Sessions,
      'averageSessionDurationChange': day2AvgSession - day1AvgSession,
      'day1Date': day1.dt,
      'day2Date': day2.dt,
      'improved': day2Duration > day1Duration,
    };
  }

  /// Analyzes multiple days to find optimal work patterns
  static Map<String, dynamic> analyzeOptimalWorkPatterns(List<DayModel> days) {
    // Filter to days with significant activity (more than 30 minutes)
    final activeDays =
        days.where((day) => day.totalDuration.inMinutes > 30).toList();
    if (activeDays.isEmpty) {
      return {
        'optimalStartTime': null,
        'optimalDuration': null,
        'mostProductiveDayOfWeek': null,
        'suggestions': ['Not enough data to analyze optimal patterns'],
      };
    }

    // Track productivity by start hour
    final hourlyProductivity = <int, List<double>>{};
    final dayOfWeekProductivity = <int, List<double>>{};
    final durationProductivity = <int, List<double>>{};

    // Calculate productivity score for each day (normalized 0-1)
    for (final day in activeDays) {
      final metrics = calculateProductivityMetrics(day);
      final productivityScore = metrics['productivityScore'] as double;
      final sessions = day.sessions;

      // Skip days with incomplete data
      if (sessions.isEmpty) continue;

      // Associate productivity with start hour
      final startHour = sessions.first.$1.dt.hour;
      if (!hourlyProductivity.containsKey(startHour)) {
        hourlyProductivity[startHour] = [];
      }
      hourlyProductivity[startHour]!.add(productivityScore);

      // Associate productivity with day of week
      final dayOfWeek = day.dt.weekday; // 1 = Monday, 7 = Sunday
      if (!dayOfWeekProductivity.containsKey(dayOfWeek)) {
        dayOfWeekProductivity[dayOfWeek] = [];
      }
      dayOfWeekProductivity[dayOfWeek]!.add(productivityScore);

      // Associate productivity with duration (rounded to nearest hour)
      final durationHours = (day.totalDuration.inMinutes / 60).round();
      if (durationHours > 0) {
        if (!durationProductivity.containsKey(durationHours)) {
          durationProductivity[durationHours] = [];
        }
        durationProductivity[durationHours]!.add(productivityScore);
      }
    }

    // Find optimal start time
    int? optimalStartHour;
    double maxStartHourScore = 0;
    hourlyProductivity.forEach((hour, scores) {
      if (scores.length >= 3) {
        // Require at least 3 data points
        final avgScore = scores.reduce((a, b) => a + b) / scores.length;
        if (avgScore > maxStartHourScore) {
          maxStartHourScore = avgScore;
          optimalStartHour = hour;
        }
      }
    });

    // Find most productive day of week
    int? mostProductiveDayOfWeek;
    double maxDayOfWeekScore = 0;
    dayOfWeekProductivity.forEach((dayOfWeek, scores) {
      if (scores.length >= 2) {
        // Require at least 2 data points
        final avgScore = scores.reduce((a, b) => a + b) / scores.length;
        if (avgScore > maxDayOfWeekScore) {
          maxDayOfWeekScore = avgScore;
          mostProductiveDayOfWeek = dayOfWeek;
        }
      }
    });

    // Find optimal duration
    int? optimalDurationHours;
    double maxDurationScore = 0;
    durationProductivity.forEach((duration, scores) {
      if (scores.length >= 3) {
        // Require at least 3 data points
        final avgScore = scores.reduce((a, b) => a + b) / scores.length;
        if (avgScore > maxDurationScore) {
          maxDurationScore = avgScore;
          optimalDurationHours = duration;
        }
      }
    });

    // Generate suggestions based on findings
    final suggestions = <String>[];

    if (optimalStartHour != null) {
      final amPm = optimalStartHour! < 12 ? 'AM' : 'PM';
      final hour12 = optimalStartHour! % 12 == 0 ? 12 : optimalStartHour! % 12;
      suggestions.add(
          'Try starting your day around $hour12 $amPm for optimal productivity');
    }

    if (optimalDurationHours != null) {
      suggestions.add(
          'Your productivity peaks with ~$optimalDurationHours hour${optimalDurationHours == 1 ? '' : 's'} of work');
    }

    if (mostProductiveDayOfWeek != null) {
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      suggestions.add(
          '${days[mostProductiveDayOfWeek! - 1]} tends to be your most productive day');
    }

    // Find if morning or afternoon sessions are more productive
    final morningSessions = activeDays
        .expand((day) => day.sessions)
        .where((s) => s.$1.dt.hour < 12)
        .map((s) => s.$3.inMinutes / 60)
        .toList();

    final afternoonSessions = activeDays
        .expand((day) => day.sessions)
        .where((s) => s.$1.dt.hour >= 12)
        .map((s) => s.$3.inMinutes / 60)
        .toList();

    if (morningSessions.length >= 5 && afternoonSessions.length >= 5) {
      final morningAvg =
          morningSessions.reduce((a, b) => a + b) / morningSessions.length;
      final afternoonAvg =
          afternoonSessions.reduce((a, b) => a + b) / afternoonSessions.length;

      if (morningAvg > afternoonAvg * 1.2) {
        suggestions.add(
            'Your morning sessions are notably more productive than afternoon sessions');
      } else if (afternoonAvg > morningAvg * 1.2) {
        suggestions.add(
            'Your afternoon sessions are notably more productive than morning sessions');
      }
    }

    return {
      'optimalStartTime': optimalStartHour,
      'optimalDuration': optimalDurationHours != null
          ? Duration(hours: optimalDurationHours!)
          : null,
      'mostProductiveDayOfWeek': mostProductiveDayOfWeek,
      'suggestions': suggestions,
    };
  }

  /// Forecasts expected progress based on historical data
  static Map<String, dynamic> forecastProgress(
      List<DayModel> historicalDays, int forecastDays, Duration targetHours) {
    if (historicalDays.isEmpty) {
      return {
        'projectedCompletionDate': null,
        'daysRequired': null,
        'averageDailyProgress': Duration.zero,
        'confidence': 0.0,
      };
    }

    // Sort days by date
    final sortedDays = List<DayModel>.from(historicalDays)
      ..sort((a, b) => a.dt.compareTo(b.dt));

    // Calculate average daily duration over the last 7 days or available days
    final recentDaysCount = min(7, sortedDays.length);
    final recentDays = sortedDays.sublist(sortedDays.length - recentDaysCount);

    final totalRecentDuration = recentDays.fold<Duration>(
        Duration.zero, (sum, day) => sum + day.totalDuration);

    final averageDailyDuration = recentDaysCount > 0
        ? Duration(
            microseconds: totalRecentDuration.inMicroseconds ~/ recentDaysCount)
        : Duration.zero;

    // Calculate total accumulated duration
    final totalAccumulatedDuration = sortedDays.fold<Duration>(
        Duration.zero, (sum, day) => sum + day.totalDuration);

    // Calculate remaining duration
    final remainingDuration = targetHours - totalAccumulatedDuration;

    // Skip calculation if already achieved or no recent progress
    if (remainingDuration.inSeconds <= 0) {
      return {
        'projectedCompletionDate': DateTime.now(),
        'daysRequired': 0,
        'averageDailyProgress': averageDailyDuration,
        'confidence': 1.0,
        'percentComplete': 100.0,
        'isCompleted': true,
      };
    }

    if (averageDailyDuration.inSeconds <= 0) {
      return {
        'projectedCompletionDate': null,
        'daysRequired': null,
        'averageDailyProgress': Duration.zero,
        'confidence': 0.0,
        'percentComplete':
            (totalAccumulatedDuration.inSeconds / targetHours.inSeconds * 100)
                .clamp(0, 100),
        'isCompleted': false,
      };
    }

    // Calculate days required to reach target
    final daysRequired =
        (remainingDuration.inSeconds / averageDailyDuration.inSeconds).ceil();

    // Calculate projected completion date
    final today = DateTime.now();
    final projectedCompletionDate =
        DateTime(today.year, today.month, today.day + daysRequired);

    // Calculate confidence based on consistency
    double calculateConfidence() {
      if (recentDaysCount < 3)
        return 0.4; // Low confidence with few data points

      // Calculate coefficient of variation to measure consistency
      final durations =
          recentDays.map((d) => d.totalDuration.inMinutes).toList();
      final mean = durations.reduce((a, b) => a + b) / durations.length;

      if (mean == 0) return 0.0;

      final variance = durations.fold<double>(
              0, (sum, duration) => sum + pow(duration - mean, 2)) /
          durations.length;

      final stdDev = sqrt(variance);
      final coeffOfVariation = stdDev / mean;

      // Lower coefficient means higher consistency
      // Map to a 0-1 confidence score (1 = high confidence)
      return max(0.3, min(0.95, 1 - coeffOfVariation * 0.5));
    }

    final confidence = calculateConfidence();

    return {
      'projectedCompletionDate': projectedCompletionDate,
      'daysRequired': daysRequired,
      'averageDailyProgress': averageDailyDuration,
      'confidence': confidence,
      'percentComplete':
          (totalAccumulatedDuration.inSeconds / targetHours.inSeconds * 100)
              .clamp(0, 100),
      'isCompleted': false,
    };
  }

  /// Segments the day into focused work blocks (pomodoro-style analysis)
  static List<Map<String, dynamic>> identifyWorkBlocks(DayModel day) {
    final workBlocks = <Map<String, dynamic>>[];
    final sessions = day.sessions;

    if (sessions.isEmpty) return workBlocks;

    // Group sessions that are close together into work blocks
    const breakThreshold =
        Duration(minutes: 30); // Max break between sessions in same block

    TimePoint? blockStart;
    TimePoint? lastEnd;
    List<(TimePoint, TimePoint, Duration)> blockSessions = [];

    for (final session in sessions) {
      // If this is the first session or if the break is short enough
      if (blockStart == null ||
          session.$1.dt.difference(lastEnd!.dt) <= breakThreshold) {
        // Start a new block or add to existing
        blockStart ??= session.$1;
        lastEnd = session.$2;
        blockSessions.add(session);
      } else {
        // Break is too long, finish current block and start new one
        final blockDuration = lastEnd!.dt.difference(blockStart.dt);
        final totalSessionTime =
            blockSessions.fold<Duration>(Duration.zero, (sum, s) => sum + s.$3);

        workBlocks.add({
          'startTime': blockStart.dt,
          'endTime': lastEnd.dt,
          'totalDuration': blockDuration,
          'activeDuration': totalSessionTime,
          'sessionCount': blockSessions.length,
          'efficiency':
              totalSessionTime.inSeconds / max(1, blockDuration.inSeconds),
          'sessions': blockSessions,
        });

        // Start new block
        blockStart = session.$1;
        lastEnd = session.$2;
        blockSessions = [session];
      }
    }

    // Add the final block if it exists
    if (blockStart != null) {
      final blockDuration = lastEnd!.dt.difference(blockStart.dt);
      final totalSessionTime =
          blockSessions.fold<Duration>(Duration.zero, (sum, s) => sum + s.$3);

      workBlocks.add({
        'startTime': blockStart.dt,
        'endTime': lastEnd!.dt,
        'totalDuration': blockDuration,
        'activeDuration': totalSessionTime,
        'sessionCount': blockSessions.length,
        'efficiency':
            totalSessionTime.inSeconds / max(1, blockDuration.inSeconds),
        'sessions': blockSessions,
      });
    }

    // Add descriptive labels for each work block
    for (final block in workBlocks) {
      // Label based on time of day
      final hour = (block['startTime'] as DateTime).hour;
      String timeOfDay = '';

      if (hour >= 5 && hour < 12) {
        timeOfDay = 'Morning';
      } else if (hour >= 12 && hour < 17) {
        timeOfDay = 'Afternoon';
      } else if (hour >= 17 && hour < 21) {
        timeOfDay = 'Evening';
      } else {
        timeOfDay = 'Night';
      }

      // Label based on duration
      final durationMin = (block['totalDuration'] as Duration).inMinutes;
      String durationLabel = '';

      if (durationMin < 30) {
        durationLabel = 'Quick';
      } else if (durationMin < 90) {
        durationLabel = 'Medium';
      } else {
        durationLabel = 'Extended';
      }

      // Label based on efficiency
      final efficiency = block['efficiency'] as double;
      String focusLabel = '';

      if (efficiency > 0.9) {
        focusLabel = 'Highly Focused';
      } else if (efficiency > 0.7) {
        focusLabel = 'Focused';
      } else if (efficiency > 0.5) {
        focusLabel = 'Moderate Focus';
      } else {
        focusLabel = 'Distracted';
      }

      block['label'] = '$durationLabel $timeOfDay Work ($focusLabel)';
    }

    return workBlocks;
  }

  /// Provides streak-based gamification metrics
  static Map<String, dynamic> calculateStreaks(List<DayModel> allDays) {
    if (allDays.isEmpty) {
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'totalActiveDays': 0,
        'lastActiveDate': null,
      };
    }

    // Sort days chronologically
    final sortedDays = List<DayModel>.from(allDays)
      ..sort((a, b) => a.dt.compareTo(b.dt));

    // Find days with meaningful activity (more than 10 minutes)
    final activeDayDates = sortedDays
        .where((day) => day.totalDuration.inMinutes > 10)
        .map((day) => DateTime(day.dt.year, day.dt.month, day.dt.day))
        .toSet();

    if (activeDayDates.isEmpty) {
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'totalActiveDays': 0,
        'lastActiveDate': null,
      };
    }

    // Calculate current streak
    int currentStreak = 0;
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    DateTime checkDate = today;

    while (activeDayDates.contains(checkDate)) {
      currentStreak++;
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
    }

    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 0;

    final allDates = activeDayDates.toList()..sort();

    for (int i = 0; i < allDates.length; i++) {
      if (i == 0) {
        tempStreak = 1;
        longestStreak = 1;
      } else {
        final previousDate = allDates[i - 1];
        final currentDate = allDates[i];

        final difference = currentDate.difference(previousDate).inDays;

        if (difference == 1) {
          // Consecutive day
          tempStreak++;
          longestStreak = max(longestStreak, tempStreak);
        } else if (difference > 1) {
          // Streak broken
          tempStreak = 1;
        }
      }
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalActiveDays': activeDayDates.length,
      'lastActiveDate': activeDayDates.reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }

  /// Categorize sessions by length to identify patterns
  static Map<String, dynamic> analyzeSessionDistribution(DayModel day) {
    final sessions = day.sessions;
    if (sessions.isEmpty) {
      return {
        'veryShort': 0,
        'short': 0,
        'medium': 0,
        'long': 0,
        'veryLong': 0,
        'total': 0,
        'mostCommonType': 'None',
      };
    }

    int veryShort = 0; // < 5 mins
    int short = 0; // 5-15 mins
    int medium = 0; // 15-45 mins
    int long = 0; // 45-120 mins
    int veryLong = 0; // > 120 mins

    for (final session in sessions) {
      final durationMins = session.$3.inMinutes;

      if (durationMins < 5) {
        veryShort++;
      } else if (durationMins < 15) {
        short++;
      } else if (durationMins < 45) {
        medium++;
      } else if (durationMins < 120) {
        long++;
      } else {
        veryLong++;
      }
    }

    // Determine most common session type
    final typeCount = {
      'Very Short': veryShort,
      'Short': short,
      'Medium': medium,
      'Long': long,
      'Very Long': veryLong,
    };

    String mostCommonType = 'None';
    int maxCount = 0;

    typeCount.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonType = type;
      }
    });

    // Calculate percentages
    final total = sessions.length;
    final percentages = {
      'veryShortPercent': total > 0 ? (veryShort / total * 100).round() : 0,
      'shortPercent': total > 0 ? (short / total * 100).round() : 0,
      'mediumPercent': total > 0 ? (medium / total * 100).round() : 0,
      'longPercent': total > 0 ? (long / total * 100).round() : 0,
      'veryLongPercent': total > 0 ? (veryLong / total * 100).round() : 0,
    };

    return {
      'veryShort': veryShort,
      'short': short,
      'medium': medium,
      'long': long,
      'veryLong': veryLong,
      'total': total,
      'mostCommonType': mostCommonType,
      'percentages': percentages,
    };
  }

  /// Export day data to various formats
  static String exportToCsv(DayModel day) {
    final buffer = StringBuffer();

    // Write header
    buffer.writeln(
        'Date,${day.dt.year}-${day.dt.month.toString().padLeft(2, '0')}-${day.dt.day.toString().padLeft(2, '0')}');
    buffer.writeln('Total Duration (min),${day.totalDuration.inMinutes}');
    buffer.writeln();

    // Write events
    buffer.writeln('Events:');
    buffer.writeln('Time,Type,Duration (min),Total Duration (min)');

    for (final event in day.events) {
      final time =
          '${event.dt.hour.toString().padLeft(2, '0')}:${event.dt.minute.toString().padLeft(2, '0')}:${event.dt.second.toString().padLeft(2, '0')}';
      final type = event.typ.toString().split('.').last;
      buffer.writeln('$time,$type,${event.dur.inMinutes}');
    }

    buffer.writeln();

    // Write sessions
    buffer.writeln('Sessions:');
    buffer.writeln('Start Time,End Time,Duration (min)');

    for (final session in day.sessions) {
      final startTime =
          '${session.$1.dt.hour.toString().padLeft(2, '0')}:${session.$1.dt.minute.toString().padLeft(2, '0')}';
      final endTime =
          '${session.$2.dt.hour.toString().padLeft(2, '0')}:${session.$2.dt.minute.toString().padLeft(2, '0')}';
      final duration = session.$3.inMinutes;

      buffer.writeln('$startTime,$endTime,$duration');
    }

    return buffer.toString();
  }

  /// Calculate time spent per hour of day (useful for heatmaps)
  static Map<int, Duration> calculateHourlyDistribution(DayModel day) {
    final hourlyDistribution = <int, Duration>{};

    for (int hour = 0; hour < 24; hour++) {
      hourlyDistribution[hour] = Duration.zero;
    }

    for (final session in day.sessions) {
      final startHour = session.$1.dt.hour;
      final endHour = session.$2.dt.hour;
      final duration = session.$3;

      if (startHour == endHour) {
        hourlyDistribution[startHour] =
            (hourlyDistribution[startHour] ?? Duration.zero) + duration;
      } else {
        // Split duration across hours
        final startMinutes = 60 - session.$1.dt.minute;
        final startDuration = Duration(minutes: startMinutes);
        hourlyDistribution[startHour] =
            (hourlyDistribution[startHour] ?? Duration.zero) + startDuration;

        // Full hours in between
        for (int h = startHour + 1; h < endHour; h++) {
          hourlyDistribution[h] = (hourlyDistribution[h] ?? Duration.zero) +
              const Duration(hours: 1);
        }

        // End hour
        final endMinutes = session.$2.dt.minute;
        final endDuration = Duration(minutes: endMinutes);
        hourlyDistribution[endHour] =
            (hourlyDistribution[endHour] ?? Duration.zero) + endDuration;
      }
    }

    return hourlyDistribution;
  }
}
