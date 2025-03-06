import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../day_model/day_model.dart';
import '../day_model/day_services.dart';
import '../time_point/time_point.dart';

/// Record holds a collection of DayModels and manages persistence to/from storage
class Record {
  /// The date when this record was last updated
  final DateTime lastUpdate;

  /// Collection of day models containing all tracking data
  final List<DayModel> days;

  const Record({
    required this.lastUpdate,
    required this.days,
  });

  /// Current total accumulated time across all days
  Duration get totalAccumulatedTime =>
      days.fold(Duration.zero, (sum, day) => sum + day.totalDuration);

  /// Get the day model for today
  DayModel? get today {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    try {
      return days.firstWhere((day) =>
          day.dt.year == todayDate.year &&
          day.dt.month == todayDate.month &&
          day.dt.day == todayDate.day);
    } catch (_) {
      return null;
    }
  }

  /// Get the active status of current tracking
  bool get isCurrentlyTracking {
    final todayModel = today;
    if (todayModel == null || todayModel.events.isEmpty) return false;

    return todayModel.events.last.typ == TimePointTyp.resume;
  }

  /// Days with activity in the past week
  List<DayModel> get recentActiveDays {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    return days
        .where((day) =>
            day.hasActivity &&
            day.dt.isAfter(weekAgo) &&
            !_isSameDay(day.dt, now))
        .toList();
  }

  /// Serialize record to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Convert record to JSON map
  Map<String, dynamic> toJson() {
    return {
      'lastUpdate': lastUpdate.toIso8601String(),
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  /// Create a new instance with optional field updates
  Record copyWith({
    DateTime? lastUpdate,
    List<DayModel>? days,
  }) {
    return Record(
      lastUpdate: lastUpdate ?? this.lastUpdate,
      days: days ?? List<DayModel>.from(this.days),
    );
  }

  /// Create a Record from JSON map with robust error handling
  factory Record.fromJson(Map<String, dynamic> json) {
    try {
      final lastUpdateStr = json['lastUpdate'];
      if (lastUpdateStr == null) {
        return Record(
          lastUpdate: DateTime.now(),
          days: [],
        );
      }

      DateTime parsedUpdate;
      try {
        parsedUpdate = DateTime.parse(lastUpdateStr);
      } catch (_) {
        parsedUpdate = DateTime.now();
      }

      final daysList = json['days'];
      if (daysList == null || daysList is! List) {
        return Record(
          lastUpdate: parsedUpdate,
          days: [],
        );
      }

      final parsedDays = <DayModel>[];
      for (final dayJson in daysList) {
        try {
          parsedDays.add(DayModel.fromJson(dayJson));
        } catch (e) {
          debugPrint('Error parsing day: $e');
          // Skip invalid days
        }
      }

      return Record(
        lastUpdate: parsedUpdate,
        days: parsedDays,
      );
    } catch (e) {
      debugPrint('Error creating Record from JSON: $e');
      return Record(
        lastUpdate: DateTime.now(),
        days: [],
      );
    }
  }

  /// Create a Record from JSON string with error handling
  factory Record.fromJsonString(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return Record.fromJson(decoded);
    } catch (e) {
      debugPrint('Error parsing JSON string: $e');
      return Record(
        lastUpdate: DateTime.now(),
        days: [],
      );
    }
  }

  /// Helper method to check if two dates are the same day
  //
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Service class for Record operations
class RecordServices {
  const RecordServices._();

  /// Creates a new empty record with a single day (today)
  //
  static Record createEmptyRecord() {
    final now = DateTime.now();
    final today = DayModelService.createNewDay(now);

    return Record(
      lastUpdate: today.dt,
      days: [today],
    );
  }

  /// Adds a new time point event (toggle between pause/resume)
  //
  static Record addActiveEvent(Record record, DateTime at) {
    // final now = DateTime.now();
    final List<DayModel> updatedDays = List.from(record.days);

    // Find today's index or create today if it doesn't exist
    final todayDate = DateTime(at.year, at.month, at.day);
    final todayIndex = updatedDays.indexWhere((day) =>
        day.dt.year == todayDate.year &&
        day.dt.month == todayDate.month &&
        day.dt.day == todayDate.day);

    if (todayIndex >= 0) {
      // Update existing day
      updatedDays[todayIndex] = DayModelService.addActiveEvent(
        day: updatedDays[todayIndex],
        dtAt: at,
      );
    } else {
      // Create new day
      final newDay = DayModelService.createNewDay(at);
      final withEvent = DayModelService.addActiveEvent(day: newDay, dtAt: at);
      updatedDays.add(withEvent);

      // Sort days by date
      updatedDays.sort((a, b) => a.dt.compareTo(b.dt));
    }

    return record.copyWith(
      lastUpdate: at,
      days: updatedDays,
    );
  }

  /// Updates duration without adding a toggle point (for real-time updates).
  //
  static Record updateDuration(
    Record record,
    DateTime at, {
    bool debug = false,
  }) {
    // final now = DateTime.now();
    final List<DayModel> updatedDays = List.from(record.days);

    // Find today's index or return unchanged if today doesn't exist
    final todayDate = DateTime(at.year, at.month, at.day);
    final todayIndex = updatedDays.indexWhere(
      (day) =>
          day.dt.year == todayDate.year &&
          day.dt.month == todayDate.month &&
          day.dt.day == todayDate.day,
    );

    if (todayIndex >= 0) {
      updatedDays[todayIndex] = DayModelService.unactiveDtUpdate(
        day: updatedDays[todayIndex],
        dtAt: at,
      );

      return record.copyWith(
        // lastUpdate: at,
        days: updatedDays,
      );
    }
    if (debug) debugPrint('No day found for updateDuration');
    return record;
  }

  /// Ensures all days are properly closed/finalized
  //
  static Record sanitizeRecord(Record record) {
    // final now = DateTime.now();
    final List<DayModel> sanitizedDays = [];

    for (final day in record.days) {
      sanitizedDays.add(DayModelService.sanitize(day));
    }

    return record.copyWith(
      // lastUpdate: now,
      days: sanitizedDays,
    );
  }

  /// Finalizes a day by adding an end-of-day timepoint
  //
  static Record endDay(Record record, DateTime date) {
    final List<DayModel> updatedDays = List.from(record.days);

    // Find the day's index
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dayIndex = updatedDays.indexWhere((day) =>
        day.dt.year == dateOnly.year &&
        day.dt.month == dateOnly.month &&
        day.dt.day == dateOnly.day);

    if (dayIndex >= 0) {
      updatedDays[dayIndex] = DayModelService.endDay(updatedDays[dayIndex]);
    }

    return record.copyWith(
      lastUpdate: DateTime.now(),
      days: updatedDays,
    );
  }

  /// Merges two records, keeping the most complete data
  //
  static Record mergeRecords(Record record1, Record record2) {
    try {
      final allDays = <DateTime, DayModel>{};

      // Process all days from record1
      for (final day in record1.days) {
        final dateKey = DateTime(day.dt.year, day.dt.month, day.dt.day);
        allDays[dateKey] = day;
      }

      // Merge with days from record2
      for (final day in record2.days) {
        final dateKey = DateTime(day.dt.year, day.dt.month, day.dt.day);

        if (allDays.containsKey(dateKey)) {
          try {
            // Merge days for same date
            allDays[dateKey] = DayModelService.mergeDays(
              allDays[dateKey]!,
              day,
            );
          } catch (e) {
            debugPrint('Error merging days: $e');
            // Keep the original day if merging fails
          }
        } else {
          allDays[dateKey] = day;
        }
      }

      // Choose the most recent update time
      final lastUpdate = record1.lastUpdate.isAfter(record2.lastUpdate)
          ? record1.lastUpdate
          : record2.lastUpdate;

      // Sort days chronologically
      final sortedDays = allDays.values.toList()
        ..sort((a, b) => a.dt.compareTo(b.dt));

      return Record(
        lastUpdate: lastUpdate,
        days: sortedDays,
      );
    } catch (e) {
      debugPrint('Error merging records: $e');
      // If anything fails, return the more recently updated record
      return record1.lastUpdate.isAfter(record2.lastUpdate) ? record1 : record2;
    }
  }

  /// Exports record to CSV format
  //
  static String exportToCsv(Record record) {
    final buffer = StringBuffer();

    // Write header
    buffer.writeln('Time Tracking Data Export');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln(
      'Total Accumulated Time (hours): ${record.totalAccumulatedTime.inMinutes / 60}',
    );
    buffer.writeln();

    // Write days
    buffer.writeln(
      'Date,Total Duration (minutes),Sessions Count,Most Active Period',
    );

    for (final day in record.days) {
      if (day.hasActivity) {
        final summary = DayModelService.createDaySummary(day);
        buffer.writeln(
          '${day.dt.year}-${day.dt.month.toString().padLeft(2, '0')}-${day.dt.day.toString().padLeft(2, '0')},'
          '${day.totalDuration.inMinutes},'
          '${summary['sessionCount']},'
          '${summary['mostActivePeriod']}',
        );
      }
    }

    return buffer.toString();
  }

  /// Saves record to storage and DB
  //
  static Future<bool> saveRecord(
    Record record,
    Future<void> Function(String) saveToStorage,
    Future<void> Function(Map<String, dynamic>) saveToDatabase,
  ) async {
    try {
      // Serialize record
      final jsonString = record.toJsonString();
      final jsonMap = record.toJson();

      // Save to local storage
      await saveToStorage(jsonString);

      // Save to database
      await saveToDatabase(jsonMap);

      return true;
    } catch (e) {
      debugPrint('Error saving record: $e');
      return false;
    }
  }

  /// Loads record from storage
  //
  static Future<Record?> loadRecord(
    Future<String?> Function() loadFromStorage,
    Future<Map<String, dynamic>?> Function() loadFromDatabase,
  ) async {
    try {
      // Try loading from local storage first
      final localData = await loadFromStorage();
      Record? localRecord;

      if (localData != null) {
        localRecord = Record.fromJsonString(localData);
      }

      // Try loading from database
      final dbData = await loadFromDatabase();
      Record? dbRecord;

      if (dbData != null) {
        dbRecord = Record.fromJson(dbData);
      }

      // If both exist, merge them.
      // if (localRecord != null && dbRecord != null) {
      //   return mergeRecords(localRecord, dbRecord);
      // }
      if (localRecord != null && dbRecord != null) {
        if (localRecord.lastUpdate.isAfter(dbRecord.lastUpdate)) {
          return localRecord;
        }
        return dbRecord;
      }

      // Return whichever one exists
      return localRecord ?? dbRecord;
    } catch (e) {
      debugPrint('Error loading record: $e');
      return null;
    }
  }
}
