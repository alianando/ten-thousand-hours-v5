import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/providers/time_entry/tme_entry_db_pro.dart';
import '../providers/time_entry_provider.dart';

/// Example widget showing how to use tracking status provider
class TrackingStatusWidget extends ConsumerWidget {
  const TrackingStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingStatus = ref.watch(trackingStatusProvider);

    return trackingStatus.when(
      data: (status) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status.isTracking ? 'Currently Tracking' : 'Not Tracking',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: status.isTracking ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text('Current session: ${_formatDuration(status.elapsedTime)}'),
            Text('Today: ${_formatDuration(status.todayDuration)}'),
            Text('All time: ${_formatDuration(status.totalDuration)}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(timeEntryControllerProvider.notifier).toggleTracking();
              },
              child: Text(status.isTracking ? 'Stop' : 'Start'),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Example widget showing how to use daily summary provider
class DailySummaryWidget extends ConsumerWidget {
  const DailySummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get summary for the last 7 days
    final dailySummary = ref.watch(
      dailySummaryProvider(DateRange.lastDays(7)),
    );

    return dailySummary.when(
      data: (summary) {
        if (summary.isEmpty) {
          return const Text('No data for the past week');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summary.length,
          itemBuilder: (context, index) {
            final day = summary[index];
            final date = day['date'] as String;
            final dayDuration = day['dayDuration'] as Duration;

            return ListTile(
              title: Text(date),
              trailing: Text(_formatDuration(dayDuration)),
            );
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }
}

/// Example widget showing how to use time entry statistics provider
class StatisticsWidget extends ConsumerWidget {
  const StatisticsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistics = ref.watch(timeEntryStatisticsProvider);

    return statistics.when(
      data: (stats) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total entries: ${stats['totalEntries']}'),
            Text('Resume events: ${stats['resumeCount']}'),
            Text('Pause events: ${stats['pauseCount']}'),
            Text(
              'Total time: ${_formatDuration(stats['latestGlobalDuration'] as Duration)}',
            ),
            Text('Active days: ${stats['activeDaysCount']}'),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, _) => Text('Error: $error'),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final days = hours ~/ 24;
    final remainingHours = hours % 24;

    if (days > 0) {
      return '$days days, $remainingHours hours';
    } else {
      return '$hours hours';
    }
  }
}
