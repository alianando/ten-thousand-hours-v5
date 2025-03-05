import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ten_thousands_hours/models/time_data/model/day_model/day_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/indecies_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/session_data.dart';
import 'package:ten_thousands_hours/models/time_data/model/stat_data.dart';
import 'package:ten_thousands_hours/models/time_data/model/time_data.dart';
import 'package:ten_thousands_hours/models/time_data/time_logic.dart';

void main() {
  // create a group of tests
  group('time_data test', () {
    test('check creating test init day', () {
      // arrange
      final now = DateTime.now();
      final pastDt = now.subtract(const Duration(days: 1, hours: 2));
      final event1 = pastDt.add(const Duration(minutes: 10));
      final event2 = pastDt.add(const Duration(minutes: 25));
      final event3 = pastDt.add(const Duration(minutes: 87));
      final event4 = pastDt.add(const Duration(minutes: 90));
      final event5 = pastDt.add(const Duration(minutes: 120));
      final event6 = pastDt.add(const Duration(minutes: 150));

      // act
      final session = SessionServices.createDefaultSession(pastDt);
      DayModel dayData = DayModelService.createNewDay(pastDt);
      dayData = DayModelService.addActiveEvent(
        day: dayData,
        dtAt: pastDt.add(const Duration(minutes: 10)),
      );
      dayData = DayModelService.addActiveEvent(day: dayData, dtAt: event1);
      dayData = DayModelService.addActiveEvent(day: dayData, dtAt: event2);
      dayData = DayModelService.addActiveEvent(day: dayData, dtAt: event3);
      dayData = DayModelService.addActiveEvent(day: dayData, dtAt: event4);
      dayData = DayModelService.addActiveEvent(day: dayData, dtAt: event5);
      dayData = DayModelService.addActiveEvent(day: dayData, dtAt: event6);
      dayData = DayModelService.endDay(dayData);
      final stat = StatServices.updateStatistics(
        oldStat: StatServices.createDefaultStat(),
        durIncreased: dayData.durPoint.dur,
        potentialMaxDur: dayData.durPoint.dur,
        potentialMinDur: const Duration(),
      );
      dayData = DayModelService.updateCoordinates(
        day: dayData,
        timeAt: pastDt,
        sessionStartDt: session.sessionStartDt,
        sessionEndDt: session.sessionEndDt,
        coordinateMaxDur: stat.maxDurReleventDays,
        coordinateMinDur: stat.minDurReleventDays,
      );
      final List<DayModel> days = [dayData];
      final indecies = IndicesServices.updateIndices(
        dayDates: days.map((e) => e.dt).toList(),
      );
      final oldTImeData = TimeData(
        lastUpdate: pastDt,
        statData: stat,
        sessionData: session,
        indices: indecies,
        days: days,
      );
      // assert
      expect(oldTImeData.days.length, 1);
      // today is correctly added in indecies.
      //expect(oldTImeData.indecies.today, 0);
      // expect(oldTImeData.days[0].events.length, 9);
    });

    test('check tic Different day', () {
      // arrange
      final now = DateTime.now();
      final pastDt = now.subtract(const Duration(days: 1, hours: 2));
      final event1 = pastDt.add(const Duration(minutes: 10));
      final event2 = pastDt.add(const Duration(minutes: 25));
      final event3 = pastDt.add(const Duration(minutes: 87));
      final event4 = pastDt.add(const Duration(minutes: 90));
      final event5 = pastDt.add(const Duration(minutes: 120));
      final event6 = pastDt.add(const Duration(minutes: 150));

      // assert
      TimeData timeData = TimeLogic.createEmptyTimeData(at: pastDt);
      timeData = TimeLogic.addEvent(timeData, event1);
      timeData = TimeLogic.addEvent(timeData, event2);
      timeData = TimeLogic.addEvent(timeData, event3);
      timeData = TimeLogic.addEvent(timeData, event4);
      timeData = TimeLogic.addEvent(timeData, event5);
      timeData = TimeLogic.addEvent(timeData, event6);

      final newTimeData = TimeDataServices.ticDifferentDay(
        oldData: timeData,
        tic: now,
      );
      // assert
      // past day is added correctly.
      expect(timeData.days.length, 1);
      expect(timeData.indices.today, 0);
      expect(timeData.days[0].events.length, 8);
      // new day is added correctly.
      expect(newTimeData.days.length, 2);
      expect(newTimeData.indices.today, greaterThanOrEqualTo(0));
      // expect(newTimeData.indecies.weekIndices, [0, 1]);
      // expect(newTimeData.indecies.monthIndices, [0, 1]);
    });
  });
}
