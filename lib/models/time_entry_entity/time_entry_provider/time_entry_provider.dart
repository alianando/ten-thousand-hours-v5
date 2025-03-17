import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../providers/storage_pro.dart';
import '../../../root/root.dart';
import '../day_entry/day_model.dart';
import '../day_entry/day_services.dart';
import '../time_entry/time_entry.dart';
import '../time_point/time_point.dart';

final timeEntryP = NotifierProvider<TimeEntryNotifier, TimeEntry>(
  TimeEntryNotifier.new,
);

class TimeEntryNotifier extends Notifier<TimeEntry> {
  @override
  TimeEntry build() {
    final now = DateTime.now();
    final today = DayEntry.createEmptyDay(now);
    final lastUpdate = DateTime(now.year, now.month, now.day);
    return TimeEntry(
      lastUpdate: lastUpdate,
      days: [today],
    );
  }

  void retrieveTimeEntry({bool debug = false}) async {
    try {
      pout('RetrieveTimeEntry <- TimeEntryProvider', debug);
      const debugL = 2;
      final localDays = TimeEntryMethods.localDayEntries(
        ref,
        debug: false,
        debugLevel: debugL,
      );
      final localIsValid = localDays.isNotEmpty;
      final localLastUpdate =
          localIsValid ? localDays.last.events.last.dt : DateTime(1999);
      pout('local last update $localLastUpdate', debug, level: debugL);
      if (localIsValid) {
        final varifiedLocals = TimeEntryMethods.checkDays(
          localDays,
          debug: debug,
          dl: debugL,
        );
        state = TimeEntry(days: varifiedLocals, lastUpdate: localLastUpdate);
        pout('Local data added', debug, level: debugL);
      }
      final supabaseDays = await TimeEntryMethods.supabaseDayEntries(
        debug: false,
        dl: debugL,
      );
      final supabaseDayIsCorrect = supabaseDays.isNotEmpty;
      final supabaseLastUpdate = supabaseDayIsCorrect
          ? supabaseDays.last.events.last.dt
          : DateTime(1999);
      pout('supabase last update $supabaseLastUpdate', debug, level: debugL);
      if (supabaseLastUpdate.isAfter(localLastUpdate)) {
        final verifiedSupabaseDays = TimeEntryMethods.checkDays(
          supabaseDays,
          debug: debug,
          dl: debugL,
        );
        state = TimeEntry(
          days: verifiedSupabaseDays,
          lastUpdate: supabaseLastUpdate,
        );
        pout('Supabase data added', false, level: debugL);
        TimeEntryMethods.saveToLocal(ref, verifiedSupabaseDays);
        return;
      }
      if (supabaseLastUpdate.isAtSameMomentAs(localLastUpdate)) {
        pout('Data is up to date', debug, level: debugL);
        return;
      }
      if (localLastUpdate.isAfter(supabaseLastUpdate)) {
        pout('Supabase data is old', debug, level: debugL);
        TimeEntryMethods.saveToSupabase(localDays);
        return;
      }
    } catch (e) {
      debugPrint('Error retrieving record: $e');
    }
  }

  void addActiveEvent({bool debug = true}) {
    final now = DateTime.now();
    var updatedDayEntries = List<DayEntry>.from(state.days);
    for (int i = updatedDayEntries.length - 1; i >= 0; i--) {
      final day = updatedDayEntries[i];
      if (day.dt.isAtSameMomentAs(DtHelper.dayStartDt(now))) {
        final updatedDay = DayModelService.addActiveEvent(
          day: day,
          dtAt: now,
        );
        updatedDayEntries[i] = updatedDay;
        pout('added an event successfully', debug);
        break;
      }
    }
    state = TimeEntry(
      days: updatedDayEntries,
      lastUpdate: now,
    );
    TimeEntryMethods.saveToLocal(ref, updatedDayEntries);
    TimeEntryMethods.saveToSupabase(updatedDayEntries);
  }

  void handelNewDay({bool debug = true}) {
    final now = DateTime.now();
    final updatedDayEntries = List<DayEntry>.from(state.days);
    final newDay = DayEntry.createEmptyDay(now);
    updatedDayEntries.add(newDay);
    if (updatedDayEntries.length > 1) {
      updatedDayEntries.sort((a, b) => a.dt.compareTo(b.dt));
    }
    for (int i = 0; i < updatedDayEntries.length - 1; i++) {
      ///! Sensitize all the days
      /// this ends the previous day which is very important.
      updatedDayEntries[i] = DayModelService.sanitize(updatedDayEntries[i]);
    }
    state = TimeEntry(
      days: updatedDayEntries,
      lastUpdate: now,
    );
    TimeEntryMethods.saveToLocal(ref, updatedDayEntries);
    TimeEntryMethods.saveToSupabase(updatedDayEntries);
  }
}

class TimeEntryMethods {
  const TimeEntryMethods._();

  /// Database key for saving/retrieving record
  // final String _updateDtKey = 'updated_at';
  static const String _dayEntriesKey = 'day_entries';

  static List<DayEntry> checkDays(
    List<DayEntry> days, {
    bool debug = false,
    int dl = 0,
  }) {
    pout('CheckDays @ TimeEntryNot', debug, level: dl);
    final dt = DateTime.now();
    List<DayEntry> updated = List<DayEntry>.from(days);
    final todayIndex = updated.indexWhere(
      (d) => d.dt.isAtSameMomentAs(DtHelper.dayStartDt(dt)),
    );
    if (todayIndex < 0) {
      pout('Added today', debug, level: dl + 1);
      updated.add(DayEntry.createEmptyDay(dt));
    } else {
      pout('Today exists', debug, level: dl + 1);
    }

    /// if today does not exist, then sensitize all the days
    // todo: implement sensitize
    // if(todayIndex < 0){
    //   for(int i = 0; i < updated.length; i++){
    //     updated[i] = updated[i].sensitize();
    //   }
    // }
    if (updated.length < 2) {
      return updated;
    }
    updated.sort((a, b) => a.dt.compareTo(b.dt));
    for (int i = 0; i < updated.length - 1; i++) {
      updated[i] = DayModelService.sanitize(updated[i]);
    }
    return updated;
  }

  static List<DayEntry> localDayEntries(
    Ref ref, {
    bool debug = false,
    int debugLevel = 0,
  }) {
    try {
      final local = ref.read(storageProvider);
      final localDayString = local.getString(_dayEntriesKey);
      if (localDayString != null) {
        List<DayEntry> localDay = jsonDecode(localDayString)
            .map((e) {
              return DayEntry.fromJson(e);
            })
            .whereType<DayEntry>()
            .toList();
        pout('localDay: $localDay', debug, level: debugLevel);
        if (localDay.length < 2) {
          return localDay;
        }
        localDay.sort((a, b) => a.dt.compareTo(b.dt));

        return localDay;
      }
    } catch (e) {
      debugPrint('Error retrieving local day entries: $e');
    }

    return [];
  }

  static Future<List<DayEntry>> supabaseDayEntries({
    bool debug = false,
    int dl = 0,
  }) async {
    try {
      final response = await Supabase.instance.client
          .from('time_data_db')
          .select()
          .eq('id', 1)
          .single();

      final dayJson = response[_dayEntriesKey];
      List<DayEntry> dayEntries = dayJson
          .map((e) {
            return DayEntry.fromJson(e);
          })
          .whereType<DayEntry>()
          .toList();
      pout(
        'supabase day entries: ${dayEntries.toString()}',
        debug,
        level: dl,
      );
      if (dayEntries.length < 2) {
        return dayEntries;
      }
      dayEntries.sort((a, b) => a.dt.compareTo(b.dt));
      return dayEntries;
    } catch (e) {
      debugPrint('Error retrieving supabase day entries: $e');
    }

    return [];
  }

  static void saveToLocal(
    Ref ref,
    List<DayEntry> days,
  ) {
    try {
      final dayEntryJson = days.map((day) => day.toJson()).toList();
      final dayString = jsonEncode(dayEntryJson);
      ref.read(storageProvider).setString(_dayEntriesKey, dayString);
      pout('${days.length} days saved to local', true);
    } catch (e) {
      debugPrint('Error saving day entries: $e');
    }
  }

  static void saveToSupabase(List<DayEntry> days) async {
    try {
      final dayEntryJson = days.map((day) => day.toJson()).toList();
      Map<String, dynamic> dataToUpdate = {
        _dayEntriesKey: dayEntryJson,
      };
      await Supabase.instance.client
          .from('time_data_db')
          .update(dataToUpdate)
          .eq('id', 1);
      pout('${days.length} days saved to supabase', true);
    } catch (e) {
      debugPrint('Error saving to supabase: $e');
    }
  }
}
