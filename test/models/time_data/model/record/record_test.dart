import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ten_thousands_hours/models/time_data/model/day_model/day_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/day_model/day_services.dart';
import 'package:ten_thousands_hours/models/time_data/model/record/record.dart';
import 'package:ten_thousands_hours/models/time_data/model/time_point/time_point.dart';

void main() {
  group('my tests', () {
    test('my test', () {
      expect(1, 1);
    });
    test('create empty record', () {
      final record = RecordServices.createEmptyRecord();
      expect(record.days.length, 1);
      expect(record.days.first.events.length, 2);
      expect(record.days.first.dt.year, DateTime.now().year);
      expect(record.days.first.dt.month, DateTime.now().month);
      expect(record.days.first.dt.day, DateTime.now().day);
      expect(record.days.first.dt.hour, 0);
      expect(record.days.first.dt.minute, 0);
      expect(record.days.first.dt.second, 0);
      expect(record.days.first.dt.millisecond, 0);
      expect(record.days.first.dt.microsecond, 0);
    });
  });

  group('Record Class Tests', () {
    test('creates Record instance correctly', () {
      final now = DateTime.now();
      final day = DayModelService.createNewDay(now);

      final record = Record(
        lastUpdate: now,
        days: [day],
      );

      expect(record.lastUpdate, now);
      expect(record.days.length, 1);
      expect(record.days.first.dt.year, now.year);
      expect(record.days.first.dt.month, now.month);
      expect(record.days.first.dt.day, now.day);
    });

    test('calculates totalAccumulatedTime correctly', () {
      final now = DateTime.now();

      // Create first day with 1 hour
      final day1 = DayModelService.createNewDay(now);
      final startTimePoint =
          TimePoint(dt: now, typ: TimePointTyp.resume, dur: Duration.zero);
      final endTimePoint = TimePoint(
          dt: now.add(const Duration(hours: 1)),
          typ: TimePointTyp.pause,
          dur: const Duration(hours: 1));

      final day1WithDuration = day1.copyWith(
        events: [startTimePoint, endTimePoint],
        durPoint: endTimePoint,
      );

      // Create second day with 2 hours
      final day2 =
          DayModelService.createNewDay(now.add(const Duration(days: 1)));
      final startTimePoint2 = TimePoint(
          dt: now.add(const Duration(days: 1)),
          typ: TimePointTyp.resume,
          dur: Duration.zero);
      final endTimePoint2 = TimePoint(
          dt: now.add(const Duration(days: 1, hours: 2)),
          typ: TimePointTyp.pause,
          dur: const Duration(hours: 2));

      final day2WithDuration = day2.copyWith(
        events: [startTimePoint2, endTimePoint2],
        durPoint: endTimePoint2,
      );

      final record = Record(
        lastUpdate: now,
        days: [day1WithDuration, day2WithDuration],
      );

      expect(record.totalAccumulatedTime, equals(const Duration(hours: 3)));
    });

    test('gets today correctly', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      // Create days
      final dayToday = DayModelService.createNewDay(today);
      final dayYesterday = DayModelService.createNewDay(yesterday);
      final dayTomorrow = DayModelService.createNewDay(tomorrow);

      final record = Record(
        lastUpdate: now,
        days: [dayYesterday, dayToday, dayTomorrow],
      );

      final todayResult = record.today;
      expect(todayResult, isNotNull);
      expect(todayResult!.dt.year, today.year);
      expect(todayResult.dt.month, today.month);
      expect(todayResult.dt.day, today.day);
    });

    test('returns null for today when today not in list', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      final dayYesterday = DayModelService.createNewDay(yesterday);
      final dayTomorrow = DayModelService.createNewDay(tomorrow);

      final record = Record(
        lastUpdate: now,
        days: [dayYesterday, dayTomorrow],
      );

      expect(record.today, isNull);
    });

    test('detects active tracking status correctly', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Create active day
      final day = DayModelService.createNewDay(today);
      final resumeTimePoint =
          TimePoint(dt: today, typ: TimePointTyp.resume, dur: Duration.zero);

      final activeDay = day.copyWith(
        events: [resumeTimePoint],
      );

      final activeRecord = Record(
        lastUpdate: now,
        days: [activeDay],
      );

      // Create inactive day
      final inactiveDay = day.copyWith(
        events: [
          resumeTimePoint,
          TimePoint(
              dt: today.add(const Duration(hours: 1)),
              typ: TimePointTyp.pause,
              dur: const Duration(hours: 1))
        ],
      );

      final inactiveRecord = Record(
        lastUpdate: now,
        days: [inactiveDay],
      );

      expect(activeRecord.isCurrentlyTracking, isTrue);
      expect(inactiveRecord.isCurrentlyTracking, isFalse);
    });

    test('gets recent active days correctly', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Create days with varying activity
      final days = <DayModel>[];

      // Today (active) - shouldn't be included in recentActiveDays
      final todayDay = DayModelService.createNewDay(today);
      final todayActive = todayDay.copyWith(
        events: [
          TimePoint(dt: today, typ: TimePointTyp.resume, dur: Duration.zero),
          TimePoint(
              dt: today.add(const Duration(hours: 1)),
              typ: TimePointTyp.pause,
              dur: const Duration(hours: 1))
        ],
        durPoint: TimePoint(
            dt: today.add(const Duration(hours: 1)),
            typ: TimePointTyp.pause,
            dur: const Duration(hours: 1)),
      );
      days.add(todayActive);

      // 3 days ago (active) - should be included
      final threeDaysAgo = today.subtract(const Duration(days: 3));
      final threeDaysAgoDay = DayModelService.createNewDay(threeDaysAgo);
      final threeDaysAgoActive = threeDaysAgoDay.copyWith(
        events: [
          TimePoint(
              dt: threeDaysAgo, typ: TimePointTyp.resume, dur: Duration.zero),
          TimePoint(
              dt: threeDaysAgo.add(const Duration(hours: 2)),
              typ: TimePointTyp.pause,
              dur: const Duration(hours: 2))
        ],
        durPoint: TimePoint(
            dt: threeDaysAgo.add(const Duration(hours: 2)),
            typ: TimePointTyp.pause,
            dur: const Duration(hours: 2)),
      );
      days.add(threeDaysAgoActive);

      // 8 days ago (active) - shouldn't be included (too old)
      final eightDaysAgo = today.subtract(const Duration(days: 8));
      final eightDaysAgoDay = DayModelService.createNewDay(eightDaysAgo);
      final eightDaysAgoActive = eightDaysAgoDay.copyWith(
        events: [
          TimePoint(
              dt: eightDaysAgo, typ: TimePointTyp.resume, dur: Duration.zero),
          TimePoint(
              dt: eightDaysAgo.add(const Duration(hours: 3)),
              typ: TimePointTyp.pause,
              dur: const Duration(hours: 3))
        ],
        durPoint: TimePoint(
            dt: eightDaysAgo.add(const Duration(hours: 3)),
            typ: TimePointTyp.pause,
            dur: const Duration(hours: 3)),
      );
      days.add(eightDaysAgoActive);

      final record = Record(
        lastUpdate: now,
        days: days,
      );

      final recentActive = record.recentActiveDays;
      expect(recentActive.length, 1); // Only the 3-days ago should be included
      expect(recentActive.first.dt.day, threeDaysAgo.day);
      expect(recentActive.first.dt.month, threeDaysAgo.month);
      expect(recentActive.first.dt.year, threeDaysAgo.year);
    });

    test('serializes to JSON correctly', () {
      final now = DateTime.now();
      final day = DayModelService.createNewDay(now);

      final record = Record(
        lastUpdate: now,
        days: [day],
      );

      final json = record.toJson();

      expect(json['lastUpdate'], now.toIso8601String());
      expect(json['days'], isNotEmpty);
      expect(json['days'].length, 1);
      expect(json['days'][0], equals(day.toJson()));
    });

    test('serializes to JSON string correctly', () {
      final now = DateTime.now();
      final day = DayModelService.createNewDay(now);

      final record = Record(
        lastUpdate: now,
        days: [day],
      );

      final jsonString = record.toJsonString();

      // Verify string can be parsed back to JSON
      final decodedJson = jsonDecode(jsonString);
      expect(decodedJson['lastUpdate'], now.toIso8601String());
      expect(decodedJson['days'], isNotEmpty);
    });

    test('creates from JSON correctly', () {
      final now = DateTime.now();
      final day = DayModelService.createNewDay(now);
      final originalRecord = Record(
        lastUpdate: now,
        days: [day],
      );

      final json = originalRecord.toJson();
      final recreatedRecord = Record.fromJson(json);

      expect(recreatedRecord.lastUpdate.toIso8601String(),
          equals(now.toIso8601String()));
      expect(recreatedRecord.days.length, 1);
    });

    test('creates from JSON string correctly', () {
      final now = DateTime.now();
      final day = DayModelService.createNewDay(now);
      final originalRecord = Record(
        lastUpdate: now,
        days: [day],
      );

      final jsonString = originalRecord.toJsonString();
      final recreatedRecord = Record.fromJsonString(jsonString);

      expect(recreatedRecord.lastUpdate.toIso8601String(),
          equals(now.toIso8601String()));
      expect(recreatedRecord.days.length, 1);
    });

    test('handles malformed JSON gracefully', () {
      final malformedJson = {
        'lastUpdate': 'not-a-date',
        'days': 'not-an-array'
      };

      // Should not throw
      final record = Record.fromJson(malformedJson);
      expect(record, isA<Record>());
      expect(record.days, isEmpty);
    });

    test('handles malformed JSON string gracefully', () {
      const malformedJsonString = '{"lastUpdate": "broken", "days": []}';

      // Should not throw
      final record = Record.fromJsonString(malformedJsonString);
      expect(record, isA<Record>());
      expect(record.days, isEmpty);
    });

    test('copyWith creates correct copy', () {
      final now = DateTime.now();
      final later = now.add(const Duration(hours: 1));
      final day1 = DayModelService.createNewDay(now);
      final day2 = DayModelService.createNewDay(later);

      final original = Record(
        lastUpdate: now,
        days: [day1],
      );

      // Test replacing all fields
      final fullCopy = original.copyWith(
        lastUpdate: later,
        days: [day1, day2],
      );

      expect(fullCopy.lastUpdate, equals(later));
      expect(fullCopy.days.length, equals(2));

      // Test replacing just one field
      final partialCopy = original.copyWith(
        lastUpdate: later,
      );

      expect(partialCopy.lastUpdate, equals(later));
      expect(partialCopy.days.length, equals(1));
      expect(partialCopy.days.first, equals(day1));
    });

    test('isSameDay functionality works correctly', () {
      final now = DateTime.now();
      final sameDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final differentDay = DateTime(now.year, now.month, now.day + 1);

      // Test the functionality indirectly through a public method
      // For example, we can check if days with same date are treated as the same day
      final record = Record(
        lastUpdate: now,
        days: [
          DayModelService.createNewDay(now),
          DayModelService.createNewDay(differentDay),
        ],
      );

      expect(record.days.length, 2);
      expect(record.days.any((day) => day.dt.day == now.day), isTrue);
      expect(record.days.any((day) => day.dt.day == differentDay.day), isTrue);

      // Test that today method works with same-day functionality
      final todayRecord = Record(
        lastUpdate: now,
        days: [DayModelService.createNewDay(sameDay)],
      );

      expect(todayRecord.today, isNotNull);
      expect(todayRecord.today!.dt.day, now.day);
    });
  });

  group('RecordServices Tests', () {
    test('updates duration correctly', () {
      final now = DateTime.now();

      // Create record with active tracking
      final day = DayModelService.createNewDay(now);
      final resumePoint = TimePoint(
        dt: now,
        typ: TimePointTyp.resume,
        dur: Duration.zero,
      );
      final activeDay = day.copyWith(
        durPoint: resumePoint,
        events: [resumePoint],
      );

      final record = Record(
        lastUpdate: now,
        days: [activeDay],
      );

      // Update duration after 30 minutes
      final thirtyMinLater = now.add(const Duration(minutes: 30));
      final updatedRecord = RecordServices.updateDuration(
        record,
        thirtyMinLater,
        debug: true,
      );

      expect(updatedRecord.days.length, 1);
      // expect(updatedRecord.days.first.events.length, 1);
      // expect(
      //   updatedRecord.days.first.durPoint.dur,
      //   equals(const Duration(minutes: 30)),
      // );
      // expect(updatedRecord.days.first.durPoint.typ, TimePointTyp.pause);

      // expect(updatedRecord.lastUpdate, equals(thirtyMinLater));
    });

    test('creates empty record correctly', () {
      final record = RecordServices.createEmptyRecord();

      expect(record.days.length, 1);
      expect(record.days.first.events.length, 2);
      expect(record.days.first.dt.day, DateTime.now().day);
      expect(record.lastUpdate.day, DateTime.now().day);
    });

    test('adds active event correctly', () {
      final now = DateTime.now();
      final record = Record(
        lastUpdate: now,
        days: [DayModelService.createNewDay(now)],
      );

      final updatedRecord = RecordServices.addActiveEvent(record, now);

      expect(record.days.first.events.length, 2);
      expect(updatedRecord.days.first.events.length, 2);
      // expect(updatedRecord.days.first.events.first.typ,
      //     equals(TimePointTyp.resume));
      // expect(updatedRecord.isCurrentlyTracking, isTrue);

      // Add another event to toggle it off
      final pausedRecord = RecordServices.addActiveEvent(
          updatedRecord, now.add(const Duration(minutes: 30)));

      expect(pausedRecord.days.first.events.length, 3);
      // expect(
      //     pausedRecord.days.first.events.last.typ, equals(TimePointTyp.pause));
      // expect(pausedRecord.isCurrentlyTracking, isFalse);
    });

    test('adds active event to new day if needed', () {
      // it does not work like this.
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();

      final record = Record(
        lastUpdate: yesterday,
        days: [DayModelService.createNewDay(yesterday)],
      );

      final updatedRecord = RecordServices.addActiveEvent(record, today);

      expect(updatedRecord.days.length, 2);
      expect(updatedRecord.today, isNotNull);
      expect(updatedRecord.today!.events.length, 2);
    });

    test('sanitizes record correctly', () {
      final now = DateTime.now();

      // Create record with active tracking
      final day = DayModelService.createNewDay(now);
      final resumePoint =
          TimePoint(dt: now, typ: TimePointTyp.resume, dur: Duration.zero);
      final activeDay = day.copyWith(
        events: [resumePoint],
      );

      final record = Record(
        lastUpdate: now,
        days: [activeDay],
      );

      // Sanitize should add a pause event at the day's end time
      final sanitized = RecordServices.sanitizeRecord(record);

      expect(sanitized.days.first.events.length, 2);
      expect(
          sanitized.days.first.events.first.typ, equals(TimePointTyp.resume));
      expect(sanitized.days.first.events.last.typ, equals(TimePointTyp.pause));
      expect(sanitized.isCurrentlyTracking, isFalse);
    });

    test('ends day correctly', () {
      final now = DateTime.now();

      // Create record with active tracking
      final day = DayModelService.createNewDay(now);
      final resumePoint =
          TimePoint(dt: now, typ: TimePointTyp.resume, dur: Duration.zero);
      final activeDay = day.copyWith(
        events: [resumePoint],
      );

      final record = Record(
        lastUpdate: now,
        days: [activeDay],
      );

      final ended = RecordServices.endDay(record, now);

      expect(ended.days.first.events.length, 2);
      expect(ended.days.first.events.last.typ, equals(TimePointTyp.pause));
      expect(ended.isCurrentlyTracking, isFalse);
    });

    test('merges records correctly', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      // First record has data for yesterday
      final day1 = DayModelService.createNewDay(yesterday);
      final yesterdayActive = day1.copyWith(
        events: [
          TimePoint(
              dt: yesterday, typ: TimePointTyp.resume, dur: Duration.zero),
          TimePoint(
              dt: yesterday.add(const Duration(hours: 1)),
              typ: TimePointTyp.pause,
              dur: const Duration(hours: 1))
        ],
        durPoint: TimePoint(
            dt: yesterday.add(const Duration(hours: 1)),
            typ: TimePointTyp.pause,
            dur: const Duration(hours: 1)),
      );

      final record1 = Record(
        lastUpdate: yesterday,
        days: [yesterdayActive],
      );

      // Second record has data for today
      final day2 = DayModelService.createNewDay(now);
      final todayActive = day2.copyWith(
        events: [
          TimePoint(dt: now, typ: TimePointTyp.resume, dur: Duration.zero),
          TimePoint(
              dt: now.add(const Duration(hours: 2)),
              typ: TimePointTyp.pause,
              dur: const Duration(hours: 2))
        ],
        durPoint: TimePoint(
            dt: now.add(const Duration(hours: 2)),
            typ: TimePointTyp.pause,
            dur: const Duration(hours: 2)),
      );

      final record2 = Record(
        lastUpdate: now,
        days: [todayActive],
      );

      final merged = RecordServices.mergeRecords(record1, record2);

      expect(merged.days.length, 2);
      expect(merged.lastUpdate, equals(now));
      expect(merged.totalAccumulatedTime, equals(const Duration(hours: 3)));
    });

    test('merges overlapping days correctly', () {
      final now = DateTime.now();

      // First record has one session for today
      final day1 = DayModelService.createNewDay(now);
      final session1Start =
          TimePoint(dt: now, typ: TimePointTyp.resume, dur: Duration.zero);
      final session1End = TimePoint(
          dt: now.add(const Duration(hours: 1)),
          typ: TimePointTyp.pause,
          dur: const Duration(hours: 1));
      final day1WithSession = day1.copyWith(
        events: [session1Start, session1End],
        durPoint: session1End,
      );

      final record1 = Record(
        lastUpdate: now,
        days: [day1WithSession],
      );

      // Second record has another session for the same day
      final day2 = DayModelService.createNewDay(now);
      final session2Start = TimePoint(
          dt: now.add(const Duration(hours: 2)),
          typ: TimePointTyp.resume,
          dur: Duration.zero);
      final session2End = TimePoint(
          dt: now.add(const Duration(hours: 3)),
          typ: TimePointTyp.pause,
          dur: const Duration(hours: 1));
      final day2WithSession = day2.copyWith(
        events: [session2Start, session2End],
        durPoint: session2End,
      );

      final record2 = Record(
        lastUpdate: now,
        days: [day2WithSession],
      );

      final merged = RecordServices.mergeRecords(record1, record2);

      expect(merged.days.length, 1);
      expect(merged.days.first.events.length, 4);
      expect(merged.days.first.sessions.length, 2);
      expect(merged.days.first.durPoint.dur, equals(const Duration(hours: 2)));
    });

    test('handles merging records with malformed days', () {
      final now = DateTime.now();

      // Create a normal record
      final normalDay = DayModelService.createNewDay(now);
      final normalRecord = Record(
        lastUpdate: now,
        days: [normalDay],
      );

      // Create a problematic record with a minimal valid day
      final minimalDay = DayModel(
        dt: now,
        events: [],
        durPoint:
            TimePoint(dt: now, dur: const Duration(), typ: TimePointTyp.pause),
      );

      final problematicRecord = Record(
        lastUpdate: now,
        days: [minimalDay],
      );

      // Merging should work without throwing
      final merged =
          RecordServices.mergeRecords(normalRecord, problematicRecord);

      expect(merged.days.length, 1);
      expect(merged.days.first.dt.day, now.day);
    });

    test('handles merge conflicts by keeping most recent data', () {
      final now = DateTime.now();
      final earlier = now.subtract(const Duration(hours: 2));
      final later = now.add(const Duration(hours: 2));

      // First record has earlier session
      final day1 = DayModelService.createNewDay(now);
      final session1Start =
          TimePoint(dt: earlier, typ: TimePointTyp.resume, dur: Duration.zero);
      final session1End = TimePoint(
          dt: now, typ: TimePointTyp.pause, dur: const Duration(hours: 2));
      final day1WithSession = day1.copyWith(
        events: [session1Start, session1End],
        durPoint: TimePoint(
            dt: now, dur: const Duration(hours: 2), typ: TimePointTyp.pause),
      );

      // Second record has later session
      final day2 = DayModelService.createNewDay(now);
      final session2Start =
          TimePoint(dt: now, typ: TimePointTyp.resume, dur: Duration.zero);
      final session2End = TimePoint(
          dt: later, typ: TimePointTyp.pause, dur: const Duration(hours: 2));
      final day2WithSession = day2.copyWith(
        events: [session2Start, session2End],
        durPoint: TimePoint(
            dt: later, dur: const Duration(hours: 2), typ: TimePointTyp.pause),
      );

      final record1 = Record(
        lastUpdate: now,
        days: [day1WithSession],
      );

      final record2 = Record(
        lastUpdate: later,
        days: [day2WithSession],
      );

      final merged = RecordServices.mergeRecords(record1, record2);

      expect(merged.days.length, 1);
      expect(merged.days.first.events.length, 4); // Both sessions combined
      expect(merged.days.first.sessions.length, 2); // Both sessions preserved
      expect(merged.days.first.durPoint.dur,
          equals(const Duration(hours: 4))); // Total duration combined
      expect(merged.lastUpdate, equals(later)); // Later timestamp used
    });

    test('exports to CSV correctly', () {
      final now = DateTime.now();

      // Create a day with activity
      final day = DayModelService.createNewDay(now);
      final startTimePoint =
          TimePoint(dt: now, typ: TimePointTyp.resume, dur: Duration.zero);
      final endTimePoint = TimePoint(
          dt: now.add(const Duration(hours: 1)),
          typ: TimePointTyp.pause,
          dur: const Duration(hours: 1));

      final dayWithActivity = day.copyWith(
        events: [startTimePoint, endTimePoint],
        dt: startTimePoint.dt,
        durPoint: endTimePoint,
        // Assuming the DayModel class has a different way to store sessions
        // or doesn't have this property at all
      );

      final record = Record(
        lastUpdate: now,
        days: [dayWithActivity],
      );

      final csv = RecordServices.exportToCsv(record);

      expect(csv, isA<String>());
      expect(csv, contains('Time Tracking Data Export'));
      expect(csv, contains('Total Accumulated Time'));
      expect(
          csv,
          contains(
              'Date,Total Duration (minutes),Sessions Count,Most Active Period'));

      // Should contain day's data
      final formattedDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(csv, contains(formattedDate));
      expect(csv, contains('60')); // 60 minutes
    });

    test('handles empty record CSV export', () {
      final now = DateTime.now();
      final emptyDay = DayModelService.createNewDay(now);

      final record = Record(
        lastUpdate: now,
        days: [emptyDay],
      );

      final csv = RecordServices.exportToCsv(record);

      expect(csv, isA<String>());
      expect(csv, contains('Time Tracking Data Export'));
      expect(csv, contains('Total Accumulated Time (hours): 0.0'));
      // Should not contain any day data rows since there's no activity
    });

    test('save and load operations use correct functions', () async {
      final now = DateTime.now();
      final day = DayModelService.createNewDay(now);

      final record = Record(
        lastUpdate: now,
        days: [day],
      );

      // Mock storage and database functions
      String? storedData;
      Map<String, dynamic>? databaseData;

      Future<void> mockSaveToStorage(String data) async {
        storedData = data;
      }

      Future<void> mockSaveToDatabase(Map<String, dynamic> data) async {
        databaseData = data;
      }

      // Test save operation
      final saveResult = await RecordServices.saveRecord(
          record, mockSaveToStorage, mockSaveToDatabase);

      expect(saveResult, isTrue);
      expect(storedData, isNotNull);
      expect(databaseData, isNotNull);
      expect(jsonDecode(storedData!), equals(record.toJson()));
      expect(databaseData, equals(record.toJson()));

      // Test load operation
      Future<String?> mockLoadFromStorage() async {
        return storedData;
      }

      Future<Map<String, dynamic>?> mockLoadFromDatabase() async {
        return databaseData;
      }

      final loadedRecord = await RecordServices.loadRecord(
          mockLoadFromStorage, mockLoadFromDatabase);

      expect(loadedRecord, isNotNull);
      expect(loadedRecord!.lastUpdate.toIso8601String(),
          equals(now.toIso8601String()));
      expect(loadedRecord.days.length, equals(1));
    });

    test('load operation handles storage failures gracefully', () async {
      // Mock functions that return exceptions
      Future<String?> mockLoadFromStorageFailure() async {
        throw Exception('Storage failure');
      }

      Future<Map<String, dynamic>?> mockLoadFromDatabaseFailure() async {
        throw Exception('Database failure');
      }

      // Should return null without throwing
      final loadedRecord = await RecordServices.loadRecord(
          mockLoadFromStorageFailure, mockLoadFromDatabaseFailure);

      expect(loadedRecord, isNull);
    });

    test('load operation prefers local when both available', () async {
      final now = DateTime.now();
      final localTime = now;
      final dbTime = now.subtract(const Duration(hours: 1));

      final localDay = DayModelService.createNewDay(now);
      final localRecord = Record(
        lastUpdate: localTime,
        days: [localDay],
      );

      final dbDay = DayModelService.createNewDay(now);
      final dbRecord = Record(
        lastUpdate: dbTime,
        days: [dbDay],
      );

      // Mock storage and database functions
      Future<String?> mockLoadFromStorage() async {
        return localRecord.toJsonString();
      }

      Future<Map<String, dynamic>?> mockLoadFromDatabase() async {
        return dbRecord.toJson();
      }

      // Load operation should merge, with local data getting precedence
      final loadedRecord = await RecordServices.loadRecord(
          mockLoadFromStorage, mockLoadFromDatabase);

      expect(loadedRecord, isNotNull);
      expect(
          loadedRecord!.lastUpdate, equals(localTime)); // Should use local time
    });

    test('handles record with no days', () {
      final now = DateTime.now();

      final emptyRecord = Record(
        lastUpdate: now,
        days: [],
      );

      // Various operations should handle empty days list
      expect(emptyRecord.totalAccumulatedTime, equals(Duration.zero));
      expect(emptyRecord.today, isNull);
      expect(emptyRecord.isCurrentlyTracking, isFalse);
      expect(emptyRecord.recentActiveDays, isEmpty);

      // Serialization should work
      final json = emptyRecord.toJson();
      expect(json['days'], isEmpty);

      // Deserialization should work
      final recreated = Record.fromJson(json);
      expect(recreated.days, isEmpty);
    });

    test('handles extremely large day collections efficiently', () {
      final now = DateTime.now();

      // Create a large collection of days
      final days = <DayModel>[];
      for (int i = 0; i < 365; i++) {
        final date = now.subtract(Duration(days: i));
        final day = DayModelService.createNewDay(date);
        days.add(day);
      }

      final largeRecord = Record(
        lastUpdate: now,
        days: days,
      );

      // Operations should still be efficient
      expect(() => largeRecord.totalAccumulatedTime, returnsNormally);
      expect(() => largeRecord.today, returnsNormally);
      expect(() => largeRecord.recentActiveDays, returnsNormally);
      expect(() => largeRecord.toJson(), returnsNormally);

      // Time how long serialization takes
      final stopwatch = Stopwatch()..start();
      final json = largeRecord.toJson();
      stopwatch.stop();

      // Serialization should be reasonably fast (under 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(json['days'].length, equals(365));
    });

    test('load operation handles partial data', () async {
      final now = DateTime.now();

      // Create a partial record in storage
      final storageDay =
          DayModelService.createNewDay(now.subtract(const Duration(days: 1)));
      final storageRecord = Record(
        lastUpdate: now.subtract(const Duration(days: 1)),
        days: [storageDay],
      );

      // Create a different partial record in database
      final dbDay = DayModelService.createNewDay(now);
      final dbRecord = Record(
        lastUpdate: now,
        days: [dbDay],
      );

      // Mock functions
      Future<String?> mockLoadFromStorage() async {
        return storageRecord.toJsonString();
      }

      Future<Map<String, dynamic>?> mockLoadFromDatabase() async {
        return dbRecord.toJson();
      }

      // Should merge the records
      final loadedRecord = await RecordServices.loadRecord(
          mockLoadFromStorage, mockLoadFromDatabase);

      expect(loadedRecord, isNotNull);
      expect(loadedRecord!.days.length, equals(2)); // Both days included
      expect(loadedRecord.lastUpdate, equals(now)); // Latest timestamp
    });

    test('load operation handles missing database gracefully', () async {
      final now = DateTime.now();

      // Create a record in storage only
      final storageDay = DayModelService.createNewDay(now);
      final storageRecord = Record(
        lastUpdate: now,
        days: [storageDay],
      );

      // Mock functions
      Future<String?> mockLoadFromStorage() async {
        return storageRecord.toJsonString();
      }

      Future<Map<String, dynamic>?> mockLoadFromDatabase() async {
        return null; // Database returns no data
      }

      // Should still load from storage
      final loadedRecord = await RecordServices.loadRecord(
          mockLoadFromStorage, mockLoadFromDatabase);

      expect(loadedRecord, isNotNull);
      expect(loadedRecord!.days.length, equals(1));
      expect(loadedRecord.lastUpdate, equals(now));
    });

    test('load operation handles missing storage gracefully', () async {
      final now = DateTime.now();

      // Create a record in database only
      final dbDay = DayModelService.createNewDay(now);
      final dbRecord = Record(
        lastUpdate: now,
        days: [dbDay],
      );

      // Mock functions
      Future<String?> mockLoadFromStorage() async {
        return null; // Storage returns no data
      }

      Future<Map<String, dynamic>?> mockLoadFromDatabase() async {
        return dbRecord.toJson();
      }

      // Should load from database
      final loadedRecord = await RecordServices.loadRecord(
          mockLoadFromStorage, mockLoadFromDatabase);

      expect(loadedRecord, isNotNull);
      expect(loadedRecord!.days.length, equals(1));
      expect(loadedRecord.lastUpdate, equals(now));
    });
  });
}
