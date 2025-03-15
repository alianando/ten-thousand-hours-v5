import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/providers/time_entry/tme_entry_db_pro.dart';
import '../models/time_entry.dart';

// /// Provider for getting the latest TimeEntry
// final latestTimeEntryProvider = FutureProvider<TimeEntry?>((ref) async {
//   final database = ref.watch(timeEntryDatabaseProvider);
//   return await database.getLatestTimeEntry();
// });

/// Provider for getting all TimeEntries with pagination support
final allTimeEntriesProvider =
    FutureProvider.family<List<TimeEntry>, TimeEntryQueryParams>((
  ref,
  params,
) async {
  final database = ref.watch(timeEntryDatabaseProvider);
  return await database.getAllTimeEntries(
    limit: params.limit,
    offset: params.offset,
    orderBy: params.orderBy,
  );
});

/// Provider for getting TimeEntries for a specific day
final timeEntriesForDayProvider =
    FutureProvider.family<List<TimeEntry>, DateTime>((ref, date) async {
  final database = ref.watch(timeEntryDatabaseProvider);
  return await database.getTimeEntriesForDay(date);
});

/// Provider for getting TimeEntries within a date range
final timeEntriesForRangeProvider =
    FutureProvider.family<List<TimeEntry>, DateRange>((ref, range) async {
  final database = ref.watch(timeEntryDatabaseProvider);
  return await database.getTimeEntriesBetween(range.startDate, range.endDate);
});

/// Provider for getting daily summary statistics
final dailySummaryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, DateRange?>(
        (ref, range) async {
  final database = ref.watch(timeEntryDatabaseProvider);
  return await database.getDailySummary(
    startDate: range?.startDate,
    endDate: range?.endDate,
  );
});

/// Provider for general time entry statistics
final timeEntryStatisticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final database = ref.watch(timeEntryDatabaseProvider);
  return await database.getStatistics();
});

/// Provider for current tracking status (updates every second)
final trackingStatusProvider = StreamProvider<TrackingStatus>((ref) async* {
  final controller = ref.watch(timeEntryControllerProvider.notifier);

  while (true) {
    yield await controller.getTrackingStatus();
    await Future.delayed(const Duration(seconds: 1));
  }
});

/// Provider for the current day's total duration (cached)
final todayDurationProvider = FutureProvider<Duration>((ref) async {
  final status = await ref.watch(trackingStatusProvider.future);
  return status.todayDuration;
});

/// Helper class for date ranges
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({required this.startDate, required this.endDate});

  /// Create a DateRange for today
  factory DateRange.today() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return DateRange(startDate: startDate, endDate: endDate);
  }

  /// Create a DateRange for the last n days
  factory DateRange.lastDays(int days) {
    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final startDate = DateTime(now.year, now.month, now.day - days);
    return DateRange(startDate: startDate, endDate: endDate);
  }

  /// Create a DateRange for a specific month
  factory DateRange.month(int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59, 999);
    return DateRange(startDate: startDate, endDate: endDate);
  }
}

/// Helper class for query params
class TimeEntryQueryParams {
  final int? limit;
  final int? offset;
  final String? orderBy;

  const TimeEntryQueryParams({
    this.limit,
    this.offset,
    this.orderBy,
  });

  /// Create query params for pagination
  factory TimeEntryQueryParams.paged({
    required int page,
    required int pageSize,
    String? orderBy,
  }) {
    return TimeEntryQueryParams(
      limit: pageSize,
      offset: page * pageSize,
      orderBy: orderBy ?? 'dt DESC',
    );
  }

  /// Create query params for the most recent entries
  factory TimeEntryQueryParams.recent(int count) {
    return TimeEntryQueryParams(
      limit: count,
      orderBy: 'dt DESC',
    );
  }
}

/// Class to represent tracking status
class TrackingStatus {
  final bool isTracking;
  final Duration elapsedTime;
  final Duration todayDuration;
  final Duration totalDuration;
  final TimeEntry? currentEntry;
  final String? error;

  const TrackingStatus({
    required this.isTracking,
    required this.elapsedTime,
    required this.todayDuration,
    required this.totalDuration,
    this.currentEntry,
    this.error,
  });

  bool get hasError => error != null;
}
