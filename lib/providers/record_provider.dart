import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ten_thousands_hours/models/time_data/model/day_model/day_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/day_model/day_services.dart';
import 'package:ten_thousands_hours/models/time_data/model/record/record.dart';
import 'package:ten_thousands_hours/providers/storage_pro.dart';

/// Provider for the Record
final recordProvider = NotifierProvider<RecordNotifier, Record>(
  RecordNotifier.new,
);

/// Notifier class that manages state for the Record
class RecordNotifier extends Notifier<Record> {
  /// Initialize with empty record
  @override
  Record build() {
    return RecordServices.createEmptyRecord();
  }

  /// Database key for saving/retrieving record
  final String _recordKey = 'time_record';

  /// Initialize the record by loading from local storage and Supabase
  /// Merges both sources to ensure we have the most complete data
  Future<void> init({bool debug = false}) async {
    try {
      // Load from local storage
      final localData = ref.read(storageProvider).getString(_recordKey);
      Record? localRecord;

      if (localData != null) {
        localRecord = Record.fromJsonString(localData);
        if (debug) {
          debugPrint(
            'Record loaded from local storage: ${localRecord.lastUpdate}',
          );
        }
      }

      // Load from Supabase
      final supabaseRecord = await _loadFromSupabase(debug: debug);

      if (localRecord != null && supabaseRecord != null) {
        // Merge both records if we have both sources
        final mergedRecord =
            RecordServices.mergeRecords(localRecord, supabaseRecord);
        state = mergedRecord;
        if (debug) {
          debugPrint(
              'Records merged from local and Supabase: ${mergedRecord.lastUpdate}');
        }
      } else {
        // Use whichever record is available
        state = localRecord ?? supabaseRecord ?? state;
      }

      // Always sanitize record on startup to ensure data integrity
      state = RecordServices.sanitizeRecord(state);

      // Save the record to ensure local and remote are synced
      _saveRecord(state, debug: debug);
    } catch (e) {
      debugPrint('Error initializing record: $e');
    }
  }

  /// Handle ticking updates (called periodically)
  ///
  /// If it's still the same day, just update durations
  /// If it's a new day, end the previous day and start a new one
  /// Makes sure active tracking is properly maintained across days
  void onTickUpdate(DateTime now, {bool debug = false}) {
    try {
      final lastUpdateDate = DateTime(
        state.lastUpdate.year,
        state.lastUpdate.month,
        state.lastUpdate.day,
      );

      final currentDate = DateTime(
        now.year,
        now.month,
        now.day,
      );

      // Check if we've moved to a new day
      final isNewDay = currentDate.isAfter(lastUpdateDate);

      if (isNewDay) {
        if (debug) debugPrint('New day detected');

        // Check if the previous day ended with an active session
        final wasActive = state.isCurrentlyTracking;

        // End previous day
        Record updatedRecord = RecordServices.endDay(state, lastUpdateDate);

        // Create new day for today
        DayModel newDay = DayModelService.createNewDay(currentDate);

        // If we were actively tracking, add a resume point to continue
        if (wasActive) {
          if (debug) debugPrint('Continuing active session to new day');
          newDay = DayModelService.addActiveEvent(
            day: newDay,
            dtAt: DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
            ),
          );
        }

        // Add the new day to our record
        final updatedDays = List<DayModel>.from(updatedRecord.days)
          ..add(newDay);
        updatedDays.sort((a, b) => a.dt.compareTo(b.dt));

        updatedRecord = updatedRecord.copyWith(
          days: updatedDays,
          lastUpdate: now,
        );

        state = updatedRecord;
        _saveRecord(updatedRecord, debug: debug);
      } else {
        // Same day, just update durations if actively tracking
        if (state.isCurrentlyTracking) {
          final updatedRecord = RecordServices.updateDuration(state, now);
          state = updatedRecord;

          // Only save every minute to avoid excessive writes
          // if (now.second == 0) {
          //   _saveRecord(updatedRecord, debug: debug);
          // }
        }
      }
    } catch (e) {
      debugPrint('Error in handleTick: $e');
    }
  }

  /// Add a new time point (toggles between pause and resume)
  void addActiveEvent(DateTime at, {bool debug = false}) {
    try {
      final updatedRecord = RecordServices.addActiveEvent(state, at);
      state = updatedRecord;
      _saveRecord(updatedRecord, debug: debug);

      if (debug) {
        final isTracking = updatedRecord.isCurrentlyTracking;
        debugPrint(
          'Added active event - now ${isTracking ? 'tracking' : 'paused'}',
        );
      }
    } catch (e) {
      debugPrint('Error adding active event: $e');
    }
  }

  /// Load record data from Supabase
  Future<Record?> _loadFromSupabase({bool debug = false}) async {
    try {
      if (debug) {
        debugPrint('Fetching record from Supabase');
      }

      final response = await Supabase.instance.client
          .from('time_records')
          .select()
          .eq('user_id',
              Supabase.instance.client.auth.currentUser?.id ?? 'anonymous')
          .single();

      final recordData = response['record_data'];
      if (recordData == null) {
        if (debug) debugPrint('No record data found in Supabase');
        return null;
      }

      final record = Record.fromJson(recordData);
      if (debug) {
        debugPrint('Record loaded from Supabase: ${record.lastUpdate}');
      }
      return record;
    } catch (e) {
      if (debug) {
        debugPrint('Error loading from Supabase: $e');
      }
      return null;
    }
  }

  /// Save record to both local storage and Supabase
  Future<void> _saveRecord(Record record, {bool debug = false}) async {
    try {
      // Save to local storage
      final jsonString = record.toJsonString();
      ref.read(storageProvider).setString(_recordKey, jsonString);
      if (debug) debugPrint('Record saved to local storage');

      // Save to Supabase
      try {
        await Supabase.instance.client.from('time_records').upsert({
          'user_id':
              Supabase.instance.client.auth.currentUser?.id ?? 'anonymous',
          'record_data': record.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        if (debug) debugPrint('Record saved to Supabase');
      } catch (e) {
        debugPrint('Error saving to Supabase: $e');
      }
    } catch (e) {
      debugPrint('Error saving record: $e');
    }
  }

  /// Export record data to CSV format
  String exportToCsv() {
    return RecordServices.exportToCsv(state);
  }

  /// Clear all data and reset to a new empty record
  void resetData({bool debug = false}) {
    final newRecord = RecordServices.createEmptyRecord();
    state = newRecord;
    _saveRecord(newRecord, debug: debug);
    if (debug) debugPrint('Record reset to empty state');
  }

  /// Manual method to force adding a time point event at a specific date/time
  /// Useful for testing or correcting data
  void addTimePointAt(DateTime at, {bool debug = false}) {
    try {
      final updatedRecord = RecordServices.addActiveEvent(state, at);
      state = updatedRecord;
      _saveRecord(updatedRecord, debug: debug);
      if (debug) debugPrint('Manually added time point at $at');
    } catch (e) {
      debugPrint('Error adding time point: $e');
    }
  }

  /// Get Statistics about the current record
  Map<String, dynamic> getStatistics() {
    // Use only active days (days with activity)
    final activeDays = state.days.where((day) => day.hasActivity).toList();
    if (activeDays.isEmpty) {
      return {
        'totalDuration': Duration.zero,
        'averageDaily': Duration.zero,
        'activeDaysCount': 0,
        'currentStreak': 0,
      };
    }

    // Calculate basic statistics
    final totalDuration = state.totalAccumulatedTime;
    final averageDaily = Duration(
        microseconds: totalDuration.inMicroseconds ~/ activeDays.length);

    // Calculate current streak
    int currentStreak = 0;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Loop backward from today, incrementing streak for consecutive days
    for (int i = 0; i < 100; i++) {
      // Limit to 100 days to avoid infinite loop
      final checkDate = today.subtract(Duration(days: i));
      final hasActivity = state.days.any((day) =>
          day.hasActivity &&
          day.dt.year == checkDate.year &&
          day.dt.month == checkDate.month &&
          day.dt.day == checkDate.day);

      if (hasActivity) {
        currentStreak++;
      } else {
        break; // Break on first day without activity
      }
    }

    return {
      'totalDuration': totalDuration,
      'averageDaily': averageDaily,
      'activeDaysCount': activeDays.length,
      'currentStreak': currentStreak,
    };
  }
}
