import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';

import '../../providers/time_data_provider.dart';

final currentTPProvider = Provider((ref) {
  final timeData = ref.watch(timeDataProvider);
  return timeData.today.durPoint;
});

final sessionStatusProvider = Provider((ref) {
  final timeData = ref.watch(timeDataProvider);
  final now = DateTime.now();
  final session = timeData.sessionData;

  final bool isInSession =
      now.isAfter(session.sessionStartDt) && now.isBefore(session.sessionEndDt);

  return {
    'isInSession': isInSession,
    'sessionStartTime': session.sessionStartDt,
    'sessionEndTime': session.sessionEndDt,
    'timeRemaining':
        isInSession ? session.sessionEndDt.difference(now) : const Duration(),
  };
});

class CurrentTimePoint extends ConsumerWidget {
  const CurrentTimePoint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastPoint = ref.watch(currentTPProvider);
    final sessionStatus = ref.watch(sessionStatusProvider);
    final isInSession = sessionStatus['isInSession'] as bool;
    final timeTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with session status
            Row(
              children: [
                _buildCircleStatus(context, isInSession),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInSession ? 'Active Session' : 'Session Paused',
                      style: timeTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isInSession
                          ? 'Time remaining: ${_formatDuration(sessionStatus['timeRemaining'] as Duration)}'
                          : 'Next session starts soon',
                      style: timeTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Time counter - prominent display
            Center(
              child: Column(
                children: [
                  Text(
                    'Today\'s Progress',
                    style: timeTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildTimeCounter(context, lastPoint.dur),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Session schedule timeline
            _buildSessionTimeline(
              context,
              sessionStatus['sessionStartTime'] as DateTime,
              sessionStatus['sessionEndTime'] as DateTime,
              lastPoint.dt,
              isInSession,
            ),

            const SizedBox(height: 16),

            // Progress indicators
            _buildProgressRow(context, isInSession, lastPoint.dur),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleStatus(BuildContext context, bool isInSession) {
    final color = isInSession
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.tertiary;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
      ),
      child: Center(
        child: Icon(
          isInSession ? Icons.play_arrow_rounded : Icons.pause_rounded,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildTimeCounter(BuildContext context, Duration duration) {
    // final List<String> parts = DtUtils.durToHMS(duration).split(':');
    // final colorScheme = Theme.of(context).colorScheme;
    // final textTheme = Theme.of(context).textTheme;
    String hourString() {
      int h = duration.inHours;
      if (h < 10) {
        return '0$h';
      }
      return '$h';
    }

    String minuteString() {
      final h = duration.inHours;

      int m = (duration - Duration(hours: h)).inMinutes;
      if (m < 10) {
        return '0$m';
      }
      return '$m';
    }

    String secondString() {
      final h = duration.inHours;
      final m = (duration - Duration(hours: h)).inMinutes;

      int s = (duration - Duration(hours: h, minutes: m)).inSeconds;
      if (s < 10) {
        return '0$s';
      }
      return '$s';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeUnit(context, hourString(), 'h'),
        _buildTimeSeparator(context),
        _buildTimeUnit(context, minuteString(), 'm'),
        _buildTimeSeparator(context),
        _buildTimeUnit(context, secondString(), 's'),
      ],
    );
  }

  Widget _buildTimeUnit(BuildContext context, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                ),
          ),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSessionTimeline(BuildContext context, DateTime start,
      DateTime end, DateTime? currentPoint, bool isInSession) {
    final now = DateTime.now();
    final total = end.difference(start).inMinutes;
    double progress = 0;

    if (total > 0) {
      final elapsed = now.difference(start).inMinutes;
      progress = elapsed / total;
      progress = progress.clamp(0.0, 1.0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Session Timeline',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),

        // Timeline bar
        Stack(
          children: [
            // Background bar
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Progress bar
            Container(
              width: MediaQuery.of(context).size.width *
                  progress *
                  0.8, // adjust factor as needed
              height: 8,
              decoration: BoxDecoration(
                color: isInSession
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),

        // Time labels
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DtUtils.dtToHM(start),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Current: ${currentPoint != null ? DtUtils.dtToHM(currentPoint) : 'N/A'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                DtUtils.dtToHM(end),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow(
      BuildContext context, bool isInSession, Duration totalDuration) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildProgressIndicator(
          context,
          'Status',
          isInSession ? 'Active' : 'Paused',
          isInSession
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          isInSession ? colorScheme.primary : colorScheme.tertiary,
        ),
        _buildProgressIndicator(
          context,
          'Focus Time',
          _formatHoursMinutes(totalDuration),
          Icons.access_time_filled,
          colorScheme.secondary,
        ),
        _buildProgressIndicator(
          context,
          isInSession ? 'Remaining' : 'Next Start',
          isInSession
              ? '${(totalDuration.inMinutes / 60).toStringAsFixed(1)} hrs'
              : 'Soon',
          isInSession ? Icons.hourglass_bottom : Icons.schedule,
          isInSession ? colorScheme.primary : colorScheme.tertiary,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatHoursMinutes(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
