// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:ten_thousands_hours/models/time_data/model/day_model/day_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/indecies_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/session_data.dart';
import 'package:ten_thousands_hours/models/time_data/model/stat_data.dart';

import 'day_model/day_services.dart';

/// Ctrl+Alt+B (Windows/Linux) = opne copilot chat.
/// Ctrl+B = oben file or debug tab.
/// Ctrl+j = open terminal.

class TimeData {
  final DateTime lastUpdate;
  final StatData statData;
  final SessionData sessionData;
  final Indices indices;
  final List<DayModel> days;

  const TimeData({
    required this.lastUpdate,
    required this.statData,
    required this.sessionData,
    required this.indices,
    required this.days,
  });

  Map<String, dynamic> toJson() {
    return {
      'lastUpdate': lastUpdate.toIso8601String(),
      'statData': statData.toJson(),
      'sessionData': sessionData.toJson(),
      'indecies': indices.toJson(),
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  factory TimeData.fromJson(Map<String, dynamic> json) {
    return TimeData(
      lastUpdate: DateTime.parse(json['lastUpdate']),
      statData: StatData.fromJson(json['statData']),
      sessionData: SessionData.fromJson(json['sessionData']),
      indices: Indices.fromJson(json['indecies']),
      days: (json['days'] as List).map((d) => DayModel.fromJson(d)).toList(),
    );
  }

  TimeData copyWith({
    DateTime? lastUpdate,
    StatData? statData,
    SessionData? sessionData,
    Indices? indecies,
    List<DayModel>? days,
  }) {
    return TimeData(
      lastUpdate: lastUpdate ?? this.lastUpdate,
      statData: statData ?? this.statData,
      sessionData: sessionData ?? this.sessionData,
      indices: indecies ?? this.indices,
      days: days ?? this.days,
    );
  }

  DayModel get today => days[indices.today];
  List<int> get weekIndices => indices.weekIndices;
  Duration get maxDurReleventDays => statData.maxDurReleventDays;
}

class TimeDataServices {
  const TimeDataServices._();

  static TimeData ticDifferentDay({
    required TimeData oldData,
    required DateTime tic,
    bool debug = false,
  }) {
    if (debug) {
      debugPrint('## -- ticDifferentDay -- ##');
    }
    final now = tic;
    final sessionData = SessionServices.createDefaultSession(now);
    List<DayModel> days = List<DayModel>.from(oldData.days);

    /// end the previous today.
    DayModel oldToday = days[oldData.indices.today].copyWith();
    final oldDur = oldToday.durPoint.dur;
    days[oldData.indices.today] = DayModelService.endDay(oldToday);
    final newDur = days[oldData.indices.today].durPoint.dur;
    final durIncreased = newDur - oldDur;
    StatData statData = oldData.statData.copyWith(
      totalDur: oldData.statData.totalDur + durIncreased,
    );
    final newToday = DayModelService.createNewDay(now);
    days.add(newToday);
    days.sort((a, b) => a.dt.compareTo(b.dt));
    if (debug) {
      debugPrint('${days.map((d) => d.durPoint.dt.day)}');
    }
    final newIndecies = IndicesServices.updateIndices(
      dayDates: days.map((d) => d.events.first.dt).toList(),
    );
    statData = StatServices.updateMaxMin(
      oldStats: statData,
      days: days,
      sessionStartDt: sessionData.sessionStartDt,
      sessionEndDt: sessionData.sessionEndDt,
      todayIndex: newIndecies.today,
      releventIndecies: newIndecies.weekIndices,
    );
    for (int i in newIndecies.weekIndices) {
      final day = days[i];
      days[i] = DayModelService.updateCoordinates(
        day: day,
        timeAt: day.durPoint.dt,
        sessionStartDt: sessionData.sessionStartDt,
        sessionEndDt: sessionData.sessionEndDt,
        coordinateMaxDur: statData.maxDurReleventDays,
        coordinateMinDur: statData.minDurReleventDays,
        isToday: i == newIndecies.today,
      );
    }

    return TimeData(
      lastUpdate: now,
      statData: statData,
      sessionData: sessionData,
      indices: newIndecies,
      days: days,
    );
  }

  static TimeData handleNowDtOutsideSession(
    TimeData timeData,
    DateTime nowDt,
  ) {
    DateTime sesEndDt = nowDt.add(const Duration(minutes: 30));
    if (!sesEndDt.isBefore(timeData.sessionData.dayEndTime)) {
      sesEndDt = timeData.sessionData.dayEndTime;
    }
    final newSession = timeData.sessionData.copyWith(
      sessionEndDt: sesEndDt,
    );

    return updateSession(timeData, newSession, nowDt);
  }

  static TimeData handleNowDtInsideSession(
    TimeData timeData,
    DateTime nowDt,
  ) {
    final session = timeData.sessionData;
    final stat = timeData.statData;
    final timeUpdatedToday = DayModelService.unactiveDtUpdate(
      day: timeData.today,
      dtAt: nowDt,
    );
    final updatedStat = StatServices.updateStatistics(
      oldStat: stat,
      durIncreased: timeUpdatedToday.durPoint.dur - timeData.today.durPoint.dur,
      potentialMaxDur: timeUpdatedToday.durPoint.dur,
      potentialMinDur: const Duration(),
    );
    final updatedToday = DayModelService.updateCoordinates(
      day: timeUpdatedToday,
      timeAt: nowDt,
      sessionStartDt: session.sessionStartDt,
      sessionEndDt: session.sessionEndDt,
      coordinateMaxDur: updatedStat.maxDurReleventDays,
      coordinateMinDur: updatedStat.minDurReleventDays,
      isToday: true,
    );
    final List<DayModel> updatedDays = List<DayModel>.from(timeData.days);

    updatedDays[timeData.indices.today] = updatedToday;

    /// update week indices
    /// jsut adding the new dt point.
    // for (int i = 0; i < timeData.indecies.weekIndices.length; i++) {
    //   if (i == timeData.indecies.today) {
    //     continue;
    //   }
    //   final day = timeData.days[timeData.indecies.weekIndices[i]];
    //   final DayModel updatedDay = DayModelService.unactiveDtUpdate(
    //     day: day,
    //     timeAt: nowDt,
    //   );
    //   updatedDays[timeData.indecies.weekIndices[i]] = updatedDay;
    // }

    return timeData.copyWith(
      lastUpdate: nowDt,
      statData: updatedStat,
      days: updatedDays,
    );
  }

  static TimeData updateSession(
    TimeData timeData,
    SessionData newSession,
    DateTime nowDt, {
    bool debug = false,
  }) {
    if (debug) {
      debugPrint('## -- updateSession -- ##');
    }
    final indecies = timeData.indices;
    final days = List<DayModel>.from(timeData.days);
    final updatedStat = StatServices.updateMaxMin(
      oldStats: timeData.statData,
      days: days,
      sessionStartDt: newSession.sessionStartDt,
      sessionEndDt: newSession.sessionEndDt,
      todayIndex: indecies.today,
      releventIndecies: indecies.weekIndices,
    );

    if (debug) {
      debugPrint('## -- min dur: ${updatedStat.minDurReleventDays} -- ##');
    }

    for (int i in indecies.weekIndices) {
      final day = days[i];
      final today = i == indecies.today;
      days[i] = DayModelService.updateCoordinates(
        day: day,
        timeAt: day.durPoint.dt,
        sessionStartDt: newSession.sessionStartDt,
        sessionEndDt: newSession.sessionEndDt,
        coordinateMaxDur: updatedStat.maxDurReleventDays,
        coordinateMinDur: updatedStat.minDurReleventDays,
        isToday: today,
      );
    }

    // Return updated time data
    return timeData.copyWith(
      sessionData: newSession,
      statData: updatedStat,
      days: days,
    );
  }

  static TimeData recalculate(TimeData timeData) {
    if (timeData.days.isEmpty) {
      return timeData;
    }
    List<DayModel> updatedDays = List<DayModel>.from(timeData.days);
    updatedDays.sort((a, b) => a.durPoint.dt.compareTo(b.durPoint.dt));
    final updatedIndices = IndicesServices.updateIndices(
      dayDates: updatedDays.map((day) => day.durPoint.dt).toList(),
    );
    final updatedSession = SessionServices.createDefaultSession(
      updatedDays.first.durPoint.dt,
    );
    final updatedStat = StatServices.updateMaxMin(
      oldStats: timeData.statData,
      days: updatedDays,
      sessionStartDt: updatedSession.sessionStartDt,
      sessionEndDt: updatedSession.sessionEndDt,
      todayIndex: updatedIndices.today,
      releventIndecies: updatedIndices.weekIndices,
    );
    for (int i in updatedIndices.weekIndices) {
      final day = updatedDays[i];
      updatedDays[i] = DayModelService.updateCoordinates(
        day: day,
        timeAt: day.durPoint.dt,
        sessionStartDt: updatedSession.sessionStartDt,
        sessionEndDt: updatedSession.sessionEndDt,
        coordinateMaxDur: updatedStat.maxDurReleventDays,
        coordinateMinDur: updatedStat.minDurReleventDays,
        isToday: i == updatedIndices.today,
      );
    }

    return TimeData(
      lastUpdate: updatedDays.first.dt,
      statData: updatedStat,
      sessionData: updatedSession,
      indices: updatedIndices,
      days: updatedDays,
    );
  }
}
