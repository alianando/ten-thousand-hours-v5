import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_entry_entity/time_point/time_point.dart';
import 'package:ten_thousands_hours/root/root.dart';

import '../../indices_entry/indices_provider.dart';
import '../coordinate_model.dart';

final continiousTodayCooPro = NotifierProvider<ContiniousTodayCooNot, List<C>>(
  ContiniousTodayCooNot.new,
);

class ContiniousTodayCooNot extends Notifier<List<C>> {
  @override
  List<C> build() {
    return [];
  }

  void calculate(
    List<TimePoint> timePoints, {
    DateTime? sessionStartTime,
    DateTime? sessionEndTime,
    Duration? maxSessionDuration,
    bool debug = false,
  }) {
    pout('calculate ContiniousTOdayCooNot', debug);
    int debugLevel = 2;
    if (timePoints.isEmpty) {
      pout('No time points found', debug, level: debugLevel);
      return;
    }
    sessionStartTime ??= DtHelper.dayStartDt(timePoints.first.dt);
    sessionEndTime ??= DtHelper.dayEndDt(timePoints.first.dt);
    maxSessionDuration ??= const Duration(hours: 10);
    final xRange = sessionEndTime.difference(sessionStartTime).inMilliseconds;
    final yRange = maxSessionDuration.inMilliseconds;
    const double z = 0;
    List<C> coordinates = timePoints
        .map((e) => C(
              x: e.dt.difference(sessionStartTime!).inMilliseconds / xRange,
              y: e.dur.inMilliseconds / yRange,
              z: z,
            ))
        .toList();

    /// if today add now dt
    if (DtHelper.isToday(sessionStartTime)) {
      final now = DateTime.now();
      final x = now.difference(sessionStartTime).inMilliseconds / xRange;
      final yVal = timePoints.last.typ == TimePointTyp.pause
          ? timePoints.last.dur.inMilliseconds
          : (timePoints.last.dur + now.difference(timePoints.last.dt))
              .inMilliseconds;
      final y = yVal / yRange;
      coordinates.add(C(x: x, y: y, z: z));
    }
    pout('coordinates $coordinates', debug, level: debugLevel);
    state = coordinates;
  }
}

final continiousOtherDaysCooPro =
    NotifierProvider<ContiniousOtherDaysCooNot, ListOfListOfC>(
  ContiniousOtherDaysCooNot.new,
);

class ContiniousOtherDaysCooNot extends Notifier<ListOfListOfC> {
  @override
  ListOfListOfC build() {
    final monthEntries = ref.watch(monthEntriesP);
    if (monthEntries.isEmpty) {
      return const ListOfListOfC(list: []);
    }
    final List<List<C>> otherDayCoordinates = monthEntries
        .map((e) => _calculateListOfC(e.events))
        .map((e) => e.list)
        .toList();
    debugPrint('otherDayCoordinates $otherDayCoordinates');
    return ListOfListOfC(list: otherDayCoordinates);
  }

  ListOfC _calculateListOfC(
    List<TimePoint> timePoints, {
    DateTime? sessionStartTime,
    DateTime? sessionEndTime,
    Duration? maxSessionDuration,
    bool debug = false,
  }) {
    pout('calculate ContiniousOtherDayCooNot', debug);
    int debugLevel = 2;
    if (timePoints.isEmpty) {
      pout('No time points found', true, level: debugLevel);
      return const ListOfC(list: []);
    }
    sessionStartTime ??= DtHelper.dayStartDt(timePoints.first.dt);
    sessionEndTime ??= DtHelper.dayEndDt(timePoints.first.dt);
    maxSessionDuration ??= const Duration(hours: 10);
    final xRange = sessionEndTime.difference(sessionStartTime).inMilliseconds;
    final yRange = maxSessionDuration.inMilliseconds;
    final double z = DtHelper.dayStartDt(DateTime.now())
        .difference(DtHelper.dayStartDt(sessionStartTime))
        .inDays
        .toDouble();
    List<C> dayCoordinates = [];
    for (final tp in timePoints) {
      final x = tp.dt.difference(sessionStartTime).inMilliseconds / xRange;
      final y = tp.dur.inMilliseconds / yRange;
      dayCoordinates.add(C(x: x, y: y, z: z));
    }
    return ListOfC(list: dayCoordinates);
  }
}
