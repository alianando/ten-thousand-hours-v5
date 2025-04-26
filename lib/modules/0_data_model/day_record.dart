import 'package:flutter/foundation.dart';
import 'time_stamp.dart';

import '../../utils/dt_utils.dart';

class DayEntry {
  final DateTime dt;
  final List<TimeStamp> events;

  const DayEntry({required this.dt, required this.events});

  // ADDED: Computed properties for convenience

  // Duration get lastEventDur => durPoint.dur;
  // bool get hasActivity => lastEventDur.inSeconds > 0;
  DateTime get startDt => DtHelper.dayStartDt(dt);
  DateTime get endDt => DtHelper.dayEndDt(dt);
  bool get isToday => _isSameDay(dt, DateTime.now());
  List<TimeStamp> get timeStapms => List<TimeStamp>.from(events);
  TimeStamp get lastTimeStapm => events.last;
  bool get isActive => events.isNotEmpty && events.last.typ == TPType.resume;
  DateTime get lastRecordedDt {
    if (events.isEmpty) return DateTime(1999, 3, 3);
    return events.last.dt;
  }

  Duration get lastRecordedDur {
    if (events.isEmpty) return const Duration();
    return events.last.duration;
  }

  Map<String, dynamic> toJson() {
    return {
      'lastUpdate': dt.toIso8601String(),
      'events': events.map((tp) => tp.toJson()).toList(),
    };
  }

  factory DayEntry.fromJson(Map<String, dynamic> json) {
    return DayEntry(
      dt: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'])
          : DateTime(1999, 3, 3),
      events: json['events'] == null
          ? []
          : (json['events'] as List)
              .map((ts) => TimeStamp.fromJson(ts))
              .toList(),
    );
  }

  DayEntry copyWith({
    DateTime? dt,
    List<TimeStamp>? events,
  }) {
    return DayEntry(
      dt: dt ?? this.dt,
      events: events != null
          ? List<TimeStamp>.from(events)
          : List<TimeStamp>.from(this.events),
    );
  }

  @override
  String toString() {
    return 'DayModel(${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}, ${events.length} events, ${lastRecordedDur.inMinutes} mins)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DayEntry &&
        _isSameDay(other.dt, dt) &&
        listEquals(other.events, events);
  }

  @override
  int get hashCode => Object.hash(
      dt.year * 10000 + dt.month * 100 + dt.day, Object.hashAll(events));

  // ADDED: Helper method for checking same day
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Creates a corrected version of this day model
  /// Returns a new DayEntry with corrected events while retaining the original dt value.
  DayEntry corrected() {
    final date = startDt;
    final sortedEvents = _sortEventsByTime(timeStapms);
    final filteredEvents = _filterEventsOnSameDay(sortedEvents, date);
    final eventsWithStartEnd = _ensureStartAndEndPoints(filteredEvents, date);
    final correctedEvents = _updateDurations(eventsWithStartEnd);

    return DayEntry(
      dt: dt,
      events: correctedEvents,
    );
    // return copyWith();
  }

  List<TimeStamp> _sortEventsByTime(List<TimeStamp> events) {
    if (events.length > 1) {
      return events..sort((a, b) => a.dt.compareTo(b.dt));
    }
    return events;
  }

  List<TimeStamp> _filterEventsOnSameDay(
    List<TimeStamp> events,
    DateTime date,
  ) {
    return events.where((e) => _isSameDay(e.dt, date)).toList();
  }

  List<TimeStamp> _ensureStartAndEndPoints(
    List<TimeStamp> events,
    DateTime date,
  ) {
    final filteredEvents = List<TimeStamp>.from(events);

    if (!filteredEvents.any((e) => e.dt.isAtSameMomentAs(date))) {
      filteredEvents.insert(0, TimeStamp(date, Duration.zero, TPType.pause));
    }

    if (!isToday && !filteredEvents.any((e) => e.dt.isAtSameMomentAs(endDt))) {
      filteredEvents.add(TimeStamp(endDt, Duration.zero, TPType.pause));
    }

    return filteredEvents;
  }

  List<TimeStamp> _updateDurations(List<TimeStamp> events) {
    TimeStamp? prev;
    final correctedEvents = <TimeStamp>[];

    for (int i = 0; i < events.length; i++) {
      final event = events[i];

      if (i == 0) {
        final initialEvent = TimeStamp(startDt, Duration.zero, TPType.pause);
        correctedEvents.add(initialEvent);
        prev = initialEvent;
      } else {
        final duration = prev!.typ == TPType.resume
            ? prev.dur + event.dt.difference(prev.dt)
            : prev.dur;

        correctedEvents.add(TimeStamp(event.dt, duration, event.typ));
        prev = correctedEvents.last;
      }
    }

    return correctedEvents;
  }

  DayEntry addActiveEvent(DateTime at) {
    final events = List<TimeStamp>.from(this.events);
    final updatedEvents = TimeStampService.insertTimePoint(events, at, true);

    return copyWith(
      events: updatedEvents,
    );
  }

  factory DayEntry.create(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final emptyPoint = TimeStamp(
      dayStart,
      Duration.zero,
      TPType.pause,
    );
    return DayEntry(dt: dayStart, events: [emptyPoint]);
  }

  DayEntry end() {
    final events = List<TimeStamp>.from(this.events);
    final dayEndDt = DtHelper.dayEndDt(dt);

    // Calculate the final duration at end of day
    final dur = TimeStampService.calculateDuration(dayEndDt, events);

    // Create the last timepoint of the day
    final last = TimeStamp(
      dayEndDt,
      dur,
      TPType.pause, // Always end with pause
    );

    events.add(last);

    return copyWith(events: events);
  }
}
