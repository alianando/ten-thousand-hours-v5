import 'package:flutter/material.dart';
import 'package:ten_thousands_hours/models/app_data/coordinates/hourly_dur_distribution.dart';
import 'package:ten_thousands_hours/models/time_data/day_entry/day_services.dart';
import 'package:ten_thousands_hours/models/time_data/time_point/time_point.dart';
import 'package:ten_thousands_hours/root/root.dart';

import '../time_data/day_entry/day_model.dart';
import 'coordinates.dart';
import 'indecies_model.dart';
import 'session_data.dart';
import 'stat_data.dart';

class TimeData {
  final List<DayEntry> dayEntries;
  final Indices indices;
  final StatData statData;
  final Coordinates coordinates;
  final SessionData sessionData;

  TimeData({
    this.dayEntries = const [],
    this.indices = const Indices(),
    this.statData = const StatData(),
    this.coordinates = const Coordinates(),
    required this.sessionData,
  });

  TimeData copyWith({
    List<DayEntry>? dayEntries,
    Indices? indices,
    StatData? statData,
    Coordinates? coordinates,
    SessionData? sessionData,
  }) {
    return TimeData(
      dayEntries: dayEntries ?? this.dayEntries,
      indices: indices ?? this.indices,
      statData: statData ?? this.statData,
      coordinates: coordinates ?? this.coordinates,
      sessionData: sessionData ?? this.sessionData,
    );
  }

  DayEntry get todayEntry => dayEntries.isNotEmpty
      ? indices.today >= 0
          ? dayEntries[indices.today]
          : dayEntries.firstWhere(
              (element) => element.dt == DtHelper.dayStartDt(DateTime.now()),
              orElse: () => DayEntry.createEmptyDay(DateTime.now()),
            )
      : DayEntry.createEmptyDay(DateTime.now());

  DateTime get lastActiveUpdate => todayEntry.durPoint.dt;

  bool get isActive => todayEntry.events.last.typ == TimePointTyp.resume;

  static generateAppData(
    List<DayEntry> dayEntries, {
    bool debug = false,
  }) {
    // pout('AppData: generateAppData', debug);
    // pout('dayEntries: ${dayEntries.length}', debug);
    if (dayEntries.length <= 1) {
      debug = false;
    }
    List<DayEntry> days = List.from(dayEntries);
    days = days.map((e) => DayModelService.sanitize(e)).toList();
    Indices indices = IndicesServices.updateIndices(
      dayDates: days.map((e) => e.dt).toList(),
    );
    final todayNotFound = indices.today < 0;
    final now = DateTime.now();
    if (todayNotFound) {
      days.insert(0, DayEntry.createEmptyDay(now));
      days.sort((a, b) => a.dt.compareTo(b.dt));
      indices = IndicesServices.updateIndices(
        dayDates: days.map((e) => e.dt).toList(),
      );
    }
    // pout('sanitized days ${days.length}', debug);
    final session = SessionServices.createDefaultSession(now);
    final stat = StatServices.calculateStatistics(
      days: days,
      sessionStartDt: session.sessionStartDt,
      sessionEndDt: session.sessionEndDt,
      todayIndex: indices.today,
      allSessionIndices: indices.allSessionIndices,
    );

    /// calculate coordinates.
    final coordinates = CoordinateHelper.generateCoordinates(
      dayEntries: dayEntries,
      activeSessionIndex: indices.today,
      allSessionInices: indices.allSessionIndices,
      statData: stat,
      sessionData: session,
    );
    final updatedData = TimeData(
      dayEntries: days,
      indices: indices,
      statData: stat,
      coordinates: coordinates,
      sessionData: session,
    );
    if (debug) {
      debugPrint('## AppData: generateAppData');
      updatedData.printAppData();
    }
    return updatedData;
  }

  // 1. handel time update.
  // 1.1 handel different day. -> generateAppData.
  // 1.2 handel same day.
  // 2. handel session change.
  // 3. handel add event.

  TimeData handelSameSessionUpdate() {
    final oldMaxSessionDur = statData.maxDurReleventDays;
    final updatedStat = StatServices.refreshTodayDuration(
      oldStats: statData,
      today: todayEntry,
    );
    final newMaxSessionDur = updatedStat.maxDurReleventDays;
    if (newMaxSessionDur == oldMaxSessionDur) {
      final newCoordinates = CoordinateHelper.handelTodayDtUpdate(
        coordinates: coordinates,
        corePoints: dayEntries[indices.today].events,
        sessionStartDt: sessionData.sessionStartDt,
        sessionEndDt: sessionData.sessionEndDt,
        maxSessionDur: newMaxSessionDur,
        minSessionDur: Duration.zero,
      );
      return copyWith(
        statData: updatedStat,
        coordinates: newCoordinates,
      );
    }
    final newCoordinates = CoordinateHelper.handelTodayDtUpdate(
      coordinates: coordinates,
      corePoints: dayEntries[indices.today].events,
      sessionStartDt: sessionData.sessionStartDt,
      sessionEndDt: sessionData.sessionEndDt,
      maxSessionDur: newMaxSessionDur,
      minSessionDur: updatedStat.minDurReleventDays,
    );
    return copyWith(
      statData: updatedStat,
      coordinates: newCoordinates,
    );
  }

  TimeData handelSessionChange({
    required SessionData newSession,
  }) {
    final updatedStat = StatServices.handelSessionChange(
      oldStat: statData,
      sessionStartDt: newSession.sessionStartDt,
      sessionEndDt: newSession.sessionEndDt,
      days: dayEntries,
      todayIndex: indices.today,
      allSessionIndecies: indices.allSessionIndices,
    );

    final coordinates = CoordinateHelper.generateCoordinates(
      dayEntries: dayEntries,
      activeSessionIndex: indices.today,
      allSessionInices: indices.allSessionIndices,
      statData: updatedStat,
      sessionData: newSession,
    );

    return copyWith(
      sessionData: newSession,
      statData: updatedStat,
      coordinates: coordinates,
    );
  }

  TimeData handelAddEvent() {
    final updatedDayEntries = List<DayEntry>.from(dayEntries);
    final updatedTodayEntry = DayModelService.addActiveEvent(
      day: todayEntry,
      dtAt: DateTime.now(),
    );
    updatedDayEntries[indices.today] = updatedTodayEntry;

    final updatedStat = StatServices.refreshTodayDuration(
      oldStats: statData,
      today: updatedTodayEntry,
    );
    final coordinates = Coordinates(
      session: SessionOffsets.calculateSession(
        dayEntries: updatedDayEntries,
        activeSessionIndex: indices.today,
        allSessionInices: indices.allSessionIndices,
        statData: updatedStat,
        sessionData: sessionData,
      ),
    );

    return copyWith(
      dayEntries: updatedDayEntries,
      statData: updatedStat,
      coordinates: coordinates,
    );
  }

  static TimeData createEmptyAppData() {
    DayEntry emptyDay = DayEntry.createEmptyDay(DateTime.now());
    return TimeData.generateAppData([emptyDay]);
  }

  // static TimeData init() {
  //   return createEmptyAppData();
  // }

  void printAppData() {
    debugPrint('Days:');
    for (var element in dayEntries) {
      debugPrint('     ${element.toString()}');
    }
    debugPrint('indices:');
    debugPrint('     today: ${indices.today}');
    debugPrint('     weekIndices: ${indices.weekIndices}');
    debugPrint('     monthIndices: ${indices.monthIndices}');
    debugPrint('stat: ');
    debugPrint('     maxDurReleventDays: ${statData.maxDurReleventDays}');
    debugPrint('     minDurReleventDays: ${statData.minDurReleventDays}');
    debugPrint('     totalDur: ${statData.totalDur}');
    debugPrint('     todayDur: ${statData.todayDur}');
    debugPrint('session: ');
    debugPrint('     sessionStartDt: ${sessionData.sessionStartDt}');
    debugPrint('     sessionEndDt: ${sessionData.sessionEndDt}');
    debugPrint('coordinates: ');
    debugPrint('     session:');
    debugPrint('         today: ${coordinates.session.today.toString()}');
    debugPrint('         weekDays:');
    for (var element in coordinates.session.allDays) {
      debugPrint('             ${element.first} - ${element.last}');
    }
  }
}
