import 'package:flutter/foundation.dart';
import 'time_stamp.dart';

import '../../utils/dt_utils.dart';

class DayEntry {
  final DateTime dt;
  final TimeStamp durPoint;
  final List<TimeStamp> events;

  const DayEntry({
    required this.dt,
    required this.durPoint,
    required this.events,
  });

  // ADDED: Computed properties for convenience

  // Duration get lastEventDur => durPoint.dur;
  // bool get hasActivity => lastEventDur.inSeconds > 0;
  DateTime get startDt => DtHelper.dayStartDt(dt);
  DateTime get endDt => DtHelper.dayEndDt(dt);
  bool get isToday => _isSameDay(dt, DateTime.now());
  List<TimeStamp> get tps => List<TimeStamp>.from(events);

  Map<String, dynamic> toJson() {
    return {
      'lastUpdate': dt.toIso8601String(),
      'durPoint': durPoint.toJson(),
      'events': events.map((tp) => tp.toJson()).toList(),
    };
  }

  factory DayEntry.fromJson(Map<String, dynamic> json) {
    final durPoint = json['durPoint'] != null
        ? TimeStamp.fromJson(json['durPoint'])
        : TimeStamp(DateTime(1999, 3, 3), const Duration(), TPType.pause);

    return DayEntry(
      dt: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'])
          : durPoint.dt,
      durPoint: durPoint,
      events: json['events'] == null
          ? []
          : (json['events'] as List)
              .map((ts) => TimeStamp.fromJson(ts))
              .toList(),
    );
  }

  // IMPROVED: More comprehensive copyWith
  DayEntry copyWith({
    DateTime? dt,
    TimeStamp? durPoint,
    List<TimeStamp>? events,
  }) {
    return DayEntry(
      dt: dt ?? this.dt,
      durPoint: durPoint ?? this.durPoint,
      events: events != null
          ? List<TimeStamp>.from(events)
          : List<TimeStamp>.from(this.events),
    );
  }

  @override
  String toString() {
    return 'DayModel(${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}, ${events.length} events, ${durPoint.dur.inMinutes} mins)';
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

  /// Creates a corrected version of this day model
  DayEntry corrected() {
    // Ensure day starts at midnight
    final date = startDt;

    // Sort events by time
    List<TimeStamp> sortedEvents = List<TimeStamp>.from(events);
    if (sortedEvents.length > 1) {
      sortedEvents = sortedEvents..sort((a, b) => a.dt.compareTo(b.dt));
    }

    // Filter out events not on this day
    final filteredEvents =
        sortedEvents.where((e) => _isSameDay(e.dt, date)).toList();

    // Ensure day has start and end points
    final hasStartOfDay = filteredEvents.any(
      (e) =>
          e.dt.hour == 0 &&
          e.dt.minute == 0 &&
          e.dt.second == 0 &&
          e.dt.millisecond == 0,
    );

    if (!hasStartOfDay) {
      filteredEvents.insert(
        0,
        TimeStamp(date, Duration.zero, TPType.pause),
      );
    }
    final hasDayEnd = filteredEvents.any(
      (e) => e.dt.isAtSameMomentAs(DtHelper.dayEndDt(date)),
    );

    if (!isToday && !hasDayEnd) {
      filteredEvents.add(
        TimeStamp(
          DtHelper.dayEndDt(date),
          Duration.zero,
          TPType.pause,
        ),
      );
    }

    // Update durations for consistency
    TimeStamp? prev;
    final correctedEvents = <TimeStamp>[];

    for (int i = 0; i < filteredEvents.length; i++) {
      final event = filteredEvents[i];

      if (i == 0) {
        // First event always has zero duration
        correctedEvents.add(TimeStamp(event.dt, Duration.zero, event.typ));
        prev = correctedEvents.last;
      } else {
        // Calculate correct duration based on previous event
        final duration = prev!.typ == TPType.resume
            ? prev.dur + event.dt.difference(prev.dt)
            : prev.dur;

        correctedEvents.add(TimeStamp(event.dt, duration, event.typ));
      }
      prev = correctedEvents.last;
    }

    return DayEntry(
      dt: date,
      durPoint: correctedEvents.last,
      events: correctedEvents,
    );
  }
}

class DayRecordService {
  const DayRecordService._();

  // ADDED: Helper method for checking same day
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Adds a new active event to the day (toggles between pause/resume)
  /// Only works if the event is on the same day
  static DayEntry addActiveEvent({
    required DayEntry day,
    required DateTime dtAt,
  }) {
    // Ensure event is for the same day
    final sameDay = DayEntry._isSameDay(day.dt, dtAt);
    if (!sameDay) return day.copyWith();

    final events = List<TimeStamp>.from(day.events);
    final updatedEvents = TimeStampService.insertTimePoint(events, dtAt, true);

    return day.copyWith(
      durPoint: updatedEvents.last,
      events: updatedEvents,
    );
  }

  static DayEntry createDay(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final emptyPoint = TimeStamp(
      dayStart,
      Duration.zero,
      TPType.pause,
    );
    return DayEntry(dt: dayStart, durPoint: emptyPoint, events: [emptyPoint]);
  }

  /// Updates the duration at a specific time without creating a new event
  /// Used for progress updates during active tracking
  static DayEntry unactiveDtUpdate({
    required DayEntry day,
    required DateTime dtAt,
  }) {
    // Ensure update is for the same day
    final sameDay = _isSameDay(day.dt, dtAt);
    if (!sameDay) return day.copyWith();

    final events = List<TimeStamp>.from(day.events);
    final newPoint = TimeStampService.getEffectivePointAt(events, dtAt);

    return day.copyWith(
      durPoint: newPoint,
    );
  }

  /// Finalizes a day by adding an end-of-day timepoint
  /// Useful for completed days or when crossing to a new day
  static DayEntry endDay(DayEntry day) {
    final events = List<TimeStamp>.from(day.events);
    final dayEndDt = DtHelper.dayEndDt(day.dt);

    // Calculate the final duration at end of day
    final dur = TimeStampService.calculateDuration(dayEndDt, events);

    // Create the last timepoint of the day
    final last = TimeStamp(
      dayEndDt,
      dur,
      TPType.pause, // Always end with pause
    );

    events.add(last);

    return DayEntry(
      dt: DtHelper.dayStartDt(day.dt),
      durPoint: last,
      events: events,
    );
  }
}
