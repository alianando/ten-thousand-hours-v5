import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'day_record.dart';

class TimeRecord {
  final List<DayEntry> days;

  const TimeRecord({required this.days});

  List<DayEntry> get allDays => List.from(days);

  /// Serialize record to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Convert record to JSON map
  Map<String, dynamic> toJson() {
    return {
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  /// Create a new instance with optional field updates
  TimeRecord copyWith({
    List<DayEntry>? days,
  }) {
    return TimeRecord(
      days: days ?? List<DayEntry>.from(this.days),
    );
  }

  /// Create a Record from JSON map with robust error handling
  factory TimeRecord.fromJson(Map<String, dynamic> json) {
    try {
      final daysList = json['days'];
      if (daysList == null || daysList is! List) {
        return const TimeRecord(days: []);
      }

      final parsedDays = <DayEntry>[];
      for (final dayJson in daysList) {
        try {
          parsedDays.add(DayEntry.fromJson(dayJson));
        } catch (e) {
          debugPrint('Error parsing day: $e');
          // Skip invalid days
        }
      }

      return TimeRecord(
        days: parsedDays,
      );
    } catch (e) {
      debugPrint('Error creating Record from JSON: $e');
      return const TimeRecord(days: []);
    }
  }

  /// Create a Record from JSON string with error handling
  factory TimeRecord.fromJsonString(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return TimeRecord.fromJson(decoded);
    } catch (e) {
      debugPrint('Error parsing JSON string: $e');
      return const TimeRecord(days: []);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! TimeRecord) return false;

    final TimeRecord otherEntry = other;

    // Check if days are the same
    if (days.length != otherEntry.days.length) {
      return false;
    }

    // Sort days by date for consistent comparison
    final List<DayEntry> sortedDays = List.from(days)
      ..sort((a, b) => a.dt.compareTo(b.dt));
    final List<DayEntry> otherSortedDays = List.from(otherEntry.days)
      ..sort((a, b) => a.dt.compareTo(b.dt));

    // Compare each day
    for (int i = 0; i < sortedDays.length; i++) {
      if (sortedDays[i] != otherSortedDays[i]) {
        return false;
      }
    }

    return true;
  }

  /// Hash code override
  ///
  /// Provides a consistent hash code based on the lastUpdate and days content.
  /// This is required to pair with the equality operator for proper behavior
  /// in collections like Sets and Maps.
  @override
  int get hashCode {
    // Generate a hash based on lastUpdate and all days
    return Object.hashAll(days);
  }
}

/// Service class for Record operations
class TimeRecordService {
  const TimeRecordService._();

  /// Creates a new empty record with a single day (today)
  //
  static TimeRecord createEmptyRecord() {
    final now = DateTime.now();
    final today = DayEntry.create(now);

    return TimeRecord(
      days: [today],
    );
  }

  /// Adds a new time point event (toggle between pause/resume)
  //
  static TimeRecord addActiveEvent(TimeRecord record, DateTime at) {
    var updatedDays = record.allDays;

    // Find today's index or create today if it doesn't exist
    final targetDate = DateTime(at.year, at.month, at.day);
    final targetIndex = updatedDays.indexWhere(
      (day) =>
          day.dt.year == targetDate.year &&
          day.dt.month == targetDate.month &&
          day.dt.day == targetDate.day,
    );

    if (targetIndex >= 0) {
      // Update existing day
      updatedDays[targetIndex] = updatedDays[targetIndex].addActiveEvent(at);
    } else {
      // Create new day
      final newDay = DayEntry.create(at);
      final withEvent = newDay.addActiveEvent(at);
      updatedDays.add(withEvent);

      // Sort days by date
      updatedDays.sort((a, b) => a.dt.compareTo(b.dt));
    }

    return TimeRecord(days: updatedDays);
  }

  /// Ensures all days are properly closed/finalized
  //
  static TimeRecord sanitize(TimeRecord record) {
    // debugPrint('sanitized beforr ${record.allDays.last.lastTimeStapm.typ}');
    List<DayEntry> sanitizedDays = [];
    // sanitizedDays.addAll(record.allDays);
    for (final day in record.days) {
      sanitizedDays.add(day.corrected());
    }
    // debugPrint('sanitized after ${sanitizedDays.last.lastTimeStapm.typ}');
    final todayDate = DateTime.now();
    final todayIndex = sanitizedDays.indexWhere(
      (day) =>
          day.dt.year == todayDate.year &&
          day.dt.month == todayDate.month &&
          day.dt.day == todayDate.day,
    );
    if (todayIndex < 0) {
      final newDay = DayEntry.create(todayDate);
      sanitizedDays.add(newDay);
    }
    // Sort days by date
    sanitizedDays.sort((a, b) => a.dt.compareTo(b.dt));

    return TimeRecord(
      days: sanitizedDays,
    );
  }

  /// Finalizes a day by adding an end-of-day timepoint
  //
  static TimeRecord endDay(TimeRecord record, DateTime date) {
    var updatedDays = record.allDays;

    // Find the day's index
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dayIndex = updatedDays.indexWhere((day) =>
        day.dt.year == dateOnly.year &&
        day.dt.month == dateOnly.month &&
        day.dt.day == dateOnly.day);

    if (dayIndex >= 0) updatedDays[dayIndex] = updatedDays[dayIndex].end();

    return TimeRecord(days: updatedDays);
  }

  /// Saves record to storage and DB
  //
  static Future<bool> saveRecord(
    TimeRecord record,
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
}
