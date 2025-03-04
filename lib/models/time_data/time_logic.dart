import 'package:flutter/material.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';
import 'model/indecies_model.dart';
import 'model/stat_data.dart';
import 'model/time_data.dart';
import 'model/day_model.dart';
import 'model/session_data.dart';

class TimeLogic {
  const TimeLogic._();

  static TimeData createEmptyTimeData({DateTime? at}) {
    final now = at ?? DateTime.now();
    final session = SessionServices.createDefaultSession(now);
    final stat = StatServices.createDefaultStat();
    DayModel day = DayModelService.createNewDay(now);
    day = DayModelService.updateCoordinates(
      day: day,
      at: now,
      sessionStartDt: session.sessionStartDt,
      sessionEndDt: session.sessionEndDt,
      coordinateMaxDur: stat.maxDurReleventDays,
      coordinateMinDur: stat.minDurReleventDays,
    );
    const indecies = Indices(
      today: 0,
      weekIndices: [0],
      monthIndices: [0],
    );
    return TimeData(
      lastUpdate: now,
      statData: stat,
      sessionData: session,
      indices: indecies,
      days: [day],
    );
  }

  // add a event
  static TimeData addEvent(TimeData timeData, DateTime dt) {
    final now = dt;
    final session = timeData.sessionData;
    final stat = timeData.statData;
    final indecies = timeData.indices;
    final today = timeData.days[indecies.today];
    DayModel updatedToday = DayModelService.addEvent(day: today, at: now);
    final updatedStat = StatServices.updateStatistics(
      oldStat: stat,
      durIncreased: updatedToday.durPoint.dur - today.durPoint.dur,
      potentialMaxDur: updatedToday.durPoint.dur,
      potentialMinDur: const Duration(),
    );
    updatedToday = DayModelService.updateCoordinates(
      day: updatedToday,
      at: now,
      sessionStartDt: session.sessionStartDt,
      sessionEndDt: session.sessionEndDt,
      coordinateMaxDur: updatedStat.maxDurReleventDays,
      coordinateMinDur: updatedStat.minDurReleventDays,
      isToday: true,
    );
    List<DayModel> updatedDays = List<DayModel>.from(timeData.days);
    updatedDays[indecies.today] = updatedToday;
    // Return updated time data
    return timeData.copyWith(
      lastUpdate: now,
      statData: updatedStat,
      days: updatedDays,
    );
  }

  // handle a tic
  static TimeData handleTic({
    required TimeData timeData,
    required DateTime tic,
    required Function(TimeData) saveData,
    bool debug = false,
  }) {
    if (debug) debugPrint('## -- tic: ${DtUtils.dtToHMS(tic)}');
    final now = tic;
    final session = timeData.sessionData;

    if (!DtUtils.sameDay(now, session.sessionEndDt)) {
      if (debug) {
        debugPrint(
          '## different day than ${DtUtils.dtToHMS(session.dayEndTime)} ##',
        );
      }
      final updated =
          TimeDataServices.ticDifferentDay(oldData: timeData, tic: now);
      saveData(updated);
      return updated;
    }
    if (debug) {
      debugPrint(
        '${DtUtils.dtToHMS(session.sessionStartDt)} - ${DtUtils.dtToHMS(session.sessionEndDt)}',
      );
    }
    final inside = now.isAfter(session.sessionStartDt) &&
        now.isBefore(session.sessionEndDt);

    if (inside) {
      return TimeDataServices.handleNowDtInsideSession(timeData, now);
    }

    if (debug) {
      debugPrint(
        'outside session',
      );
    }
    final updated = TimeDataServices.handleNowDtOutsideSession(timeData, now);
    saveData(updated);
    return updated;
  }

  /// Updates days based on new session data
  static TimeData updateSession(
    TimeData timeData,
    SessionData newSession,
    DateTime nowDt, {
    bool debug = false,
  }) {
    return TimeDataServices.updateSession(
      timeData,
      newSession,
      nowDt,
      debug: debug,
    );
  }
}
