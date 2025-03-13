import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ten_thousands_hours/models/time_data/time_point/time_point.dart';

void main() {
  group('TimePoint', () {
    test('should create a TimePoint with correct values', () {
      // Arrange
      final now = DateTime(2025, 3, 5, 10, 30);
      const duration = Duration(minutes: 45);
      const type = TimePointTyp.resume;

      // Act
      final timePoint = TimePoint(dt: now, dur: duration, typ: type);

      // Assert
      expect(timePoint.dt, now);
      expect(timePoint.dur, duration);
      expect(timePoint.typ, type);
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final dt = DateTime(2025, 3, 5, 10, 30);
      const dur = Duration(minutes: 45);
      const typ = TimePointTyp.resume;
      final timePoint = TimePoint(dt: dt, dur: dur, typ: typ);

      // Act
      final json = timePoint.toJson();

      // Assert
      expect(json['dt'], dt.toIso8601String());
      expect(json['dur'], dur.inMilliseconds);
      expect(json['typ'], 'resume');
    });

    test('should create from JSON correctly', () {
      // Arrange
      final dt = DateTime(2025, 3, 5, 10, 30);
      const dur = Duration(minutes: 45);
      const typ = TimePointTyp.pause;
      final json = {
        'dt': dt.toIso8601String(),
        'dur': dur.inMilliseconds,
        'typ': 'pause',
      };

      // Act
      final timePoint = TimePoint.fromJson(json);

      // Assert
      expect(timePoint.dt, dt);
      expect(timePoint.dur, dur);
      expect(timePoint.typ, typ);
    });

    test('should handle all enum values when creating from JSON', () {
      // Test all enum values
      for (final typ in TimePointTyp.values) {
        // Arrange
        final dt = DateTime(2025, 3, 5, 10, 30);
        const dur = Duration(minutes: 45);
        final typString = typ.toString().split('.').last;
        final json = {
          'dt': dt.toIso8601String(),
          'dur': dur.inMilliseconds,
          'typ': typString,
        };

        // Act
        final timePoint = TimePoint.fromJson(json);

        // Assert
        expect(timePoint.typ, typ);
      }
    });

    test('toString should return formatted string representation', () {
      // Arrange
      final dt = DateTime(2025, 3, 5, 10, 30, 45);
      const dur = Duration(minutes: 45);
      const typ = TimePointTyp.resume;
      final timePoint = TimePoint(dt: dt, dur: dur, typ: typ);

      // Act
      final result = timePoint.toString();

      // Assert
      expect(result, contains('10:30:45'));
      expect(result, contains('45sec'));
      expect(result, contains('resume'));
    });
  });

  group('TPService', () {
    group('generateCoordinates', () {
      test('insert time point test', () {
        final dayStartDt = DateTime(2025, 3, 5);
        final secondDt = DateTime(2025, 3, 5, 10);
        // Arrange
        final timePoints = [
          TimePoint(
            dt: dayStartDt,
            dur: const Duration(),
            typ: TimePointTyp.pause,
          ),
          TimePoint(
            dt: secondDt,
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
        ];
        final timeAt = DateTime(2025, 3, 5, 10, 15);

        // Act
        final result = TPService.insertTimePoint(timePoints, timeAt, true);

        // Assert
        expect(result.length, 3);
        expect(result[0].dt, dayStartDt);
        expect(result[1].dt, secondDt);
        expect(result[2].dt, timeAt);
        expect(result[2].dur.inMinutes, 45); // 30 + 15 minutes
        expect(result[2].typ, TimePointTyp.pause); // Switched from resume
      });

      test('should generate coordinates for points within session time', () {
        // Arrange
        final sessionStart = DateTime(2025, 3, 5, 10, 0);
        final sessionEnd = DateTime(2025, 3, 5, 12, 0);
        final timePoints = [
          TimePoint(
            dt: DateTime(2025, 3, 5, 10, 30),
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
          TimePoint(
            dt: DateTime(2025, 3, 5, 11, 0),
            dur: const Duration(minutes: 60),
            typ: TimePointTyp.pause,
          ),
          TimePoint(
            dt: DateTime(2025, 3, 5, 11, 30),
            dur: const Duration(minutes: 90),
            typ: TimePointTyp.resume,
          ),
        ];

        // Act
        final coordinates = TPService.generateCoordinates(
          timePoints: timePoints,
          sessionStartTime: sessionStart,
          sessionEndTime: sessionEnd,
          maxSessionDur: const Duration(minutes: 90),
          minSessionDur: const Duration(minutes: 0),
        );

        // Assert
        expect(coordinates.length, 3); // All points within session

        // Check x-coordinates (time progression from 0.0 to 1.0)
        expect(coordinates[0].dx, closeTo(0.25, 0.01)); // 30min / 120min = 0.25
        expect(coordinates[1].dx, closeTo(0.5, 0.01)); // 60min / 120min = 0.5
        expect(coordinates[2].dx, closeTo(0.75, 0.01)); // 90min / 120min = 0.75

        // Check y-coordinates (duration normalized by max-min)
        expect(coordinates[0].dy, closeTo(0.33, 0.01)); // 30min / 90min = 0.33
        expect(coordinates[1].dy, closeTo(0.67, 0.01)); // 60min / 90min = 0.67
        expect(coordinates[2].dy, closeTo(1.0, 0.01)); // 90min / 90min = 1.0
      });

      test('should filter out points outside session time', () {
        // Arrange
        final sessionStart = DateTime(2025, 3, 5, 10, 0);
        final sessionEnd = DateTime(2025, 3, 5, 12, 0);
        final timePoints = [
          TimePoint(
            dt: DateTime(2025, 3, 5, 9, 0), // Before session
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
          TimePoint(
            dt: DateTime(2025, 3, 5, 11, 0), // Within session
            dur: const Duration(minutes: 60),
            typ: TimePointTyp.pause,
          ),
          TimePoint(
            dt: DateTime(2025, 3, 5, 13, 0), // After session
            dur: const Duration(minutes: 90),
            typ: TimePointTyp.resume,
          ),
        ];

        // Act
        final coordinates = TPService.generateCoordinates(
          timePoints: timePoints,
          sessionStartTime: sessionStart,
          sessionEndTime: sessionEnd,
          maxSessionDur: const Duration(minutes: 90),
          minSessionDur: const Duration(minutes: 0),
        );

        // Assert
        expect(coordinates.length, 1); // Only one point within session
        expect(coordinates[0].dx, closeTo(0.5, 0.01)); // 60min / 120min = 0.5
      });

      test('should handle empty timePoints list', () {
        // Arrange
        final sessionStart = DateTime(2025, 3, 5, 10, 0);
        final sessionEnd = DateTime(2025, 3, 5, 12, 0);
        final timePoints = <TimePoint>[];

        // Act
        final coordinates = TPService.generateCoordinates(
          timePoints: timePoints,
          sessionStartTime: sessionStart,
          sessionEndTime: sessionEnd,
          maxSessionDur: const Duration(minutes: 90),
          minSessionDur: const Duration(minutes: 0),
        );

        // Assert
        expect(coordinates, isEmpty);
      });

      test('should handle zero session duration by using default', () {
        // Arrange
        final sessionStart = DateTime(2025, 3, 5, 10, 0);
        final sessionEnd = sessionStart; // Zero duration
        final timePoints = [
          TimePoint(
            dt: DateTime(2025, 3, 5, 10, 0),
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
        ];

        // Act
        final coordinates = TPService.generateCoordinates(
          timePoints: timePoints,
          sessionStartTime: sessionStart,
          sessionEndTime: sessionEnd,
          maxSessionDur: const Duration(minutes: 90),
          minSessionDur: const Duration(minutes: 0),
        );

        // Assert
        expect(coordinates.length, 1); // The function handles zero duration
        expect(coordinates[0].dx, 0.0); // At start of session
      });

      test('should handle zero max-min duration difference', () {
        // Arrange
        final sessionStart = DateTime(2025, 3, 5, 10, 0);
        final sessionEnd = DateTime(2025, 3, 5, 12, 0);
        final timePoints = [
          TimePoint(
            dt: DateTime(2025, 3, 5, 11, 0),
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
        ];

        // Act
        final coordinates = TPService.generateCoordinates(
          timePoints: timePoints,
          sessionStartTime: sessionStart,
          sessionEndTime: sessionEnd,
          maxSessionDur: const Duration(minutes: 30), // Same as min
          minSessionDur: const Duration(minutes: 30), // Same as max
        );

        // Assert
        expect(coordinates.length, 1);
        expect(coordinates[0].dx, closeTo(0.5, 0.01)); // Time position correct
        expect(coordinates[0].dy,
            1); // Default to 1 when min max dur equal and point dur is > 0
      });

      test('should handle debug mode', () {
        // This test just ensures debug mode doesn't crash
        // Arrange
        final sessionStart = DateTime(2025, 3, 5, 10, 0);
        final sessionEnd = DateTime(2025, 3, 5, 12, 0);
        final timePoints = [
          TimePoint(
            dt: DateTime(2025, 3, 5, 11, 0),
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
        ];

        // Act & Assert - shouldn't throw
        final coordinates = TPService.generateCoordinates(
          timePoints: timePoints,
          sessionStartTime: sessionStart,
          sessionEndTime: sessionEnd,
          maxSessionDur: const Duration(minutes: 90),
          minSessionDur: const Duration(minutes: 0),
          debug: true,
        );

        expect(coordinates.length, 1);
      });
    });

    group('insertTimePoint', () {
      test('should add first point to empty list', () {
        // Arrange
        final timePoints = <TimePoint>[];
        final timeAt = DateTime(2025, 3, 5, 10, 0);

        // Act
        final result = TPService.insertTimePoint(timePoints, timeAt, true);

        // Assert
        expect(result.length, 1);
        expect(result[0].dt, timeAt);
        expect(result[0].dur, Duration.zero);
        expect(result[0].typ, TimePointTyp.pause);
      });

      test('should insert point after existing point', () {
        // Arrange
        final firstPointTime = DateTime(2025, 3, 5, 10, 0);
        final timePoints = [
          TimePoint(
            dt: firstPointTime,
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
        ];
        final timeAt = DateTime(2025, 3, 5, 11, 0);

        // Act
        final result = TPService.insertTimePoint(timePoints, timeAt, true);

        // Assert
        expect(result.length, 2);
        expect(result[1].dt, timeAt);
        expect(result[1].dur.inMinutes, 90); // 30 (previous) + 60 (difference)
        expect(result[1].typ, TimePointTyp.pause); // Switched from resume
      });

      test('should not insert duplicate point', () {
        // Arrange
        final pointTime = DateTime(2025, 3, 5, 10, 0);
        final timePoints = [
          TimePoint(
            dt: pointTime,
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
        ];

        // Act
        final result = TPService.insertTimePoint(
            timePoints,
            pointTime, // Same time
            true);

        // Assert
        expect(result.length, 1); // No new point added
        expect(result, timePoints); // Same list returned
      });

      test('should maintain sorted order when inserting points', () {
        // Arrange
        final timePoints = [
          TimePoint(
            dt: DateTime(2025, 3, 5, 9, 0),
            dur: const Duration(minutes: 10),
            typ: TimePointTyp.resume,
          ),
          TimePoint(
            dt: DateTime(2025, 3, 5, 11, 0),
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.pause,
          ),
        ];
        final timeAt = DateTime(2025, 3, 5, 10, 0); // Between existing points

        // Act
        final result = TPService.insertTimePoint(timePoints, timeAt, true);

        // Assert
        expect(result.length, 3);
        expect(result[0].dt.hour, 9);
        expect(result[1].dt.hour, 10); // New point in correct position
        expect(result[2].dt.hour, 11);
      });

      test('should handle isActivePoint=false (no type change)', () {
        // Arrange
        final firstPointTime = DateTime(2025, 3, 5, 10, 0);
        final timePoints = [
          TimePoint(
            dt: firstPointTime,
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
        ];
        final timeAt = DateTime(2025, 3, 5, 11, 0);

        // Act
        final result = TPService.insertTimePoint(
            timePoints, timeAt, false // Don't toggle type
            );

        // Assert
        expect(result.length, 2);
        expect(result[1].dt, timeAt);
        expect(result[1].dur.inMinutes, 90); // 30 (previous) + 60 (difference)
        expect(result[1].typ,
            TimePointTyp.resume); // Same as previous (not toggled)
      });

      test('should correct date part of time', () {
        // Arrange
        final refDate = DateTime(2025, 3, 5, 10, 0);
        final timePoints = [
          TimePoint(
            dt: refDate,
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
        ];
        // Different date part but later time
        final timeAt = DateTime(2024, 1, 1, 11, 0);

        // Act
        final result = TPService.insertTimePoint(timePoints, timeAt, true);

        // Assert
        expect(result.length, 2);
        expect(result[1].dt.year, 2025); // Corrected to reference year
        expect(result[1].dt.month, 3); // Corrected to reference month
        expect(result[1].dt.day, 5); // Corrected to reference day
        expect(result[1].dt.hour, 11); // Maintains hour from input
      });
    });

    group('calculateDuration', () {
      test('should return zero for empty events list', () {
        // Arrange
        final timeAt = DateTime(2025, 3, 5, 10, 0);
        final events = <TimePoint>[];

        // Act
        final result = TPService.calculateDuration(timeAt, events);

        // Assert
        expect(result, Duration.zero);
      });

      test('should return duration of event at exact time', () {
        // Arrange
        final timeAt = DateTime(2025, 3, 5, 10, 0);
        final events = [
          TimePoint(
            dt: timeAt,
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
        ];

        // Act
        final result = TPService.calculateDuration(timeAt, events);

        // Assert
        expect(result, const Duration(minutes: 30));
      });

      test('should calculate increased duration for resume point', () {
        // Arrange
        final pointTime = DateTime(2025, 3, 5, 10, 0);
        final events = [
          TimePoint(
            dt: pointTime,
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume, // Counting time
          ),
        ];
        final timeAt = DateTime(2025, 3, 5, 10, 15); // 15 minutes later

        // Act
        final result = TPService.calculateDuration(timeAt, events);

        // Assert
        expect(result.inMinutes, 45); // 30 + 15 minutes
      });

      test('should not increase duration for pause point', () {
        // Arrange
        final pointTime = DateTime(2025, 3, 5, 10, 0);
        final events = [
          TimePoint(
            dt: pointTime,
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.pause, // Not counting time
          ),
        ];
        final timeAt = DateTime(2025, 3, 5, 10, 15); // 15 minutes later

        // Act
        final result = TPService.calculateDuration(timeAt, events);

        // Assert
        expect(result.inMinutes, 30); // Still 30 minutes (no increase)
      });

      test('should find correct point in multiple events', () {
        // Arrange
        final events = [
          TimePoint(
            dt: DateTime(2025, 3, 5, 9, 0),
            dur: const Duration(minutes: 10),
            typ: TimePointTyp.pause,
          ),
          TimePoint(
            dt: DateTime(2025, 3, 5, 10, 0),
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
          TimePoint(
            dt: DateTime(2025, 3, 5, 11, 0),
            dur: const Duration(minutes: 60),
            typ: TimePointTyp.pause,
          ),
        ];
        final timeAt =
            DateTime(2025, 3, 5, 10, 30); // Between second and third point

        // Act
        final result = TPService.calculateDuration(timeAt, events);

        // Assert
        expect(result.inMinutes,
            60); // 30 + 30 minutes (from second point + elapsed)
      });

      test('should return zero for time before first event', () {
        // Arrange
        final events = [
          TimePoint(
            dt: DateTime(2025, 3, 5, 10, 0),
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
        ];
        final timeAt = DateTime(2025, 3, 5, 9, 0); // Before first event

        // Act
        final result = TPService.calculateDuration(timeAt, events);

        // Assert
        expect(result, Duration.zero);
      });

      test('should correct date part of input time', () {
        // Arrange
        final refDate = DateTime(2025, 3, 5, 10, 0);
        final events = [
          TimePoint(
            dt: refDate,
            dur: const Duration(minutes: 30),
            typ: TimePointTyp.resume,
          ),
        ];
        // Different date but later time
        final timeAt = DateTime(2024, 1, 1, 10, 30);

        // Act
        final result = TPService.calculateDuration(timeAt, events);

        // Assert
        expect(result.inMinutes, 60); // 30 + 30 minutes
      });
    });
  });

  group('DtHelper', () {
    test('sameHourMinute should compare hours and minutes only', () {
      // Arrange
      final dt1 = DateTime(2025, 3, 5, 10, 30, 0);
      final dt2 = DateTime(2024, 1, 1, 10, 30, 45); // Different date, seconds
      final dt3 = DateTime(2025, 3, 5, 11, 30, 0); // Different hour

      // Act & Assert
      expect(DtHelper.sameHourMinute(dt1, dt2), isTrue);
      expect(DtHelper.sameHourMinute(dt1, dt3), isFalse);
    });

    test('isDayStartDt should identify midnight', () {
      // Arrange
      final midnight = DateTime(2025, 3, 5, 0, 0, 0);
      final notMidnight1 = DateTime(2025, 3, 5, 0, 1, 0); // 1 minute past
      final notMidnight2 = DateTime(2025, 3, 5, 1, 0, 0); // 1 hour past

      // Act & Assert
      expect(DtHelper.isDayStartDt(midnight), isTrue);
      expect(DtHelper.isDayStartDt(notMidnight1), isFalse);
      expect(DtHelper.isDayStartDt(notMidnight2), isFalse);
    });

    test('dayStartDt should return midnight', () {
      // Arrange
      final dt = DateTime(2025, 3, 5, 10, 30, 45);

      // Act
      final result = DtHelper.dayStartDt(dt);

      // Assert
      expect(result.year, 2025);
      expect(result.month, 3);
      expect(result.day, 5);
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
      expect(result.millisecond, 0);
    });

    test('dayEndDt should return end of day', () {
      // Arrange
      final dt = DateTime(2025, 3, 5, 10, 30, 45);

      // Act
      final result = DtHelper.dayEndDt(dt);

      // Assert
      expect(result.year, 2025);
      expect(result.month, 3);
      expect(result.day, 5);
      expect(result.hour, 23);
      expect(result.minute, 59);
      expect(result.second, 59);
      expect(result.millisecond, 999);
      expect(result.microsecond, 999);
    });

    test('correctDt should apply date from reference while keeping time', () {
      // Arrange
      final dt = DateTime(2024, 1, 1, 10, 30, 45, 500, 600);
      final refDate = DateTime(2025, 3, 5, 12, 0, 0);

      // Act
      final result = DtHelper.correctDt(dt, refDate);

      // Assert
      expect(result.year, 2025); // From refDate
      expect(result.month, 3); // From refDate
      expect(result.day, 5); // From refDate
      expect(result.hour, 10); // From dt
      expect(result.minute, 30); // From dt
      expect(result.second, 45); // From dt
      expect(result.millisecond, 500); // From dt
      expect(result.microsecond, 600); // From dt
    });
  });
}
