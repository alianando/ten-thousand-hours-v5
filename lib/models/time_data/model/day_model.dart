import 'package:flutter/material.dart';
import 'time_point.dart';

class DayModel {
  final DateTime lastUpdate;
  final TimePoint durPoint;
  final List<TimePoint> events;
  final List<Offset> coordinates;
  final CoordinateSets? coordinateSets;

  const DayModel({
    required this.lastUpdate,
    required this.durPoint,
    required this.events,
    required this.coordinates,
    this.coordinateSets,
  });

  Map<String, dynamic> toJson() {
    return {
      'lastUpdate': lastUpdate.toIso8601String(),
      'durPoint': durPoint.toJson(),
      'events': events.map((tp) => tp.toJson()).toList(),
      'coordinates': coordinates
          .map((offset) => {'dx': offset.dx, 'dy': offset.dy})
          .toList(),
      'coordinateSets': null,
    };
  }

  factory DayModel.fromJson(Map<String, dynamic> json) {
    return DayModel(
      lastUpdate: DateTime.parse(json['lastUpdate']),
      durPoint: TimePoint.fromJson(json['durPoint']),
      events:
          (json['events'] as List).map((tp) => TimePoint.fromJson(tp)).toList(),
      coordinates: (json['coordinates'] as List)
          .map((c) => Offset(
                (c['dx'] as num).toDouble(),
                (c['dy'] as num).toDouble(),
              ))
          .toList(),
      // coordinates: [],
    );
  }

  Offset jsonToCoordinate(Map<String, dynamic> j) {
    return Offset(j['dx'] as double, j['dy'] as double);
  }

  DayModel copyWith({
    DateTime? lastUpdate,
    TimePoint? durPoint,
    List<TimePoint>? events,
    List<Offset>? coordinates,
    CoordinateSets? coordinateSets,
  }) {
    return DayModel(
      lastUpdate: lastUpdate ?? this.lastUpdate,
      durPoint: durPoint ?? this.durPoint,
      events: events ?? this.events,
      coordinates: coordinates ?? this.coordinates,
      coordinateSets: coordinateSets ?? this.coordinateSets,
    );
  }

  @override
  String toString() {
    return 'Day($lastUpdate, ${durPoint.dur}, [$events], [$coordinates])';
  }
}

class CoordinateSets {
  // Add implementation details as needed
}

class DayModelService {
  const DayModelService._();

  // coordinates not updated.
  static DayModel createNewDay(DateTime at) {
    return DayModel(
      lastUpdate: at,
      durPoint: TimePoint(
        dt: at,
        dur: const Duration(),
        typ: TimePointTyp.pause,
      ),
      events: [
        if (!DtHelper.isDayStartDt(at))
          TimePoint(
            dt: DtHelper.dayStartDt(at),
            dur: const Duration(),
            typ: TimePointTyp.pause,
          ),
        TimePoint(
          dt: at,
          dur: const Duration(),
          typ: TimePointTyp.pause,
        ),
      ],
      coordinates: [],
    );
  }

  // coordinates not updated.
  static DayModel endDay(DayModel day) {
    final events = List<TimePoint>.from(day.events);
    final dayEndDt = DtHelper.dayEndDt(day.lastUpdate);
    final dur = TPService.calculateDuration(dayEndDt, events);
    final last = TimePoint(
      dt: dayEndDt,
      dur: dur,
      typ: TimePointTyp.pause,
    );
    events.add(last);
    return DayModel(
      lastUpdate: dayEndDt,
      durPoint: last,
      events: events,
      coordinates: [],
    );
  }

  static DayModel addEvent({
    required DayModel day,
    required DateTime at,
  }) {
    final events = List<TimePoint>.from(day.events);
    final correctedDt = DtHelper.correctDt(at, events.first.dt);
    final updatedEvents = TPService.addTimePoint(events, correctedDt, true);
    final durTimePoint = updatedEvents.last;
    return day.copyWith(
      durPoint: durTimePoint,
      events: updatedEvents,
    );
  }

  static DayModel unactiveDtUpdate({
    required DayModel day,
    required DateTime timeAt,
  }) {
    final events = List<TimePoint>.from(day.events);
    final correctedDt = DtHelper.correctDt(timeAt, events.first.dt);
    // final updatedEvents = TPService.addTimePoint(events, correctedDt, false);
    final dur = TPService.calculateDuration(correctedDt, events);
    final durTimePoint = TimePoint(
      dt: correctedDt,
      dur: dur,
      typ: events.last.typ,
    );
    return day.copyWith(
      durPoint: durTimePoint,
      // events: updatedEvents,
    );
  }

  static DayModel updateCoordinates({
    required DayModel day,
    required DateTime at,
    required DateTime sessionStartDt,
    required DateTime sessionEndDt,
    required Duration coordinateMaxDur,
    Duration coordinateMinDur = const Duration(),
    bool isToday = false,
  }) {
    List<TimePoint> events = List.from(day.events);
    List<TimePoint> pointsForCo = [];
    pointsForCo = TPService.addTimePoint(events, sessionStartDt, false);
    if (!isToday) {
      pointsForCo = TPService.addTimePoint(pointsForCo, sessionEndDt, false);
    } else {
      pointsForCo = TPService.addTimePoint(pointsForCo, at, false);
    }

    final updatedCoos = TPService.generateCoordinates(
      timePoints: pointsForCo,
      sessionStartTime: sessionStartDt,
      sessionEndTime: sessionEndDt,
      maxSessionDur: coordinateMaxDur,
      minSessionDur: coordinateMinDur,
    );
    return day.copyWith(coordinates: updatedCoos);
  }
}
