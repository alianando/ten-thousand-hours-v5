import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/storage_pro.dart';
import '../../root/root.dart';
import 'day_record.dart';
import 'time_record.dart';
import 'package:intl/intl.dart';

final timeRecordProvider = NotifierProvider<TimeReocrdNotifier, TimeRecord>(
  TimeReocrdNotifier.new,
);

class TimeReocrdNotifier extends Notifier<TimeRecord> {
  @override
  TimeRecord build() {
    return TimeRecordService.createEmptyRecord();
  }

  void retrieveRecord({bool debug = false}) async {
    try {
      pout('RetrieveRecord <- TimeRecordProvider', debug);
      const debugL = 2;
      final localDays = RecordDBService.localRecord(
        ref,
        debug: false,
        debugLevel: debugL,
      );
      final localIsValid = localDays.isNotEmpty;
      final localLastUpdate =
          localIsValid ? localDays.last.events.last.dt : DateTime(1999);
      pout('local last update $localLastUpdate', debug, level: debugL);
      if (localIsValid) {
        final varifiedLocals = TimeRecordService.sanitize(
          TimeRecord(days: localDays),
        );
        state = varifiedLocals;
        pout('Local data added', debug, level: debugL);
      }
      // final supabaseDays = await RecordDBService.supabaseRecord(
      //   debug: false,
      //   dl: debugL,
      // );
      // final supabaseDayIsCorrect = supabaseDays.isNotEmpty;
      // final supabaseLastUpdate = supabaseDayIsCorrect
      //     ? supabaseDays.last.events.last.dt
      //     : DateTime(1999);
      // pout('supabase last update $supabaseLastUpdate', debug, level: debugL);
      // if (supabaseLastUpdate.isAfter(localLastUpdate)) {
      //   final verifiedSupabaseDays = TimeRecordService.sanitize(
      //     TimeRecord(days: supabaseDays),
      //   );
      //   state = verifiedSupabaseDays;
      //   pout('Supabase data added', false, level: debugL);
      //   RecordDBService.saveToLocal(ref, verifiedSupabaseDays.days);
      //   return;
      // }
      // if (supabaseLastUpdate.isAtSameMomentAs(localLastUpdate)) {
      //   pout('Identical Data', debug, level: debugL);
      //   return;
      // }
      // if (localLastUpdate.isAfter(supabaseLastUpdate)) {
      //   pout('Supabase data is old', debug, level: debugL);
      //   RecordDBService.saveToSupabase(localDays);
      //   return;
      // }
    } catch (e) {
      debugPrint('Error retrieving record: $e');
    }
  }

  void addActiveEvent({bool debug = true}) {
    final now = DateTime.now();
    final oldRecord = state.copyWith();
    final updatedRecord = TimeRecordService.addActiveEvent(oldRecord, now);
    state = updatedRecord;
    RecordDBService.saveToLocal(ref, updatedRecord.days);
    RecordDBService.saveToSupabase(updatedRecord.days);
  }

  void handelNewDay({bool debug = true}) {
    final updated = TimeRecordService.sanitize(state.copyWith());
    state = updated;
    RecordDBService.saveToLocal(ref, updated.days);
    RecordDBService.saveToSupabase(updated.days);
  }
}

class RecordDBService {
  const RecordDBService._();

  /// Database key for saving/retrieving record
  // final String _updateDtKey = 'updated_at';
  static const String _dayEntriesKey = 'day_entries';

  static List<DayEntry> localRecord(
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

  static Future<List<DayEntry>> supabaseRecord({
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

/// write a stateLess widget that will display the time record

class TimeRecordProviderDebugView extends ConsumerWidget {
  const TimeRecordProviderDebugView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(timeRecordProvider);
    final days = record.days;
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ScrollPhysics(),
          itemCount: record.days.length,
          reverse: true,
          itemBuilder: (context, index) {
            final day = record.days[index];

            /// format the date using intl package.
            final date = DateFormat('dd/MM/yyyy').format(day.dt);

            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TripleRail(
                //   leading: Text(date),
                //   trailing: Text('Events: ${day.events.length}'),
                // ),
                Text('Day $date'),
                Text('  ${day.durPoint.dur.inMinutes} minutes.'),
                ...day.events.map((event) {
                  return Text('  $event');
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}
