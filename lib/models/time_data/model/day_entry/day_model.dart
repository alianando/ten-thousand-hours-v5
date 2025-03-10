import '../time_point/time_point.dart';
import 'package:flutter/foundation.dart';

class DayEntry {
  final DateTime dt;
  final TimePoint durPoint;
  final List<TimePoint> events;

  const DayEntry({
    required this.dt,
    required this.durPoint,
    required this.events,
  });

  // ADDED: Computed properties for convenience
  Duration get totalDuration => durPoint.dur;
  bool get hasActivity => totalDuration.inSeconds > 0;
  DateTime get dayStart => DtHelper.dayStartDt(dt);
  DateTime get dayEnd => DtHelper.dayEndDt(dt);
  bool get isToday => _isSameDay(dt, DateTime.now());

  // ADDED: Session extraction
  List<(TimePoint, TimePoint, Duration)> get sessions {
    final result = <(TimePoint, TimePoint, Duration)>[];
    TimePoint? sessionStart;

    for (final event in events) {
      if (event.typ == TimePointTyp.resume) {
        sessionStart = event;
      } else if (event.typ == TimePointTyp.pause && sessionStart != null) {
        final duration = event.dt.difference(sessionStart.dt);
        result.add((sessionStart, event, duration));
        sessionStart = null;
      }
    }

    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'lastUpdate': dt.toIso8601String(),
      'durPoint': durPoint.toJson(),
      'events': events.map((tp) => tp.toJson()).toList(),
    };
  }

  factory DayEntry.fromJson(Map<String, dynamic> json) {
    final durPoint = json['durPoint'] != null
        ? TimePoint.fromJson(json['durPoint'])
        : TimePoint(
            dt: DateTime(1999, 3, 3),
            dur: const Duration(),
            typ: TimePointTyp.pause);

    return DayEntry(
      dt: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'])
          : durPoint.dt,
      durPoint: durPoint,
      events: json['events'] == null
          ? [durPoint]
          : (json['events'] as List)
              .map((tp) => TimePoint.fromJson(tp))
              .toList(),
    );
  }

  // IMPROVED: More comprehensive copyWith
  DayEntry copyWith({
    DateTime? dt,
    TimePoint? durPoint,
    List<TimePoint>? events,
  }) {
    return DayEntry(
      dt: dt ?? this.dt,
      durPoint: durPoint ?? this.durPoint,
      events: events != null
          ? List<TimePoint>.from(events)
          : List<TimePoint>.from(this.events),
    );
  }

  @override
  String toString() {
    return 'DayModel(${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}, ${events.length} events, ${totalDuration.inMinutes} mins)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayEntry &&
        _isSameDay(other.dt, dt) &&
        other.durPoint == durPoint &&
        listEquals(other.events, events);
  }

  @override
  int get hashCode => Object.hash(
        dt.year * 10000 + dt.month * 100 + dt.day, // Date-only hash
        durPoint,
        Object.hashAll(events),
      );

  // ADDED: Helper method for checking same day
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ADDED: Analytics methods
  Map<int, Duration> get hourlyDistribution {
    final distribution = <int, Duration>{};
    final sessionList = sessions;

    for (final session in sessionList) {
      final startHour = session.$1.dt.hour;
      final endHour = session.$2.dt.hour;
      final duration = session.$3;

      if (startHour == endHour) {
        distribution[startHour] =
            (distribution[startHour] ?? Duration.zero) + duration;
      } else {
        // Split duration across hours
        final startMinutes = 60 - session.$1.dt.minute;
        distribution[startHour] = (distribution[startHour] ?? Duration.zero) +
            Duration(minutes: startMinutes);

        for (int h = startHour + 1; h < endHour; h++) {
          distribution[h] =
              (distribution[h] ?? Duration.zero) + const Duration(minutes: 60);
        }

        distribution[endHour] = (distribution[endHour] ?? Duration.zero) +
            Duration(minutes: session.$2.dt.minute);
      }
    }

    return distribution;
  }

  int? get mostProductiveHour {
    if (!hasActivity) return null;

    final hours = hourlyDistribution;
    int? maxHour;
    Duration maxDuration = Duration.zero;

    hours.forEach((hour, duration) {
      if (duration > maxDuration) {
        maxHour = hour;
        maxDuration = duration;
      }
    });

    return maxHour;
  }

  // Helper methods for DayModelService

  /// Creates an empty day for a specific date
  static DayEntry createEmptyDay(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final emptyPoint = TimePoint(
      dt: dayStart,
      dur: Duration.zero,
      typ: TimePointTyp.pause,
    );
    return DayEntry(dt: dayStart, durPoint: emptyPoint, events: [emptyPoint]);
  }

  /// Merges two days that represent the same calendar day
  static DayEntry mergeDays(DayEntry day1, DayEntry day2) {
    if (!_isSameDay(day1.dt, day2.dt)) {
      throw ArgumentError('Cannot merge days from different dates');
    }

    // Combine events from both days
    final allEvents = [...day1.events, ...day2.events];

    // Sort by datetime
    allEvents.sort((a, b) => a.dt.compareTo(b.dt));

    // Remove duplicates (same exact time)
    final uniqueEvents = <TimePoint>[];
    TimePoint? lastEvent;

    for (final event in allEvents) {
      if (lastEvent == null || !event.dt.isAtSameMomentAs(lastEvent.dt)) {
        uniqueEvents.add(event);
        lastEvent = event;
      }
    }

    // Find the latest point to use as durPoint
    final latestPoint = uniqueEvents.reduce(
        (value, element) => value.dt.isAfter(element.dt) ? value : element);

    return DayEntry(
      dt: day1.dt,
      durPoint: latestPoint,
      events: uniqueEvents,
    );
  }

  /// Extracts activities into meaningful sessions
  static List<(DateTime start, DateTime end, Duration duration, String label)>
      extractNamedSessions(DayEntry day) {
    const minSessionDuration = Duration(minutes: 5);
    const breakThreshold = Duration(minutes: 15);

    final results = <(DateTime, DateTime, Duration, String)>[];
    final sessionPairs = day.sessions;

    // Group sessions that are close together
    DateTime? groupStart;
    DateTime groupEnd = DateTime(1970);
    Duration totalDuration = Duration.zero;

    for (final session in sessionPairs) {
      final start = session.$1.dt;
      final end = session.$2.dt;
      final duration = session.$3;

      // Skip very short sessions
      if (duration < minSessionDuration) continue;

      if (groupStart == null) {
        groupStart = start;
        groupEnd = end;
        totalDuration = duration;
      } else {
        // If this session starts soon after the previous ended, group them
        if (start.difference(groupEnd) <= breakThreshold) {
          groupEnd = end;
          totalDuration += duration;
        } else {
          // Save the previous group and start a new one
          final label =
              _generateSessionLabel(groupStart, groupEnd, totalDuration);
          results.add((groupStart, groupEnd, totalDuration, label));

          groupStart = start;
          groupEnd = end;
          totalDuration = duration;
        }
      }
    }

    // Add the last group if it exists
    if (groupStart != null) {
      final label = _generateSessionLabel(groupStart, groupEnd, totalDuration);
      results.add((groupStart, groupEnd, totalDuration, label));
    }

    return results;
  }

  /// Generates a descriptive label for a session
  static String _generateSessionLabel(
      DateTime start, DateTime end, Duration duration) {
    final hour = start.hour;
    String timeOfDay;

    if (hour >= 5 && hour < 12) {
      timeOfDay = "Morning";
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = "Afternoon";
    } else if (hour >= 17 && hour < 21) {
      timeOfDay = "Evening";
    } else {
      timeOfDay = "Night";
    }

    final minutes = duration.inMinutes;
    if (minutes >= 180) {
      // 3 hours or more
      return "Long $timeOfDay Session";
    } else if (minutes >= 90) {
      // 1.5-3 hours
      return "Medium $timeOfDay Session";
    } else {
      return "Short $timeOfDay Session";
    }
  }

  // Sorting comparison for days
  int compareTo(DayEntry other) {
    return dt.compareTo(other.dt);
  }

  /// Serializes to a CSV-like format for export
  String toCSV() {
    final buffer = StringBuffer();
    buffer.writeln('Date,${dt.toIso8601String()}');
    buffer.writeln('Total Duration,${totalDuration.inSeconds}');
    buffer.writeln('');
    buffer.writeln('Events:');
    buffer.writeln('Time,Type,Duration(sec)');

    for (final event in events) {
      final time = event.dt.toIso8601String();
      final type = event.typ.toString().split('.').last;
      final durationSec = event.dur.inSeconds;
      buffer.writeln('$time,$type,$durationSec');
    }

    return buffer.toString();
  }

  /// Creates an instance from CSV data
  factory DayEntry.fromCSV(String csv) {
    final lines = csv.split('\n');
    if (lines.length < 5) {
      throw const FormatException('Invalid CSV format');
    }

    final dateStr = lines[0].split(',')[1];
    final dt = DateTime.parse(dateStr);

    final events = <TimePoint>[];
    for (int i = 4; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length != 3) continue;

      try {
        final time = DateTime.parse(parts[0]);
        final typeStr = parts[1];
        final durationSec = int.parse(parts[2]);

        events.add(TimePoint(
          dt: time,
          dur: Duration(seconds: durationSec),
          typ: typeStr == 'resume' ? TimePointTyp.resume : TimePointTyp.pause,
        ));
      } catch (e) {
        // Skip invalid lines
      }
    }

    if (events.isEmpty) {
      throw const FormatException('No valid events found in CSV');
    }

    events.sort((a, b) => a.dt.compareTo(b.dt));
    return DayEntry(
      dt: dt,
      durPoint: events.last,
      events: events,
    );
  }

  /// Validates the consistency of the day model
  bool get isValid {
    if (events.isEmpty) return false;

    // Check if events are sorted
    for (int i = 1; i < events.length; i++) {
      if (events[i].dt.isBefore(events[i - 1].dt)) {
        return false;
      }
    }

    // Check if all events are on the same day
    for (final event in events) {
      if (!_isSameDay(event.dt, dt)) {
        return false;
      }
    }

    // Check if durPoint is consistent with the last event
    if (durPoint.dt.isAfter(events.last.dt)) {
      return false;
    }

    return true;
  }

  /// Creates a corrected version of this day model
  DayEntry corrected() {
    // Sort events by datetime
    final sortedEvents = List<TimePoint>.from(events)
      ..sort((a, b) => a.dt.compareTo(b.dt));

    // Filter out events not on this day
    final filteredEvents =
        sortedEvents.where((e) => _isSameDay(e.dt, dt)).toList();

    // Ensure there's at least one event
    if (filteredEvents.isEmpty) {
      final midnight = DateTime(dt.year, dt.month, dt.day);
      final defaultPoint =
          TimePoint(dt: midnight, dur: Duration.zero, typ: TimePointTyp.pause);
      filteredEvents.add(defaultPoint);
    }

    // Choose the latest event as durPoint
    TimePoint latestPoint = filteredEvents.last;

    return DayEntry(
      dt: DateTime(dt.year, dt.month, dt.day),
      durPoint: latestPoint,
      events: filteredEvents,
    );
  }
}
