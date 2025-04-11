import 'package:flutter_test/flutter_test.dart';
import 'package:ten_thousands_hours/modules/1_time_record/day_record.dart';
import 'package:ten_thousands_hours/modules/1_time_record/time_stamp.dart';
import 'package:ten_thousands_hours/modules/6_graphs/3_hour_distribution_graph/hourly_distribution_services.dart';

void main() {
  group('HDServices.dayHourlyDurDistribution', () {
    // Test with empty day
    test('returns zeros for all hours when no events exist', () {
      // Arrange
      final date = DateTime(2023, 5, 15);
      final emptyDay = DayEntry(
        dt: date,
        durPoint: TimeStamp(date, Duration.zero, TPType.pause),
        events: [],
      );

      // Act
      final result = HDServices.dayHourlyDurDistribution(emptyDay);

      // Assert
      expect(result.length, 24);
      for (int hour = 0; hour < 24; hour++) {
        expect(result[hour], 0.0);
      }
    });

    // Test with a single event
    test('returns zeros for all hours when only one event exists', () {
      // Arrange
      final date = DateTime(2023, 5, 15);
      final singleEventDay = DayEntry(
        dt: date,
        durPoint: TimeStamp(date, Duration.zero, TPType.pause),
        events: [TimeStamp(date, Duration.zero, TPType.pause)],
      );

      // Act
      final result = HDServices.dayHourlyDurDistribution(singleEventDay);

      // Assert
      expect(result.length, 24);
      for (int hour = 0; hour < 24; hour++) {
        expect(result[hour], 0.0);
      }
    });

    // Test with one hour of active time
    test('calculates durations correctly for a complete hour of work', () {
      // Arrange
      final date = DateTime(2023, 5, 15);
      final startTime = DateTime(2023, 5, 15, 9, 0, 0);
      final middleTime = DateTime(2023, 5, 15, 9, 30); // 9:00 AM
      final endTime = DateTime(2023, 5, 15, 10, 0, 0); // 10:00 AM

      final day = DayEntry(
        dt: date,
        durPoint: TimeStamp(endTime, const Duration(hours: 1), TPType.pause),
        events: [
          TimeStamp(date, Duration.zero, TPType.pause),
          TimeStamp(startTime, Duration.zero, TPType.resume),
          TimeStamp(middleTime, const Duration(minutes: 30), TPType.resume),
          TimeStamp(endTime, const Duration(hours: 1), TPType.pause),
        ],
      );

      // Act
      final result = HDServices.dayHourlyDurDistribution(day);

      // Assert
      expect(result.length, 24);
      expect(result[9], 1.0); // Full hour of work from 9-10

      // All other hours should be zero
      for (int hour = 0; hour < 24; hour++) {
        if (hour != 9) {
          expect(result[hour], 0.0);
        }
      }
    });

    // Test with partial hour
    test('calculates durations correctly for partial hour of work', () {
      // Arrange
      final date = DateTime(2023, 5, 15);
      final startTime = DateTime(2023, 5, 15, 14, 30, 0); // 2:30 PM
      final endTime = DateTime(2023, 5, 15, 15, 0, 0); // 3:00 PM

      final day = DayEntry(
        dt: date,
        durPoint: TimeStamp(endTime, const Duration(minutes: 30), TPType.pause),
        events: [
          TimeStamp(startTime, Duration.zero, TPType.resume),
          TimeStamp(endTime, const Duration(minutes: 30), TPType.pause),
        ],
      );

      // Act
      final result = HDServices.dayHourlyDurDistribution(day);

      // Assert
      expect(result.length, 24);
      expect(
          result[14], closeTo(0.5, 0.001)); // Half hour of work from 2:30-3:00

      // All other hours should be zero
      for (int hour = 0; hour < 24; hour++) {
        if (hour != 14) {
          expect(result[hour], 0.0);
        }
      }
    });

    // Test with work spanning multiple hours
    test('calculates durations correctly for work spanning multiple hours', () {
      // Arrange
      final date = DateTime(2023, 5, 15);
      final startTime = DateTime(2023, 5, 15, 10, 30, 0); // 10:30 AM
      final endTime = DateTime(2023, 5, 15, 12, 15, 0); // 12:15 PM

      final day = DayEntry(
        dt: date,
        durPoint: TimeStamp(
            endTime, const Duration(hours: 1, minutes: 45), TPType.pause),
        events: [
          TimeStamp(startTime, Duration.zero, TPType.resume),
          TimeStamp(
              endTime, const Duration(hours: 1, minutes: 45), TPType.pause),
        ],
      );

      // Act
      final result = HDServices.dayHourlyDurDistribution(day);

      // Assert
      expect(result.length, 24);
      expect(result[10], closeTo(0.5, 0.001)); // 30 minutes from 10:30-11:00
      expect(result[11], 1.0); // Full hour from 11:00-12:00
      expect(result[12], closeTo(0.25, 0.001)); // 15 minutes from 12:00-12:15

      // All other hours should be zero
      for (int hour = 0; hour < 24; hour++) {
        if (hour != 10 && hour != 11 && hour != 12) {
          expect(result[hour], 0.0);
        }
      }
    });

    // Test with multiple resume-pause pairs in the same hour
    test('accumulates durations for multiple work sessions in the same hour',
        () {
      // Arrange
      final date = DateTime(2023, 5, 15);

      final startTime1 = DateTime(2023, 5, 15, 13, 0, 0); // 1:00 PM
      final endTime1 = DateTime(2023, 5, 15, 13, 20, 0); // 1:20 PM

      final startTime2 = DateTime(2023, 5, 15, 13, 30, 0); // 1:30 PM
      final endTime2 = DateTime(2023, 5, 15, 13, 50, 0); // 1:50 PM

      final day = DayEntry(
        dt: date,
        durPoint:
            TimeStamp(endTime2, const Duration(minutes: 40), TPType.pause),
        events: [
          TimeStamp(startTime1, Duration.zero, TPType.resume),
          TimeStamp(endTime1, const Duration(minutes: 20), TPType.pause),
          TimeStamp(startTime2, const Duration(minutes: 20), TPType.resume),
          TimeStamp(endTime2, const Duration(minutes: 40), TPType.pause),
        ],
      );

      // Act
      final result = HDServices.dayHourlyDurDistribution(day);

      // Assert
      expect(result.length, 24);
      expect(result[13],
          closeTo(0.6667, 0.001)); // 40 minutes total (20+20) out of 60

      // All other hours should be zero
      for (int hour = 0; hour < 24; hour++) {
        if (hour != 13) {
          expect(result[hour], 0.0);
        }
      }
    });

    // Test with unsorted events (should still work correctly)
    test('works correctly with unsorted events', () {
      // Arrange
      final date = DateTime(2023, 5, 15);
      final startTime = DateTime(2023, 5, 15, 9, 0, 0); // 9:00 AM
      final endTime = DateTime(2023, 5, 15, 10, 0, 0); // 10:00 AM

      final day = DayEntry(
        dt: date,
        durPoint: TimeStamp(endTime, const Duration(hours: 1), TPType.pause),
        events: [
          // Events in wrong order
          TimeStamp(endTime, const Duration(hours: 1), TPType.pause),
          TimeStamp(startTime, Duration.zero, TPType.resume),
        ],
      );

      // Act
      final result = HDServices.dayHourlyDurDistribution(day);

      // Assert
      expect(result.length, 24);
      expect(result[9], 1.0); // Still should show full hour from 9-10
    });

    // Test capping at 1.0 for any hour
    test('caps durations at 1.0 for any hour', () {
      // Arrange
      final date = DateTime(2023, 5, 15);

      // Two full hours of work in the same hour (impossible in reality)
      final startTime1 = DateTime(2023, 5, 15, 8, 0, 0);
      final endTime1 = DateTime(2023, 5, 15, 9, 0, 0);

      final startTime2 = DateTime(2023, 5, 15, 8, 0, 0);
      final endTime2 = DateTime(2023, 5, 15, 9, 0, 0);

      final day = DayEntry(
        dt: date,
        durPoint: TimeStamp(endTime2, const Duration(hours: 2), TPType.pause),
        events: [
          TimeStamp(startTime1, Duration.zero, TPType.resume),
          TimeStamp(endTime1, const Duration(hours: 1), TPType.pause),
          TimeStamp(startTime2, const Duration(hours: 1), TPType.resume),
          TimeStamp(endTime2, const Duration(hours: 2), TPType.pause),
        ],
      );

      // Act
      final result = HDServices.dayHourlyDurDistribution(day);

      // Assert
      expect(result.length, 24);
      expect(result[8],
          1.0); // Should be capped at 1.0 even though we have 2 hours worth
    });

    // Test with no active periods (all pause events)
    test('returns zeros for all hours when no active periods exist', () {
      // Arrange
      final date = DateTime(2023, 5, 15);
      final pauseTime1 = DateTime(2023, 5, 15, 9, 0, 0);
      final pauseTime2 = DateTime(2023, 5, 15, 10, 0, 0);

      final day = DayEntry(
        dt: date,
        durPoint: TimeStamp(pauseTime2, Duration.zero, TPType.pause),
        events: [
          TimeStamp(pauseTime1, Duration.zero, TPType.pause),
          TimeStamp(pauseTime2, Duration.zero, TPType.pause),
        ],
      );

      // Act
      final result = HDServices.dayHourlyDurDistribution(day);

      // Assert
      expect(result.length, 24);
      for (int hour = 0; hour < 24; hour++) {
        expect(result[hour], 0.0);
      }
    });
  });
}
