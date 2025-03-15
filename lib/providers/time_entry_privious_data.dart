import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/time_entry.dart';

final previousData = [
  {
    "lastUpdate": "2025-03-01T00:00:00.000",
    "durPoint": {
      "dt": "2025-03-01T23:59:59.999999",
      "dur": 264999,
      "typ": "pause"
    },
    "events": [
      {"dt": "2025-03-01T00:00:00.000", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-01T19:23:11.369571", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-01T19:24:07.706461", "dur": 0, "typ": "resume"},
      {"dt": "2025-03-01T19:27:56.706482", "dur": 229000, "typ": "pause"},
      {"dt": "2025-03-01T19:47:54.783153", "dur": 229000, "typ": "resume"},
      {"dt": "2025-03-01T19:48:30.782263", "dur": 264999, "typ": "pause"},
      {"dt": "2025-03-01T23:59:59.999999", "dur": 264999, "typ": "pause"},
      {"dt": "2025-03-01T23:59:59.999999", "dur": 264999, "typ": "pause"}
    ]
  },
  {
    "lastUpdate": "2025-03-02T00:00:00.000",
    "durPoint": {
      "dt": "2025-03-02T23:59:59.999999",
      "dur": 4498918,
      "typ": "pause"
    },
    "events": [
      {"dt": "2025-03-02T00:00:00.000", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-02T13:37:39.471314", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-02T13:42:26.440352", "dur": 0, "typ": "resume"},
      {"dt": "2025-03-02T13:53:55.359218", "dur": 688918, "typ": "pause"},
      {"dt": "2025-03-02T14:01:00.358468", "dur": 688918, "typ": "resume"},
      {"dt": "2025-03-02T14:30:49.358544", "dur": 2477918, "typ": "pause"},
      {"dt": "2025-03-02T14:34:47.362470", "dur": 2477918, "typ": "resume"},
      {"dt": "2025-03-02T14:48:30.359264", "dur": 3300915, "typ": "pause"},
      {"dt": "2025-03-02T14:54:25.361550", "dur": 3300915, "typ": "resume"},
      {"dt": "2025-03-02T14:54:34.363507", "dur": 3309917, "typ": "pause"},
      {"dt": "2025-03-02T15:16:16.358813", "dur": 3309917, "typ": "resume"},
      {"dt": "2025-03-02T15:35:49.359549", "dur": 4482918, "typ": "pause"},
      {"dt": "2025-03-02T15:55:30.652128", "dur": 4482918, "typ": "resume"},
      {"dt": "2025-03-02T15:55:46.651807", "dur": 4498918, "typ": "pause"},
      {"dt": "2025-03-02T23:59:59.999999", "dur": 4498918, "typ": "pause"}
    ]
  },
  {
    "lastUpdate": "2025-03-07T00:00:00.000",
    "durPoint": {
      "dt": "2025-03-07T23:59:59.999999",
      "dur": 4412825,
      "typ": "pause"
    },
    "events": [
      {"dt": "2025-03-07T00:00:00.000", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-07T01:17:25.798925", "dur": 0, "typ": "resume"},
      {"dt": "2025-03-07T01:38:48.828771", "dur": 1283029, "typ": "pause"},
      {"dt": "2025-03-07T02:19:48.841123", "dur": 1283029, "typ": "resume"},
      {"dt": "2025-03-07T02:47:58.169180", "dur": 2972357, "typ": "pause"},
      {"dt": "2025-03-07T02:52:25.400386", "dur": 2972357, "typ": "resume"},
      {"dt": "2025-03-07T03:13:20.891915", "dur": 4227849, "typ": "pause"},
      {"dt": "2025-03-07T03:16:50.599041", "dur": 4227849, "typ": "resume"},
      {"dt": "2025-03-07T03:18:47.514375", "dur": 4344764, "typ": "pause"},
      {"dt": "2025-03-07T03:29:09.696916", "dur": 4344764, "typ": "resume"},
      {"dt": "2025-03-07T03:30:17.757584", "dur": 4412825, "typ": "pause"},
      {"dt": "2025-03-07T23:59:59.999999", "dur": 4412825, "typ": "pause"}
    ]
  },
  {
    "lastUpdate": "2025-03-08T00:00:00.000",
    "durPoint": {
      "dt": "2025-03-08T23:59:59.999999",
      "dur": 3600000,
      "typ": "pause"
    },
    "events": [
      {"dt": "2025-03-08T00:00:00.000", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-08T16:59:02.673970", "dur": 0, "typ": "resume"},
      {"dt": "2025-03-08T17:59:02.673970", "dur": 3600000, "typ": "pause"},
      {"dt": "2025-03-08T23:59:59.999999", "dur": 3600000, "typ": "pause"},
      {"dt": "2025-03-08T23:59:59.999999", "dur": 3600000, "typ": "pause"}
    ]
  },
  {
    "lastUpdate": "2025-03-09T00:00:00.000",
    "durPoint": {
      "dt": "2025-03-09T23:59:59.999999",
      "dur": 455454,
      "typ": "pause"
    },
    "events": [
      {"dt": "2025-03-09T00:00:00.000", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-09T21:59:52.035082", "dur": 0, "typ": "resume"},
      {"dt": "2025-03-09T22:07:27.489608", "dur": 455454, "typ": "pause"},
      {"dt": "2025-03-09T23:59:59.999999", "dur": 455454, "typ": "pause"}
    ]
  },
  {
    "lastUpdate": "2025-03-10T00:00:00.000",
    "durPoint": {
      "dt": "2025-03-10T23:59:59.999999",
      "dur": 2727992,
      "typ": "pause"
    },
    "events": [
      {"dt": "2025-03-10T00:00:00.000", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-10T03:38:58.603173", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-10T03:59:55.481940", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-10T14:30:39.246199", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-10T14:55:32.240844", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-10T15:01:50.557256", "dur": 0, "typ": "resume"},
      {"dt": "2025-03-10T15:47:18.549887", "dur": 2727992, "typ": "pause"},
      {"dt": "2025-03-10T23:59:59.999999", "dur": 2727992, "typ": "pause"}
    ]
  },
  {
    "lastUpdate": "2025-03-11T00:00:00.000",
    "durPoint": {
      "dt": "2025-03-11T23:59:59.999999",
      "dur": 6554387,
      "typ": "pause"
    },
    "events": [
      {"dt": "2025-03-11T00:00:00.000", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-11T00:56:02.733049", "dur": 0, "typ": "resume"},
      {"dt": "2025-03-11T02:35:29.754153", "dur": 5967021, "typ": "pause"},
      {"dt": "2025-03-11T21:42:26.852600", "dur": 5967021, "typ": "resume"},
      {"dt": "2025-03-11T21:52:14.218835", "dur": 6554387, "typ": "pause"},
      {"dt": "2025-03-11T23:59:59.999999", "dur": 6554387, "typ": "pause"}
    ]
  },
  {
    "lastUpdate": "2025-03-13T00:00:00.000",
    "durPoint": {"dt": "2025-03-13T20:14:47.292180", "dur": 0, "typ": "resume"},
    "events": [
      {"dt": "2025-03-13T00:00:00.000", "dur": 0, "typ": "pause"},
      {"dt": "2025-03-13T20:14:47.292180", "dur": 0, "typ": "resume"}
    ]
  }
];

/// Import previous data into the TimeEntry database
Future<Map<String, dynamic>> importPreviousData() async {
  final database = TimeEntryDatabase();
  final results = {
    'total': previousData.length,
    'success': 0,
    'skipped': 0,
    'failed': 0,
    'entries': 0,
  };

  try {
    // Process each day's data
    for (final dayData in previousData) {
      try {
        final List<dynamic>? events = dayData['events'] as List<dynamic>?;
        if (events == null || events.isEmpty) {
          results['skipped'] = results['skipped']! + 1;
          continue;
        }

        // Sort events by datetime to ensure proper sequence
        events.sort((a, b) {
          final dtA = DateTime.parse(a['dt'] as String);
          final dtB = DateTime.parse(b['dt'] as String);
          return dtA.compareTo(dtB);
        });

        // Filter out duplicate end-of-day events
        final filteredEvents = <Map<String, dynamic>>[];
        for (int i = 0; i < events.length; i++) {
          // Skip duplicated end-of-day events
          if (i < events.length - 1 &&
              events[i]['dt'] == events[i + 1]['dt'] &&
              events[i]['dur'] == events[i + 1]['dur'] &&
              events[i]['typ'] == events[i + 1]['typ']) {
            continue;
          }
          filteredEvents.add(events[i] as Map<String, dynamic>);
        }

        // Process each event and convert to TimeEntry
        for (final event in filteredEvents) {
          // Parse event data
          final dt = DateTime.parse(event['dt'] as String);
          final durationMs = event['dur'] as int;
          final resume = event['typ'] == 'resume';

          // Create and save TimeEntry
          final entry = TimeEntry(
            dt: dt,
            globalDur: Duration(milliseconds: durationMs),
            dayDur: Duration(milliseconds: durationMs),
            resume: resume,
          );

          await database.insertTimeEntry(entry);
          results['entries'] = results['entries']! + 1;
        }

        results['success'] = results['success']! + 1;
      } catch (e) {
        results['failed'] = results['failed']! + 1;
        print('Error processing day data: $e');
      }
    }
  } catch (e) {
    print('Error during import: $e');
  }

  return results;
}

/// Provider for importing previous data
final importPreviousDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return await importPreviousData();
});

/// Rebuild the day durations (fixes incorrect day durations in imported data)
Future<void> rebuildDayDurations() async {
  final database = TimeEntryDatabase();

  // Get all entries sorted by date
  final entries = await database.getAllTimeEntries(orderBy: 'dt ASC');
  if (entries.isEmpty) return;

  // Group entries by day
  final Map<String, List<TimeEntry>> entriesByDay = {};
  for (final entry in entries) {
    final dateKey =
        '${entry.dt.year}-${entry.dt.month.toString().padLeft(2, '0')}-${entry.dt.day.toString().padLeft(2, '0')}';
    if (!entriesByDay.containsKey(dateKey)) {
      entriesByDay[dateKey] = [];
    }
    entriesByDay[dateKey]!.add(entry);
  }

  // Process each day to fix day durations
  await database.database.then((db) async {
    await db.transaction((txn) async {
      for (final dateKey in entriesByDay.keys) {
        final dayEntries = entriesByDay[dateKey]!;

        // Reset day tracking
        Duration dayDuration = Duration.zero;
        DateTime? lastResumeTime;

        // Process each entry chronologically
        for (int i = 0; i < dayEntries.length; i++) {
          final entry = dayEntries[i];

          if (entry.resume) {
            // This is a resume entry - mark the time
            lastResumeTime = entry.dt;

            // Update entry with current day duration
            await txn.update(
              TimeEntryDatabase.tableEntries,
              {'day_dur': dayDuration.inMilliseconds},
              where: 'id = ?',
              whereArgs: [entry.id],
            );
          } else if (lastResumeTime != null) {
            // This is a pause entry after a resume
            final elapsed = entry.dt.difference(lastResumeTime);
            dayDuration += elapsed;
            lastResumeTime = null;

            // Update entry with new day duration
            await txn.update(
              TimeEntryDatabase.tableEntries,
              {'day_dur': dayDuration.inMilliseconds},
              where: 'id = ?',
              whereArgs: [entry.id],
            );
          } else {
            // This is a pause entry without a preceding resume on this day
            // Just update it with the current day duration
            await txn.update(
              TimeEntryDatabase.tableEntries,
              {'day_dur': dayDuration.inMilliseconds},
              where: 'id = ?',
              whereArgs: [entry.id],
            );
          }
        }
      }
    });
  });
}

/// Provider for rebuilding day durations
final rebuildDayDurationsProvider = FutureProvider<void>((ref) async {
  await rebuildDayDurations();
});

/// Rebuild all global durations (fixes cumulative duration)
Future<void> rebuildGlobalDurations() async {
  final database = TimeEntryDatabase();

  // Get all entries sorted by date
  final entries = await database.getAllTimeEntries(orderBy: 'dt ASC');
  if (entries.isEmpty) return;

  // Process entries in chronological order
  Duration globalDuration = Duration.zero;
  DateTime? lastResumeTime;

  await database.database.then((db) async {
    await db.transaction((txn) async {
      for (final entry in entries) {
        if (entry.resume) {
          // This is a resume entry - mark the time
          lastResumeTime = entry.dt;

          // Update entry with current global duration
          await txn.update(
            TimeEntryDatabase.tableEntries,
            {'global_dur': globalDuration.inMilliseconds},
            where: 'id = ?',
            whereArgs: [entry.id],
          );
        } else if (lastResumeTime != null) {
          // This is a pause entry after a resume
          final elapsed = entry.dt.difference(lastResumeTime!);
          globalDuration += elapsed;
          lastResumeTime = null;

          // Update entry with new global duration
          await txn.update(
            TimeEntryDatabase.tableEntries,
            {'global_dur': globalDuration.inMilliseconds},
            where: 'id = ?',
            whereArgs: [entry.id],
          );
        } else {
          // This is a pause entry without a preceding resume
          // Just update it with the current global duration
          await txn.update(
            TimeEntryDatabase.tableEntries,
            {'global_dur': globalDuration.inMilliseconds},
            where: 'id = ?',
            whereArgs: [entry.id],
          );
        }
      }
    });
  });
}

/// Provider for rebuilding global durations
final rebuildGlobalDurationsProvider = FutureProvider<void>((ref) async {
  await rebuildGlobalDurations();
});

/// Combined function to import data and rebuild durations
Future<Map<String, dynamic>> importAndFixData() async {
  // First import the data
  final importResults = await importPreviousData();

  // Then rebuild day durations
  await rebuildDayDurations();

  // Finally rebuild global durations
  await rebuildGlobalDurations();

  return {
    ...importResults,
    'fixedDurations': true,
  };
}

/// Provider for importing and fixing data
final importAndFixDataProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return await importAndFixData();
});

/// Widget to help import previous data
class ImportPreviousDataWidget extends ConsumerWidget {
  const ImportPreviousDataWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // Use AutoDisposeFutureProvider to prevent caching the result
        final provider =
            FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
          return importAndFixData();
        });

        // Watch the provider to start import
        ref.watch(provider);

        // Show dialog with loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Importing Data'),
              content: Consumer(
                builder: (context, ref, child) {
                  final import = ref.watch(provider);

                  return import.when(
                    data: (results) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Import completed!'),
                        const SizedBox(height: 8),
                        Text('Total days processed: ${results['total']}'),
                        Text('Days imported: ${results['success']}'),
                        Text('Days skipped: ${results['skipped']}'),
                        Text('Days failed: ${results['failed']}'),
                        Text('Total entries: ${results['entries']}'),
                        const SizedBox(height: 8),
                        Text(
                            'Day durations fixed: ${results['fixedDurations'] ? 'Yes' : 'No'}'),
                      ],
                    ),
                    loading: () => const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing data...'),
                      ],
                    ),
                    error: (error, _) => Text('Error: $error'),
                  );
                },
              ),
              actions: [
                Consumer(
                  builder: (context, ref, child) {
                    final import = ref.watch(provider);

                    return TextButton(
                      onPressed: import is AsyncData
                          ? () {
                              Navigator.of(context).pop();
                            }
                          : null,
                      child: const Text('OK'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
      child: const Text('Import Previous Data'),
    );
  }
}
