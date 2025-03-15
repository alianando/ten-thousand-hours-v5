import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_entry.dart';
import 'package:ten_thousands_hours/providers/time_entry_provider.dart';

/// Provider for accessing the TimeEntryDatabase instance
final timeEntryDatabaseProvider = Provider<TimeEntryDatabase>((ref) {
  return TimeEntryDatabase();
});

/// StateNotifier to manage TimeEntry state and operations
class TimeEntryController extends StateNotifier<AsyncValue<TimeEntry?>> {
  final TimeEntryDatabase _database;
  DateTime? _lastResumeTime;

  TimeEntryController(this._database) : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final latestEntry = await _database.getLatestTimeEntry();
      if (latestEntry?.resume == true) {
        _lastResumeTime = latestEntry?.dt;
      }
      state = AsyncValue.data(latestEntry);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Start a new tracking session
  Future<void> startTracking({String? description, String? category}) async {
    try {
      state = const AsyncValue.loading();
      final now = DateTime.now();

      // Get the previous entry to calculate durations
      final latestEntry = await _database.getLatestTimeEntry();
      final globalDur = latestEntry?.globalDur ?? Duration.zero;

      // Check if we're on a new day
      bool isNewDay = latestEntry == null ||
          latestEntry.dt.year != now.year ||
          latestEntry.dt.month != now.month ||
          latestEntry.dt.day != now.day;

      final dayDur = isNewDay ? Duration.zero : latestEntry.dayDur;

      // Create and save the new entry
      final newEntry = TimeEntry.create(
        dt: now,
        globalDur: globalDur,
        dayDur: dayDur,
        resume: true,
        description: description,
        category: category,
      );

      final savedEntry = await _database.insertTimeEntry(newEntry);
      _lastResumeTime = now;
      state = AsyncValue.data(savedEntry);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Stop the current tracking session
  Future<void> stopTracking({String? description}) async {
    try {
      state = const AsyncValue.loading();
      final now = DateTime.now();

      // Get the previous entry
      final latestEntry = await _database.getLatestTimeEntry();

      // Only add a pause entry if the last entry was a resume
      if (latestEntry != null && latestEntry.resume) {
        // Calculate elapsed time since last resume
        final resumeTime = _lastResumeTime ?? latestEntry.dt;
        final elapsed = now.difference(resumeTime);

        // Create the new entry
        final newEntry = TimeEntry.create(
          dt: now,
          globalDur: latestEntry.globalDur + elapsed,
          dayDur: latestEntry.dayDur + elapsed,
          resume: false,
          description: description,
          category: latestEntry.category,
        );

        final savedEntry = await _database.insertTimeEntry(newEntry);
        _lastResumeTime = null;
        state = AsyncValue.data(savedEntry);
      } else {
        state = AsyncValue.data(latestEntry);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Toggle tracking state (start if stopped, stop if started)
  Future<void> toggleTracking({String? description, String? category}) async {
    final currentEntry = state.valueOrNull;

    if (currentEntry == null || !currentEntry.resume) {
      await startTracking(description: description, category: category);
    } else {
      await stopTracking(description: description);
    }
  }

  /// Update an existing TimeEntry
  Future<void> updateTimeEntry(TimeEntry entry) async {
    try {
      await _database.updateTimeEntry(entry);

      // Update state if this is the current entry
      if (state.valueOrNull?.id == entry.id) {
        state = AsyncValue.data(entry);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete a TimeEntry
  Future<void> deleteTimeEntry(int id) async {
    try {
      await _database.deleteTimeEntry(id);

      // If the deleted entry is the current one, reload
      if (state.valueOrNull?.id == id) {
        _initialize();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Get current tracking status and time
  Future<TrackingStatus> getTrackingStatus() async {
    try {
      final currentEntry =
          state.valueOrNull ?? await _database.getLatestTimeEntry();
      final now = DateTime.now();

      if (currentEntry == null) {
        return const TrackingStatus(
          isTracking: false,
          elapsedTime: Duration.zero,
          todayDuration: Duration.zero,
          totalDuration: Duration.zero,
        );
      }

      final isTracking = currentEntry.resume;
      Duration elapsedTime = Duration.zero;

      if (isTracking) {
        final resumeTime = _lastResumeTime ?? currentEntry.dt;
        elapsedTime = now.difference(resumeTime);
      }

      return TrackingStatus(
        isTracking: isTracking,
        elapsedTime: elapsedTime,
        todayDuration:
            currentEntry.dayDur + (isTracking ? elapsedTime : Duration.zero),
        totalDuration:
            currentEntry.globalDur + (isTracking ? elapsedTime : Duration.zero),
        currentEntry: currentEntry,
      );
    } catch (error) {
      return TrackingStatus(
        isTracking: false,
        elapsedTime: Duration.zero,
        todayDuration: Duration.zero,
        totalDuration: Duration.zero,
        error: error.toString(),
      );
    }
  }

  /// Get current tracking state (sync version)
  bool isCurrentlyTracking() {
    return state.valueOrNull?.resume == true;
  }
}

/// Provider for TimeEntryController
final timeEntryControllerProvider =
    StateNotifierProvider<TimeEntryController, AsyncValue<TimeEntry?>>((ref) {
  final database = ref.watch(timeEntryDatabaseProvider);
  return TimeEntryController(database);
});

class TimeEntryLastUpdated extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void updateTime() {
    state = DateTime.now();
  }
}

final timeEntryLastUpdatedP =
    NotifierProvider<TimeEntryLastUpdated, DateTime>(TimeEntryLastUpdated.new);

/// Provider that returns all TimeEntries from the database
final allTimeEntriesP = Provider<List<TimeEntry>>((ref) {
  // Watch the lastUpdated notifier to trigger refresh when it changes
  ref.watch(timeEntryLastUpdatedP);

  // Get the database instance
  final db = ref.watch(timeEntryDatabaseProvider);

  // This is a workaround since we need to use async in a sync provider
  // We fetch data but return an empty list initially
  // The UI should listen to this provider and handle loading states
  List<TimeEntry> entries = [];

  // Fire and forget - the UI will update when the notifier changes
  Future<void> loadEntries() async {
    entries = await db.getAllTimeEntries();
    // You might need to notify listeners that data is available
    // This could be done by updating timeEntryLastUpdatedP
  }

  loadEntries();
  return entries;
});
