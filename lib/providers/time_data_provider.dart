import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ten_thousands_hours/models/time_data/time_point/time_point.dart';
import 'package:ten_thousands_hours/providers/storage_pro.dart';
import 'package:ten_thousands_hours/root/root.dart';

import '../models/app_data/time_data.dart';
import '../models/time_data/day_entry/day_model.dart';

final timeDataPro = NotifierProvider<TimeDataNotifier, TimeData>(
  TimeDataNotifier.new,
);

class TimeDataNotifier extends Notifier<TimeData> {
  @override
  TimeData build() {
    return TimeData.createEmptyAppData();
  }

  /// Database key for saving/retrieving record
  // final String _recordKey = 'time_record';
  final String _updateDtKey = 'updated_at';
  final String _dayEntriesKey = 'day_entries';

  void initTimeData({bool debug = false}) async {
    try {
      pout('InitTimeData <- TimeDataNotifier', debug);
      final local = ref.read(storageProvider);
      final localLastUpdateString = local.getString(_updateDtKey);
      DateTime localUpdated = DateTime(1999, 3, 3);
      if (localLastUpdateString != null) {
        localUpdated = DateTime.parse(localLastUpdateString);
        pout(' LocalData', debug);
        pout('    $localUpdated', debug);
        final localDayString = local.getString(_dayEntriesKey);
        if (localDayString != null) {
          final localDay = jsonDecode(localDayString)
              .map((e) {
                return DayEntry.fromJson(e);
              })
              .whereType<DayEntry>()
              .toList();
          // debugPrint('Loaded from local storage: $localDay');
          final timeData = TimeData.generateAppData(
            localDay,
            debug: true,
          );
          state = timeData;
          pout('    added successfully', debug);
        }
      } else {
        pout('    null', debug);
      }
      final response = await Supabase.instance.client
          .from('time_data_db')
          .select()
          // .eq('user_id',
          //     Supabase.instance.client.auth.currentUser?.id ?? 'anonymous')
          // .eq('email', 'alianando44@gmail.com')
          .eq('id', 1)
          .single();

      final dayJson = response[_dayEntriesKey];
      final lastUpdate = response[_updateDtKey];
      pout('supabase', debug);
      if (lastUpdate == null) {
        pout('   null', debug);
        return null;
      }
      final supLastUpdateDt = DateTime.parse(lastUpdate);
      pout('    $supLastUpdateDt', debug);
      final smaeYear = supLastUpdateDt.year == localUpdated.year;
      final sameMonth = supLastUpdateDt.month == localUpdated.month;
      final sameDay = supLastUpdateDt.day == localUpdated.day;
      final sameHour = supLastUpdateDt.hour == localUpdated.hour;
      final sameMinute = supLastUpdateDt.minute == localUpdated.minute;
      final sameSecond = supLastUpdateDt.second == localUpdated.second;
      final sameDt = smaeYear &&
          sameMonth &&
          sameDay &&
          sameHour &&
          sameMinute &&
          sameSecond;
      if (sameDt) {
        pout('    Same dt', debug);
        return null;
      }
      if (smaeYear && sameMonth && sameDay) {
        pout('    Same day', debug);
        return null;
      }
      if (supLastUpdateDt.isAtSameMomentAs(localUpdated)) {
        pout('    Identical', debug);
        return null;
      }
      if (supLastUpdateDt.isBefore(localUpdated)) {
        pout('    Old', debug);
        return null;
      }
      if (supLastUpdateDt.isAfter(localUpdated)) {
        pout(
          '    difference is by ${supLastUpdateDt.difference(localUpdated)}',
          debug,
        );
      }

      final record = dayJson
          .map((e) {
            return DayEntry.fromJson(e);
          })
          .whereType<DayEntry>()
          .toList();
      final TimeData timeData = TimeData.generateAppData(
        record,
        debug: false,
      );
      // pout(dayJson.toString(), debug);
      // pout(record.last.events.last.toString(), debug);
      // pout(timeData.todayEntry.events.last.toString(), debug);
      // pout(timeData.isTodayActive.toString(), debug);

      state = timeData;
      pout('    supabase added.', debug);
    } catch (e) {
      debugPrint('Error initializing record: $e');
    }
  }

  void handelSessionChange({
    required DateTime sessionStartDt,
    required DateTime sessionEndDt,
  }) {
    final oldData = state.copyWith();

    state = oldData.handelSessionChange(
      newSession: oldData.sessionData.copyWith(
        sessionStartDt: sessionStartDt,
        sessionEndDt: sessionEndDt,
      ),
    );
  }

  void handelDtUpdate() {
    final DateTime now = DateTime.now();
    final oldData = state.copyWith();
    final todayEntry = oldData.dayEntries[oldData.indices.today];
    final dayUnchanged = todayEntry.dt.day == now.day &&
        todayEntry.dt.month == now.month &&
        todayEntry.dt.year == now.year;
    if (!dayUnchanged) {
      final newData = TimeData.generateAppData(
        oldData.dayEntries,
        debug: false,
      );
      // save it.
      state = newData;
      saveData();
      return;
    }
    final crossedSession = now.isAfter(oldData.sessionData.sessionEndDt);
    if (crossedSession) {
      DateTime newSessionEndDt = now.add(const Duration(minutes: 30));
      if (newSessionEndDt.day != now.day) {
        newSessionEndDt = DtHelper.dayEndDt(now);
      }

      final newData = oldData.handelSessionChange(
        newSession: oldData.sessionData.copyWith(
          sessionEndDt: newSessionEndDt,
        ),
      );
      // save it
      state = newData;
      return;
    }
    // debugPrint(getIndeciesAccordingToRule().first.toString());
    // debugPrint(getIndeciesAccordingToRule().last.toString());
    final newData = oldData.handelSameSessionUpdate();
    state = newData;
    return;
  }

  void handelAddEvent() {
    final oldData = state.copyWith();
    final newData = oldData.handelAddEvent();
    state = newData;
    // save it.
    saveData();
  }

  Future<void> saveData() async {
    final now = DateTime.now();
    saveInStorage(at: now);
    saveToSupabase(at: now);
  }

  void saveInStorage({DateTime? at}) {
    at ??= DateTime.now();
    final dayEntryJson = state.dayEntries.map((day) => day.toJson()).toList();
    final dayString = jsonEncode(dayEntryJson);
    ref.read(storageProvider).setString(_updateDtKey, at.toIso8601String());
    ref.read(storageProvider).setString(_dayEntriesKey, dayString);
  }

  Future<void> saveToSupabase({
    DateTime? at,
    bool addDayEntries = true,
    // bool addIndices = true,
    // bool addSession = true,
    // bool addStat = true,
  }) async {
    // save to supabase.
    at ??= DateTime.now();
    Map<String, dynamic> dataToUpdate = {
      _updateDtKey: at.toIso8601String(),
    };
    if (addDayEntries) {
      final dayEntryJson = state.dayEntries.map((day) => day.toJson()).toList();
      dataToUpdate[_dayEntriesKey] = dayEntryJson;
    }
    // if (addIndices) {
    //   dataToUpdate['indices'] = indices.toJson();
    // }
    // if (addSession) {
    //   dataToUpdate['session_dt'] = sessionData.toJson();
    // }
    // if (addStat) {
    //   dataToUpdate['stat_data'] = statData.toJson();
    // }
    try {
      await Supabase.instance.client
          .from('time_data_db')
          .update(dataToUpdate)
          .eq('id', 1);
      debugPrint('SaveToSupabase @ ${dataToUpdate[_updateDtKey]}');
    } catch (e) {
      debugPrint('Error saving to supabase: $e');
    }
  }
}
