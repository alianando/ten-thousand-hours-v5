import 'package:flutter_test/flutter_test.dart';
import 'package:ten_thousands_hours/models/time_data/model/session_data.dart';
import 'package:ten_thousands_hours/models/time_data/model/time_data.dart';
import 'package:ten_thousands_hours/models/time_data/model/time_point.dart';
import 'package:ten_thousands_hours/models/time_data/time_logic.dart';

void main() {
  group('TimeLogic', () {
    // Mock saveData function for testing
    void mockSaveData(TimeData data) {}

    group('createEmptyTimeData', () {
      test('should create default TimeData object with expected values', () {
        // Arrange
        final testDateTime = DateTime(2025, 3, 1, 10, 0);

        // Act
        final result = TimeLogic.createEmptyTimeData(at: testDateTime);

        // Assert
        expect(result.lastUpdate, testDateTime);

        // Check indices
        expect(result.indices.today, 0);
        expect(result.indices.weekIndices, [0]);
        expect(result.indices.monthIndices, [0]);

        // Check days
        expect(result.days.length, 1);
        final day = result.days[0];
        expect(day.lastUpdate, testDateTime);
        expect(day.events.length, greaterThanOrEqualTo(1));

        // Check session data
        final session = result.sessionData;
        expect(session.sessionStartDt.day, testDateTime.day);
        expect(session.sessionEndDt.day, testDateTime.day);

        // Check stat data
        final stat = result.statData;
        expect(stat.maxDurReleventDays, isNotNull);

        // Check coordinates
        expect(day.coordinates.isNotEmpty, isTrue);
      });

      test('should handle midnight edge case', () {
        // Arrange
        final midnightDateTime = DateTime(2025, 3, 1, 0, 0);

        // Act
        final result = TimeLogic.createEmptyTimeData(at: midnightDateTime);

        // Assert
        expect(result.lastUpdate, midnightDateTime);

        final day = result.days[0];
        expect(
            day.events.any((tp) =>
                tp.dt != null && tp.dt!.hour == 0 && tp.dt!.minute == 0),
            isTrue);
      });

      test('should use current time when at parameter is null', () {
        // Act
        final before = DateTime.now();
        final result = TimeLogic.createEmptyTimeData();
        final after = DateTime.now();

        // Assert
        expect(
            result.lastUpdate.isAfter(before) ||
                result.lastUpdate.isAtSameMomentAs(before),
            isTrue);
        expect(
            result.lastUpdate.isBefore(after) ||
                result.lastUpdate.isAtSameMomentAs(after),
            isTrue);
      });
    });

    group('addEvent', () {
      test('should add an event correctly and update durations', () {
        // Arrange
        final initialTime = DateTime(2025, 3, 1, 10, 0);
        final timeData = TimeLogic.createEmptyTimeData(at: initialTime);
        final eventTime = initialTime.add(const Duration(minutes: 30));

        // Act
        final updatedData = TimeLogic.addEvent(timeData, eventTime);

        // Assert
        expect(updatedData.lastUpdate, eventTime);

        // Check that the day was updated
        final day = updatedData.days[updatedData.indices.today];
        expect(day.events.length, greaterThan(timeData.days[0].events.length));

        // Check that stats were updated
        // final newStat = updatedData.statData;
        // expect(newStat.lastUpdate, eventTime);

        // Check coordinates were updated
        expect(day.coordinates.isNotEmpty, isTrue);
      });

      test('should handle multiple event additions', () {
        // Arrange
        final initialTime = DateTime(2025, 3, 1, 10, 0);
        final timeData = TimeLogic.createEmptyTimeData(at: initialTime);

        // Act
        final firstUpdate = TimeLogic.addEvent(
            timeData, initialTime.add(const Duration(minutes: 30)));
        final secondUpdate = TimeLogic.addEvent(
            firstUpdate, initialTime.add(const Duration(minutes: 60)));
        final thirdUpdate = TimeLogic.addEvent(
            secondUpdate, initialTime.add(const Duration(minutes: 90)));

        // Assert
        final day = thirdUpdate.days[thirdUpdate.indices.today];
        expect(
            day.events.length, greaterThan(timeData.days[0].events.length + 2));

        // Verify increasing durations
        final durPoint = day.durPoint;
        expect(durPoint.dur.inMinutes, greaterThan(0));
      });

      test('should update statistics correctly', () {
        // Arrange
        final initialTime = DateTime(2025, 3, 1, 10, 0);
        final timeData = TimeLogic.createEmptyTimeData(at: initialTime);
        final eventTime = initialTime.add(const Duration(hours: 1));

        // Act
        final updatedData = TimeLogic.addEvent(timeData, eventTime);

        // Assert
        final stat = updatedData.statData;
        expect(stat, isNot(same(timeData.statData)));

        // Duration should have increased
        final initialDur = timeData.days[0].durPoint.dur;
        final updatedDur =
            updatedData.days[updatedData.indices.today].durPoint.dur;
        expect(updatedDur.inSeconds, greaterThan(initialDur.inSeconds));
      });
    });

    group('handleTic', () {
      test('should handle tic inside session', () {
        // Arrange
        final initialTime = DateTime(2025, 3, 1, 10, 0);
        final timeData = TimeLogic.createEmptyTimeData(at: initialTime);
        // Ensure session times span our test time
        final session = SessionData(
          sessionStartDt: initialTime,
          sessionEndDt: initialTime.add(const Duration(hours: 2)),
          dayStartTime: DtHelper.dayStartDt(initialTime),
          dayEndTime: DtHelper.dayEndDt(initialTime),
        );
        final updatedTimeData = timeData.copyWith(sessionData: session);

        // Tic time is inside session
        final ticTime = initialTime.add(const Duration(minutes: 30));

        // Act
        final result = TimeLogic.handleTic(
          timeData: updatedTimeData,
          tic: ticTime,
          saveData: mockSaveData,
        );

        // Assert
        expect(result.lastUpdate, ticTime);
        final day = result.days[result.indices.today];
        // Verify events were added
        expect(day.events.length,
            greaterThanOrEqualTo(timeData.days[0].events.length));
      });

      test('should handle tic outside session', () {
        // Arrange
        final initialTime = DateTime(2025, 3, 1, 10, 0);
        final timeData = TimeLogic.createEmptyTimeData(at: initialTime);
        // Create a session that doesn't include our tic time
        final session = SessionData(
          sessionStartDt: initialTime.add(const Duration(hours: 2)),
          sessionEndDt: initialTime.add(const Duration(hours: 4)),
          dayStartTime: DtHelper.dayStartDt(initialTime),
          dayEndTime: DtHelper.dayEndDt(initialTime),
        );
        final updatedTimeData = timeData.copyWith(sessionData: session);

        // Tic time is before session
        final ticTime = initialTime.add(const Duration(minutes: 30));

        // Act
        final result = TimeLogic.handleTic(
          timeData: updatedTimeData,
          tic: ticTime,
          saveData: mockSaveData,
        );

        // Assert
        expect(result.lastUpdate, ticTime);
        // Session should be updated to include current time
        expect(
            result.sessionData.sessionStartDt.isBefore(ticTime) ||
                result.sessionData.sessionStartDt.isAtSameMomentAs(ticTime),
            isTrue);
        expect(result.sessionData.sessionEndDt.isAfter(ticTime), isTrue);
      });

      test('should handle tic on different day', () {
        // Arrange
        final initialTime = DateTime(2025, 3, 1, 10, 0);
        final timeData = TimeLogic.createEmptyTimeData(at: initialTime);

        // Tic time is on next day
        final ticTime = initialTime.add(const Duration(days: 1));

        // Act
        final result = TimeLogic.handleTic(
          timeData: timeData,
          tic: ticTime,
          saveData: mockSaveData,
        );

        // Assert
        expect(result.lastUpdate, ticTime);
        // Should have added a new day
        expect(result.days.length, greaterThan(timeData.days.length));
        // The today index should be updated
        expect(result.indices.today, greaterThan(0));
      });

      test('should handle debug output correctly', () {
        // Arrange
        final initialTime = DateTime(2025, 3, 1, 10, 0);
        final timeData = TimeLogic.createEmptyTimeData(at: initialTime);
        final ticTime = initialTime.add(const Duration(minutes: 30));

        // No assert needed, just verifying it doesn't crash with debug = true
        final result = TimeLogic.handleTic(
          timeData: timeData,
          tic: ticTime,
          saveData: mockSaveData,
          debug: true,
        );

        expect(result, isNotNull);
      });
    });

    group('updateSession', () {
      test('should update session and recalculate coordinates', () {
        // Arrange
        final initialTime = DateTime(2025, 3, 1, 10, 0);
        final timeData = TimeLogic.createEmptyTimeData(at: initialTime);

        // New session with different times
        final newSession = SessionData(
          sessionStartDt: initialTime.add(const Duration(hours: 1)),
          sessionEndDt: initialTime.add(const Duration(hours: 3)),
          dayStartTime: DtHelper.dayStartDt(initialTime),
          dayEndTime: DtHelper.dayEndDt(initialTime),
        );

        // Act
        final result =
            TimeLogic.updateSession(timeData, newSession, initialTime);

        // Assert
        expect(result.sessionData, newSession);

        // Coordinates should be recalculated
        final day = result.days[result.indices.today];
        expect(day.coordinates, isNotEmpty);
        expect(day.coordinates, isNot(equals(timeData.days[0].coordinates)));
      });

      test('should handle session update with debug flag', () {
        // Arrange
        final initialTime = DateTime(2025, 3, 1, 10, 0);
        final timeData = TimeLogic.createEmptyTimeData(at: initialTime);

        final newSession = SessionData(
          sessionStartDt: initialTime.add(const Duration(hours: 1)),
          sessionEndDt: initialTime.add(const Duration(hours: 3)),
          dayStartTime: DtHelper.dayStartDt(initialTime),
          dayEndTime: DtHelper.dayEndDt(initialTime),
        );

        // Act - no assertions needed, just verifying it doesn't crash
        final result = TimeLogic.updateSession(
          timeData,
          newSession,
          initialTime,
          debug: true,
        );

        expect(result, isNotNull);
      });

      test('should update all relevant days coordinates', () {
        // Arrange
        final initialTime = DateTime(2025, 3, 1, 10, 0);
        // Create time data with multiple days
        var timeData = TimeLogic.createEmptyTimeData(at: initialTime);

        // Add another day
        final nextDayTime = initialTime.add(const Duration(days: 1));
        timeData = TimeLogic.handleTic(
          timeData: timeData,
          tic: nextDayTime,
          saveData: mockSaveData,
        );

        // New session
        final newSession = SessionData(
          sessionStartDt: nextDayTime.add(const Duration(hours: 1)),
          sessionEndDt: nextDayTime.add(const Duration(hours: 3)),
          dayStartTime: DtHelper.dayStartDt(nextDayTime),
          dayEndTime: DtHelper.dayEndDt(nextDayTime),
        );

        // Act
        final result =
            TimeLogic.updateSession(timeData, newSession, nextDayTime);

        // Assert
        // Both days should have coordinates
        expect(result.days[0].coordinates, isNotEmpty);
        expect(result.days[1].coordinates, isNotEmpty);
      });
    });

    group('Integration tests', () {
      test('should handle a complete workflow correctly', () {
        // Setup initial data
        final initialTime = DateTime(2025, 3, 1, 10, 0);
        var timeData = TimeLogic.createEmptyTimeData(at: initialTime);

        // 1. Add an event
        final eventTime = initialTime.add(const Duration(minutes: 30));
        timeData = TimeLogic.addEvent(timeData, eventTime);

        // 2. Handle a tic inside session
        final ticTime = eventTime.add(const Duration(minutes: 15));
        timeData = TimeLogic.handleTic(
          timeData: timeData,
          tic: ticTime,
          saveData: mockSaveData,
        );

        // 3. Update session
        final newSession = SessionData(
          sessionStartDt: ticTime,
          sessionEndDt: ticTime.add(const Duration(hours: 2)),
          dayStartTime: DateTime(ticTime.year, ticTime.month, ticTime.day, 8),
          dayEndTime: DtHelper.dayEndDt(ticTime),
        );
        timeData = TimeLogic.updateSession(timeData, newSession, ticTime);

        // 4. Handle tic on a different day
        final nextDayTime = initialTime.add(const Duration(days: 1));
        timeData = TimeLogic.handleTic(
          timeData: timeData,
          tic: nextDayTime,
          saveData: mockSaveData,
        );

        // 5. Add an event on the new day
        final newDayEventTime = nextDayTime.add(const Duration(hours: 1));
        timeData = TimeLogic.addEvent(timeData, newDayEventTime);

        // Assertions
        expect(timeData.days.length, 2);
        expect(timeData.indices.today, 1);
        expect(timeData.days[1].events.isNotEmpty, isTrue);

        // Check that statistics have been updated
        final stat = timeData.statData;
        expect(stat.maxDurReleventDays.inSeconds, greaterThan(0));
      });

      test('should handle edge case transitions correctly', () {
        // Setup with time just before midnight
        final nearMidnightTime = DateTime(2025, 3, 1, 23, 59);
        var timeData = TimeLogic.createEmptyTimeData(at: nearMidnightTime);

        // Add event
        timeData = TimeLogic.addEvent(timeData, nearMidnightTime);

        // Transition to next day (midnight)
        final midnightTime = DateTime(2025, 3, 2, 0, 0);
        timeData = TimeLogic.handleTic(
          timeData: timeData,
          tic: midnightTime,
          saveData: mockSaveData,
        );

        // Assertions
        expect(timeData.days.length, 2);
        expect(timeData.indices.today, 1);

        // Day indices should include both days
        expect(timeData.indices.weekIndices.length, 2);
        expect(timeData.indices.monthIndices.length, 2);
      });
    });
  });
}
