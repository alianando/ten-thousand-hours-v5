import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/providers/time_entry/tme_entry_db_pro.dart';
import '../models/time_entry.dart';
import '../providers/time_entry_provider.dart';
import '../providers/time_entry_privious_data.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('10,000 Hours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsBottomSheet(context, ref);
            },
          ),
        ],
      ),
      body: ListView(
        shrinkWrap: true,
        physics: const ScrollPhysics(),
        children: const [
          TrackingStatusCard(),
          // WeeklyStatsCard(),
          AllEvents(),
        ],
      ),
      // const AllEvents(),
      // body: const SingleChildScrollView(
      //   padding: EdgeInsets.all(16.0),
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       // Current tracking status
      //       TrackingStatusCard(),

      //       SizedBox(height: 16),

      //       // Today's summary
      //       TodaySummaryCard(),

      //       SizedBox(height: 16),

      //       // Recent activity
      //       RecentActivityCard(),

      //       SizedBox(height: 16),

      //       // Weekly stats
      //       WeeklyStatsCard(),

      //       SizedBox(height: 16),

      //       // All-time statistics
      //       AllTimeStatsCard(),
      //     ],
      //   ),
      // ),
      floatingActionButton: const TrackingActionButton(),
    );
  }

  void _showSettingsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Import previous data button
              const ImportPreviousDataWidget(),

              const SizedBox(height: 8),

              // Fix durations button
              ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return const AlertDialog(
                        title: Text('Fixing durations'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('This may take a while...'),
                          ],
                        ),
                      );
                    },
                  );

                  try {
                    await ref.read(rebuildDayDurationsProvider.future);
                    await ref.read(rebuildGlobalDurationsProvider.future);

                    if (context.mounted) {
                      Navigator.pop(context); // Close loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Durations fixed successfully')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Fix Durations'),
              ),

              const SizedBox(height: 8),

              // Clear all data button (with confirmation)
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Clear All Data?'),
                        content: const Text(
                          'This action cannot be undone. All your tracking '
                          'data will be permanently deleted.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);

                              final database =
                                  ref.read(timeEntryDatabaseProvider);
                              await database.clearAllTimeEntries();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('All data cleared')),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Clear All Data'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AllEvents extends ConsumerWidget {
  const AllEvents({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(allTimeEntriesP);
    // if (allEntry.isLoading) {
    //   return const Center(
    //     child: CircularProgressIndicator(),
    //   );
    // }
    // if (allEntry.hasError) {
    //   return const Center(
    //     child: Text('Error'),
    //   );
    // }

    // if (allEntry.hasValue) {
    //   final entries = allEntry.value;
    //   debugPrint('Entries: $entries');
    //   if (entries == null) {
    //     return const Center(
    //       child: Text('Null data'),
    //     );
    //   }

    // }
    // if (allEntry.isEmpty) {
    //   return const Center(
    //     child: Text('No data'),
    //   );
    // }
    // final entries = allEntry;
    return ListView.builder(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      itemCount: entries!.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return ListTile(
          title: Text(entry.dt.toString()),
          subtitle: Text(
            'Ongoing: ${entry.resume}, ${entry.dayDur}, ${entry.globalDur}',
          ),
          trailing: IconButton(
            onPressed: () {
              if (entry.id == null) {
                return;
              }
              ref
                  .read(timeEntryControllerProvider.notifier)
                  .deleteTimeEntry(entry.id!);
            },
            icon: const Icon(Icons.delete),
          ),
        );
      },
    );
  }
}

/// Widget to display current tracking status
class TrackingStatusCard extends ConsumerWidget {
  const TrackingStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingStatus = ref.watch(trackingStatusProvider);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: trackingStatus.when(
          data: (status) {
            final hours = status.totalDuration.inHours;
            final minutes = (status.totalDuration.inMinutes % 60)
                .toString()
                .padLeft(2, '0');
            final seconds = (status.totalDuration.inSeconds % 60)
                .toString()
                .padLeft(2, '0');
            final totalTimeFormatted = '$hours:$minutes:$seconds';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      status.isTracking
                          ? Icons.play_circle
                          : Icons.pause_circle,
                      color: status.isTracking ? Colors.green : Colors.grey,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      status.isTracking ? 'Currently Tracking' : 'Not Tracking',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: status.isTracking ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTimerRow(
                  label: 'Current session:',
                  duration: status.elapsedTime,
                  isActive: status.isTracking,
                ),
                const SizedBox(height: 8),
                _buildTimerRow(
                  label: 'Today:',
                  duration: status.todayDuration,
                  isActive: false,
                ),
                const SizedBox(height: 8),
                _buildTimerRow(
                  label: 'All time:',
                  duration: status.totalDuration,
                  isActive: false,
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }

  Widget _buildTimerRow({
    required String label,
    required Duration duration,
    required bool isActive,
  }) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          '$hours:$minutes:$seconds',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Widget to display today's summary
class TodaySummaryCard extends ConsumerWidget {
  const TodaySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayEntries = ref.watch(
      timeEntriesForDayProvider(DateTime.now()),
    );

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Summary",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            todayEntries.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No activity recorded today',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final sessionCount = entries.where((e) => e.resume).length;
                final totalToday =
                    entries.isNotEmpty ? entries.last.dayDur : Duration.zero;

                final trackingStatus = ref.watch(trackingStatusProvider);
                Duration effectiveTotalToday = totalToday;

                if (trackingStatus is AsyncData &&
                    trackingStatus.value!.isTracking) {
                  effectiveTotalToday = trackingStatus.value!.todayDuration;
                }

                return Column(
                  children: [
                    _buildSummaryRow(
                      icon: Icons.repeat,
                      label: 'Sessions',
                      value: sessionCount.toString(),
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      icon: Icons.timer,
                      label: 'Total time',
                      value: _formatDuration(effectiveTotalToday),
                    ),
                    if (entries.isNotEmpty && entries.last.resume)
                      const Padding(
                        padding: EdgeInsets.only(top: 12.0),
                        child: Text(
                          'Currently tracking',
                          style: TextStyle(
                            color: Colors.green,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                child: Text('Error: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');

    return '$hours:$minutes';
  }
}

/// Widget to display recent activity
class RecentActivityCard extends ConsumerWidget {
  const RecentActivityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Showing the most recent 5 entries
    final recentEntries = ref.watch(
      allTimeEntriesProvider(
        TimeEntryQueryParams(
          limit: 5,
          orderBy: 'dt DESC',
        ),
      ),
    );

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to detailed history page
                    // (Not implemented in this version)
                  },
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            recentEntries.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No activity recorded yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        entry.resume ? Icons.play_arrow : Icons.pause,
                        color: entry.resume ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        entry.resume ? 'Started tracking' : 'Stopped tracking',
                      ),
                      subtitle: Text(
                        '${_formatDateTime(entry.dt)}${entry.category != null ? ' • ${entry.category}' : ''}',
                      ),
                      trailing: Text(
                        _formatDuration(entry.dayDur),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                child: Text('Error: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      // Today
      return 'Today ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day - 1) {
      // Yesterday
      return 'Yesterday ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      // Other date
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');

    return '$hours:$minutes';
  }
}

/// Widget to display weekly statistics
class WeeklyStatsCard extends ConsumerWidget {
  const WeeklyStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day - now.weekday + 1);

    final weekSummary = ref.watch(
      dailySummaryProvider(
        DateRange(
          startDate: weekStart,
          endDate: now,
        ),
      ),
    );

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Week',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            weekSummary.when(
              data: (summary) {
                if (summary.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No activity this week',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                // Calculate weekly totals
                int totalMinutes = 0;
                int sessionsCount = 0;
                int daysActive = summary.length;

                for (final day in summary) {
                  final duration = day['dayDuration'] as Duration;
                  totalMinutes += duration.inMinutes;

                  final resumeCount = day['resumeCount'] as int;
                  sessionsCount += resumeCount;
                }

                final hours = totalMinutes ~/ 60;
                final minutes = totalMinutes % 60;

                return Column(
                  children: [
                    _buildSummaryRow(
                      icon: Icons.calendar_today,
                      label: 'Days active',
                      value: daysActive.toString(),
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      icon: Icons.repeat,
                      label: 'Total sessions',
                      value: sessionsCount.toString(),
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      icon: Icons.timer,
                      label: 'Total time',
                      value: '$hours:${minutes.toString().padLeft(2, '0')}',
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                child: Text('Error: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Widget to display all-time statistics
class AllTimeStatsCard extends ConsumerWidget {
  const AllTimeStatsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistics = ref.watch(timeEntryStatisticsProvider);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All-Time Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            statistics.when(
              data: (stats) {
                final totalDuration = stats['latestGlobalDuration'] as Duration;
                final activeDays = stats['activeDaysCount'] as int;
                final totalSessions = stats['resumeCount'] as int;

                // Calculate progress toward 10,000 hours
                final totalHours = totalDuration.inHours;
                final progressPercent = (totalHours / 10000) * 100;
                final progressText = progressPercent.toStringAsFixed(2);

                return Column(
                  children: [
                    _buildProgressIndicator(progressPercent),
                    const SizedBox(height: 16),
                    Text(
                      '$totalHours hours of 10,000 ($progressText%)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatRow(
                      icon: Icons.calendar_today,
                      label: 'Days active',
                      value: activeDays.toString(),
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      icon: Icons.repeat,
                      label: 'Total sessions',
                      value: totalSessions.toString(),
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      icon: Icons.alarm,
                      label: 'Avg. daily time',
                      value: activeDays > 0
                          ? _formatDuration(
                              Duration(
                                microseconds:
                                    totalDuration.inMicroseconds ~/ activeDays,
                              ),
                            )
                          : '0:00',
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                child: Text('Error: $err'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double percent) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: CircularProgressIndicator(
            value: percent / 100,
            strokeWidth: 12,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Text(
              'complete',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');

    return '$hours:$minutes';
  }
}

/// Floating action button for tracking control
class TrackingActionButton extends ConsumerWidget {
  const TrackingActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingStatusAsync = ref.watch(trackingStatusProvider);

    return trackingStatusAsync.when(
      data: (status) {
        final isTracking = status.isTracking;

        return FloatingActionButton.extended(
          onPressed: () {
            if (isTracking) {
              // Stop tracking
              ref.read(timeEntryControllerProvider.notifier).stopTracking();
            } else {
              // Start tracking
              _showCategoryDialog(context, ref);
            }
          },
          backgroundColor: isTracking ? Colors.red : Colors.green,
          label: Row(
            children: [
              Icon(isTracking ? Icons.pause : Icons.play_arrow),
              const SizedBox(width: 8),
              Text(isTracking ? 'Stop' : 'Start'),
            ],
          ),
        );
      },
      loading: () => const FloatingActionButton(
        onPressed: null,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
      error: (_, __) => FloatingActionButton(
        onPressed: () {
          ref.read(timeEntryControllerProvider.notifier).toggleTracking();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start Tracking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  hintText: 'e.g., Coding, Learning, Practice',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final category = categoryController.text.trim();
                ref.read(timeEntryControllerProvider.notifier).startTracking(
                      category: category.isNotEmpty ? category : null,
                    );
              },
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }
}

/// Widget for importing previous data
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
                        const Text('Import completed!'),
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
