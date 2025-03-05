import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ten_thousands_hours/models/time_data/model/indecies_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/session_data.dart';
import 'package:ten_thousands_hours/models/time_data/model/stat_data.dart';
import 'package:ten_thousands_hours/providers/storage_pro.dart';

import '../models/time_data/model/day_model/day_model.dart';
import '../models/time_data/model/time_data.dart';
import '../models/time_data/time_logic.dart';
import '../utils/dt_utils.dart';

final timeDataProvider = NotifierProvider<TimeDataNot, TimeData>(
  TimeDataNot.new,
);

class TimeDataNot extends Notifier<TimeData> {
  @override
  TimeData build() {
    final timeData = TimeLogic.createEmptyTimeData();
    return timeData;
  }

  void handelTick({bool debug = false}) {
    final nowDt = DateTime.now();
    final updatedData = TimeLogic.handleTic(
      timeData: state.copyWith(),
      tic: nowDt,
      saveData: saveTimeData,
      debug: debug,
    );
    // if (debug) debugPrint('updatedData: ${updatedData.toJson()}');
    if (debug) debugPrint('last x ${updatedData.today.coordinates.last.dx}');
    if (debug) debugPrint('last y ${updatedData.today.coordinates.last.dy}');
    state = updatedData;
  }

  void updateSession({
    DateTime? startDt,
    DateTime? endDt,
    bool debug = false,
  }) {
    if (debug) debugPrint('updateSession');
    final newSessionData = state.sessionData.copyWith(
      sessionStartDt: startDt,
      sessionEndDt: endDt,
    );
    final updatedData = TimeLogic.updateSession(
      state.copyWith(),
      newSessionData,
      DateTime.now(),
    );
    state = updatedData;
    saveTimeData(state.copyWith());
  }

  void addTimePoint({required DateTime dt}) {
    final updatedData = TimeLogic.addEvent(state.copyWith(), dt);
    state = updatedData;
    saveTimeData(updatedData);
  }

  void saveTimeData(TimeData data) {
    ref.read(storageProvider).saveTimeData(jsonEncode(
          data.toJson(),
        ));
    // debugPrint('time data saved @${DtUtils.dtToHMS(state.lastUpdate)}');
    // debugPrint('saved: ${data.toJson()}');
    saveDataToSupabase(data: data);
  }

  void init({bool debug = false}) {
    final localData = ref.read(storageProvider).getTimeData();
    TimeData? localTimeData;
    if (localData != null) {
      localTimeData = TimeData.fromJson(jsonDecode(localData));
      state = localTimeData;
      if (debug) {
        debugPrint(
          'time data initialized @${DtUtils.dtToHMS(state.lastUpdate)}',
        );
      }
    }
    final supabaseData = getFromSupabase(debug: debug);
    supabaseData.then((value) {
      if (value != null) {
        if (localTimeData == null) {
          state = value;
          if (debug) {
            debugPrint(
              'time data initialized from supabase @${DtUtils.dtToHMS(state.lastUpdate)}',
            );
          }
          return;
        }
        if (value.lastUpdate.isAfter(localTimeData.lastUpdate)) {
          state = value;
          if (debug) {
            debugPrint(
              'time data initialized from supabase @${DtUtils.dtToHMS(state.lastUpdate)}',
            );
          }
        } else {
          if (debug) {
            debugPrint(
              'supabase data is not newer @${DtUtils.dtToHMS(state.lastUpdate)}',
            );
          }
        }
      }
    });
  }

  void testinit() {
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
    state = timeData;
    saveTimeData(timeData);
  }

  Future<TimeData?> getFromSupabase({bool debug = false}) async {
    try {
      if (debug) {
        debugPrint('fetching from supabase');
      }
      final response = await Supabase.instance.client
          .from('time_data_db')
          .select()
          .eq('email', 'alianando44@gmail.com');
      if (response.isNotEmpty) {
        final data = response.first;
        if (debug) debugPrint('response data: $data');
        if (data['time_data'] == null) {
          debugPrint('No time points');
          return null;
        }
        final timeDataJson = data['time_data'];
        final timeData = TimeData.fromJson(timeDataJson);
        debugPrint('Time Data Found');
        return timeData;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching data: $e');
      return Future.error(e);
    }
  }

  Future<void> saveDataToSupabase({
    required TimeData data,
    bool debug = false,
  }) async {
    try {
      await Supabase.instance.client.from('time_data_db').update({
        'time_data': data.toJson(),
      }).eq('email', 'alianando44@gmail.com');
      if (debug) {
        debugPrint('Saved to supabase');
      }
    } catch (e) {
      debugPrint('Error saving to supabase: $e');
      return Future.error(e);
    }
  }

  void clearData() {
    // state = TimeData.fromJson(exampleData);
    final today = TimeLogic.createEmptyTimeData();
    state = today;
    ref.read(storageProvider).saveTimeData(jsonEncode(today.toJson()));

    // ref.read(storageProvider).saveTimeData(jsonEncode(exampleData));
  }

  void setNewData(TimeData data) {
    state = data;
  }
}

final exampleData = {
  "lastUpdate": "2025-02-24T19:02:01.535857",
  "statData": {
    "maxDurInLastTenDays": 9492000,
    "minDurInLastTenDays": 0,
    "totalDur": 4751000,
    "todayIndex": 0,
    "weekIndices": [0],
    "monthIndices": [0]
  },
  "sessionData": {
    "dayStartTime": "2025-02-23T00:00:00.000",
    "dayEndTime": "2025-02-23T23:59:59.000",
    "sessionStartDt": "2025-02-23T00:00:00.000",
    "sessionEndDt": "2025-02-23T23:59:59.000"
  },
  "days": [
    {
      "lastUpdate": "2025-02-23T20:36:00.824337",
      "distanceFromToday": 0,
      "dur": 4746000,
      "timePoints": [
        {"dt": "2025-02-23T00:00:00.000", "dur": 0, "typ": "pause"},
        {"dt": "2025-02-23T18:23:34.210102", "dur": 0, "typ": "pause"},
        {"dt": "2025-02-23T18:23:44.000", "dur": 0, "typ": "resume"},
        {"dt": "2025-02-23T18:30:00.000", "dur": 376000, "typ": "pause"},
        {"dt": "2025-02-23T18:36:31.000", "dur": 376000, "typ": "resume"},
        {"dt": "2025-02-23T18:43:52.000", "dur": 817000, "typ": "pause"},
        {"dt": "2025-02-23T18:44:07.000", "dur": 817000, "typ": "resume"},
        {"dt": "2025-02-23T18:45:31.000", "dur": 901000, "typ": "pause"},
        {"dt": "2025-02-23T18:47:30.000", "dur": 901000, "typ": "resume"},
        {"dt": "2025-02-23T19:51:35.000", "dur": 4746000, "typ": "pause"},
        {"dt": "2025-02-23T20:00:00.000", "dur": 4746000, "typ": "pause"},
        {"dt": "2025-02-23T23:59:59.000", "dur": 4746000, "typ": "pause"}
      ],
      "coordinates": [
        {"dx": 0, "dy": 0},
        {"dx": 0.7663770414009421, "dy": 0},
        {"dx": 0.766490352897603, "dy": 0},
        {"dx": 0.7708422551186935, "dy": 0.03961230509903076},
        {"dx": 0.7753677704603062, "dy": 0.03961230509903076},
        {"dx": 0.7804719962036598, "dy": 0.0860724820901812},
        {"dx": 0.780645609324182, "dy": 0.0860724820901812},
        {"dx": 0.7816178427991065, "dy": 0.0949220396123051},
        {"dx": 0.7829951735552495, "dy": 0.0949220396123051},
        {"dx": 0.827498003449114, "dy": 0.5},
        {"dx": 0.8333429785066957, "dy": 0.5},
        {"dx": 1, "dy": 0.5}
      ]
    }
  ]
};
