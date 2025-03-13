import 'package:flutter_test/flutter_test.dart';
import 'package:ten_thousands_hours/models/time_data/day_entry/day_model.dart';
import 'package:ten_thousands_hours/models/time_data/day_entry/day_services.dart';
import 'package:ten_thousands_hours/models/time_data/time_point/time_point.dart';

void main() {
  group('DayModel', () {
    group('Construction and basic properties', () {
      test('should create with specified values', () {
        // Arrange
        final dt = DateTime(2025, 3, 5);
        final durPoint = TimePoint(
          dt: dt,
          dur: const Duration(minutes: 30),
          typ: TimePointTyp.pause,
        );
        final events = [
          TimePoint(
            dt: dt,
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.pause,
          ),
        ];

        // Act
        final day = DayEntry(
          dt: dt,
          durPoint: durPoint,
          events: events,
        );

        // Assert
        expect(day.dt, dt);
        expect(day.durPoint, durPoint);
        expect(day.events, events);
      });

      test('toString should return formatted string representation', () {
        // Arrange
        final dt = DateTime(2025, 3, 5);
        final durPoint = TimePoint(
          dt: dt,
          dur: const Duration(minutes: 30),
          typ: TimePointTyp.pause,
        );
        final events = [durPoint];
        final day = DayEntry(dt: dt, durPoint: durPoint, events: events);

        // Act
        final result = day.toString();

        // Assert
        expect(result, contains('2025:3: 5'));
      });
    });

    group('JSON Serialization', () {
      test('should convert to JSON correctly', () {
        // Arrange
        final dt = DateTime(2025, 3, 5);
        final durPoint = TimePoint(
          dt: dt,
          dur: const Duration(minutes: 30),
          typ: TimePointTyp.pause,
        );
        final events = [
          TimePoint(
            dt: dt,
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.pause,
          ),
        ];
        final day = DayEntry(dt: dt, durPoint: durPoint, events: events);

        // Act
        final json = day.toJson();

        // Assert
        expect(json['lastUpdate'], dt.toIso8601String());
        expect(json['durPoint'], isA<Map<String, dynamic>>());
        expect(json['events'], isA<List>());
        expect(json['events'].length, 1);
      });

      test('should create from JSON correctly', () {
        // Arrange
        final dt = DateTime(2025, 3, 5);
        final json = {
          'lastUpdate': dt.toIso8601String(),
          'durPoint': {
            'dt': dt.toIso8601String(),
            'dur': 1800000, // 30 minutes in milliseconds
            'typ': 'pause',
          },
          'events': [
            {
              'dt': dt.toIso8601String(),
              'dur': 1800000,
              'typ': 'pause',
            },
          ],
        };

        // Act
        final day = DayEntry.fromJson(json);

        // Assert
        expect(day.dt.year, 2025);
        expect(day.dt.month, 3);
        expect(day.dt.day, 5);
        expect(day.durPoint.dur.inMinutes, 30);
        expect(day.durPoint.typ, TimePointTyp.pause);
        expect(day.events.length, 1);
        expect(day.events[0].dur.inMinutes, 30);
      });

      test('should handle missing durPoint in JSON', () {
        // Arrange
        final dt = DateTime(2025, 3, 5);
        final json = {
          'lastUpdate': dt.toIso8601String(),
          'events': [
            {
              'dt': dt.toIso8601String(),
              'dur': 1800000,
              'typ': 'pause',
            },
          ],
        };

        // Act
        final day = DayEntry.fromJson(json);

        // Assert
        expect(day.durPoint, isNotNull);
        expect(day.durPoint.dt.year, 1999); // Default value
        expect(day.durPoint.dur, Duration.zero);
      });

      test('should handle missing events in JSON', () {
        // Arrange
        final dt = DateTime(2025, 3, 5);
        final json = {
          'lastUpdate': dt.toIso8601String(),
          'durPoint': {
            'dt': dt.toIso8601String(),
            'dur': 1800000,
            'typ': 'pause',
          },
        };

        // Act
        final day = DayEntry.fromJson(json);

        // Assert
        expect(day.events.length, 1); // Should use durPoint as the only event
        expect(day.events[0], day.durPoint);
      });

      test('should handle missing lastUpdate in JSON', () {
        // Arrange
        final dt = DateTime(2025, 3, 5);
        final json = {
          'durPoint': {
            'dt': dt.toIso8601String(),
            'dur': 1800000,
            'typ': 'pause',
          },
          'events': [
            {
              'dt': dt.toIso8601String(),
              'dur': 1800000,
              'typ': 'pause',
            },
          ],
        };

        // Act
        final day = DayEntry.fromJson(json);

        // Assert
        expect(day.dt, dt); // Should use durPoint.dt
      });
    });

    group('copyWith', () {
      test('should create a copy with specified fields changed', () {
        // Arrange
        final dt = DateTime(2025, 3, 5);
        final durPoint = TimePoint(
          dt: dt,
          dur: const Duration(minutes: 30),
          typ: TimePointTyp.pause,
        );
        final events = [durPoint];
        final day = DayEntry(dt: dt, durPoint: durPoint, events: events);

        final newDt = DateTime(2025, 3, 6);
        final newDurPoint = TimePoint(
          dt: newDt,
          dur: const Duration(minutes: 45),
          typ: TimePointTyp.resume,
        );

        // Act
        final copied = day.copyWith(
          dt: newDt,
          durPoint: newDurPoint,
        );

        // Assert
        expect(copied.dt, newDt);
        expect(copied.durPoint, newDurPoint);
        expect(copied.events, events); // Unchanged
      });

      test('should create a new instance when no parameters provided', () {
        // Arrange
        final dt = DateTime(2025, 3, 5);
        final durPoint = TimePoint(
          dt: dt,
          dur: const Duration(minutes: 30),
          typ: TimePointTyp.pause,
        );
        final events = [durPoint];
        final day = DayEntry(dt: dt, durPoint: durPoint, events: events);

        // Act
        final copied = day.copyWith();

        // Assert
        expect(identical(day, copied), isFalse); // Different instance
        expect(copied.dt, dt);
        expect(copied.durPoint, durPoint);
        expect(identical(copied.events, day.events),
            isFalse); // Should be a deep copy
      });
    });
  });

  group('DayModelService', () {
    group('createNewDay', () {
      test('should create a day with correct starting values at midnight', () {
        // Arrange
        final midnight = DateTime(2025, 3, 5, 0, 0);

        // Act
        final day = DayModelService.createNewDay(midnight);

        // Assert
        expect(day.dt, equals(midnight)); // Should be midnight
        expect(day.durPoint.dt, equals(midnight));
        expect(day.durPoint.dur, Duration.zero);
        expect(day.durPoint.typ, TimePointTyp.pause);
        expect(day.events.length, 1); // Only one event at midnight
      });

      test('should create a day with correct starting values at non-midnight',
          () {
        // Arrange
        final nonMidnight = DateTime(2025, 3, 5, 10, 30);

        // Act
        final day = DayModelService.createNewDay(nonMidnight);

        // Assert
        // dt should be midnight of the day
        expect(day.dt.year, 2025);
        expect(day.dt.month, 3);
        expect(day.dt.day, 5);
        expect(day.dt.hour, 0);
        expect(day.dt.minute, 0);
        expect(day.dt.second, 0);

        expect(day.durPoint.dt, equals(nonMidnight));
        expect(day.durPoint.dur, Duration.zero);
        expect(day.durPoint.typ, TimePointTyp.pause);

        expect(day.events.length, 2); // One at midnight, one at specified time
        expect(day.events[0].dt.hour, 0);
        expect(day.events[0].dt.minute, 0);
        expect(day.events[1].dt, equals(nonMidnight));
      });
    });

    group('endDay', () {
      test('should add final event at end of day', () {
        // Arrange
        final date = DateTime(2025, 3, 5, 10, 0);
        final day = DayModelService.createNewDay(date);

        // Act
        final endedDay = DayModelService.endDay(day);

        // Assert
        expect(endedDay.events.last.dt.hour, 23);
        expect(endedDay.events.last.dt.minute, 59);
        expect(endedDay.events.last.dt.second, 59);
        expect(endedDay.events.last.typ, TimePointTyp.pause);
        expect(endedDay.durPoint,
            equals(endedDay.events.last)); // durPoint should be the last event
      });

      test('should calculate correct duration for the day', () {
        // Arrange
        final date = DateTime(2025, 3, 5, 10, 0);
        var day = DayModelService.createNewDay(date);

        // Add some events with durations
        day = DayModelService.addActiveEvent(
          day: day,
          dtAt: DateTime(2025, 3, 5, 11, 0),
        );
        day = DayModelService.addActiveEvent(
          day: day,
          dtAt: DateTime(2025, 3, 5, 12, 0),
        );

        // Act
        final endedDay = DayModelService.endDay(day);

        // Assert
        // The exact duration would depend on the implementation of calculateDuration
        expect(endedDay.durPoint.dur.inSeconds, greaterThan(0));
      });
    });

    group('addActiveEvent', () {
      test('should add a new event to the day', () {
        // Arrange
        final date = DateTime(2025, 3, 5, 10, 0);
        final day = DayModelService.createNewDay(date);
        final eventTime = DateTime(2025, 3, 5, 11, 0);

        // Act
        final updatedDay = DayModelService.addActiveEvent(
          day: day,
          dtAt: eventTime,
        );

        // Assert
        expect(updatedDay.events.length, day.events.length + 1);
        expect(updatedDay.events.last.dt, eventTime);
      });

      test('should toggle event type correctly', () {
        // Arrange
        final date = DateTime(2025, 3, 5, 10, 0);
        var day = DayModelService.createNewDay(date);

        // Act
        // First event (after initial events)
        day = DayModelService.addActiveEvent(
          day: day,
          dtAt: DateTime(2025, 3, 5, 11, 0),
        );
        // Second event
        day = DayModelService.addActiveEvent(
          day: day,
          dtAt: DateTime(2025, 3, 5, 12, 0),
        );

        // Assert
        // Types should alternate
        final types = day.events.map((e) => e.typ).toList();
        expect(types[types.length - 2], isNot(types.last));
      });

      test('should update durPoint to the last added event', () {
        // Arrange
        final date = DateTime(2025, 3, 5, 10, 0);
        final day = DayModelService.createNewDay(date);
        final eventTime = DateTime(2025, 3, 5, 11, 0);

        // Act
        final updatedDay = DayModelService.addActiveEvent(
          day: day,
          dtAt: eventTime,
        );

        // Assert
        expect(updatedDay.durPoint.dt, eventTime);
      });

      test('should not add event from different day', () {
        // Arrange
        final date = DateTime(2025, 3, 5, 10, 0);
        final day = DayModelService.createNewDay(date);
        final differentDayTime = DateTime(2025, 3, 6, 11, 0); // Next day

        // Act
        final updatedDay = DayModelService.addActiveEvent(
          day: day,
          dtAt: differentDayTime,
        );

        // Assert
        expect(
            updatedDay.events.length, day.events.length); // No new event added
      });
    });

    group('unactiveDtUpdate', () {
      test('should update time without adding new event', () {
        // Arrange
        final date = DateTime(2025, 3, 5, 10, 0);
        var day = DayModelService.createNewDay(date);
        // Add an active resume event
        day = DayModelService.addActiveEvent(
          day: day,
          dtAt: DateTime(2025, 3, 5, 11, 0),
        );

        // Act - update 30 minutes later
        final updateTime = DateTime(2025, 3, 5, 11, 30);
        final updatedDay = DayModelService.unactiveDtUpdate(
          day: day,
          dtAt: updateTime,
        );

        // Assert
        expect(updatedDay.events.length, day.events.length);
        expect(updatedDay.durPoint.dt, updateTime);
      });

      test('should not update for different day', () {
        // Arrange
        final date = DateTime(2025, 3, 5, 10, 0);
        final day = DayModelService.createNewDay(date);
        final differentDayTime = DateTime(2025, 3, 6, 11, 0); // Next day

        // Act
        final updatedDay = DayModelService.unactiveDtUpdate(
          day: day,
          dtAt: differentDayTime,
        );

        // Assert
        expect(updatedDay.durPoint, day.durPoint); // Unchanged
      });
    });

    group('updateCoordinates', () {
      test('should generate coordinates for events', () {
        // Arrange
        final date = DateTime(2025, 3, 5, 10, 0);
        final day = DayModelService.createNewDay(date);
        final sessionStart = DateTime(2025, 3, 5, 9, 0);
        final sessionEnd = DateTime(2025, 3, 5, 17, 0);

        // Act
        final coordinates = DayModelService.updateCoordinates(
          day: day,
          timeAt: date,
          sessionStartDt: sessionStart,
          sessionEndDt: sessionEnd,
          coordinateMaxDur: const Duration(hours: 8),
          coordinateMinDur: Duration.zero,
        );

        // Assert
        expect(coordinates, isNotEmpty);
      });

      test('should handle isToday parameter correctly', () {
        // Arrange
        final date = DateTime(2025, 3, 5, 10, 0);
        final day = DayModelService.createNewDay(date);
        final sessionStart = DateTime(2025, 3, 5, 9, 0);
        final sessionEnd = DateTime(2025, 3, 5, 17, 0);

        // Act - with isToday = false (default)
        final coordinatesNotToday = DayModelService.updateCoordinates(
          day: day,
          timeAt: date,
          sessionStartDt: sessionStart,
          sessionEndDt: sessionEnd,
          coordinateMaxDur: const Duration(hours: 8),
          coordinateMinDur: Duration.zero,
        );

        // Act - with isToday = true
        final coordinatesToday = DayModelService.updateCoordinates(
          day: day,
          timeAt: date,
          sessionStartDt: sessionStart,
          sessionEndDt: sessionEnd,
          coordinateMaxDur: const Duration(hours: 8),
          coordinateMinDur: Duration.zero,
          isToday: true,
        );

        // Assert
        expect(coordinatesNotToday.length,
            greaterThanOrEqualTo(2)); // Should include session start/end
        expect(coordinatesToday.length,
            greaterThanOrEqualTo(1)); // May not include session end
      });
    });
  });
}
