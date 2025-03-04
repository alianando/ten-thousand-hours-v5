import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ten_thousands_hours/models/time_data/model/day_model.dart';

import '../../providers/time_data_provider.dart';

final monthPro = Provider<List<DayModel>>((ref) {
  final timeData = ref.watch(timeDataProvider);
  final indices = timeData.indices.monthIndices;
  List<DayModel> days = [];
  for (var i = 0; i < indices.length; i++) {
    days.add(timeData.days[indices[i]]);
  }
  return days;
});

final monthStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final monthDays = ref.watch(monthPro);

  // Calculate total duration for the month
  final totalDuration = monthDays.fold<Duration>(
    Duration.zero,
    (total, day) => total + day.durPoint.dur,
  );

  // Calculate active days (days with tracked time)
  final activeDays =
      monthDays.where((day) => day.durPoint.dur.inMinutes > 0).length;

  // Find the day with maximum duration
  final maxDurationDay = monthDays.isEmpty
      ? null
      : monthDays.reduce(
          (curr, next) => curr.durPoint.dur > next.durPoint.dur ? curr : next);

  // Calculate average daily duration (only for days with activity)
  final averageDuration = activeDays > 0
      ? Duration(seconds: totalDuration.inSeconds ~/ activeDays)
      : Duration.zero;

  return {
    'totalDuration': totalDuration,
    'activeDays': activeDays,
    'maxDurationDay': maxDurationDay,
    'averageDuration': averageDuration,
  };
});

class MonthView extends ConsumerWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthDays = ref.watch(monthPro);
    final stats = ref.watch(monthStatsProvider);
    final now = DateTime.now();
    final currentMonth = DateFormat('MMMM yyyy').format(now);

    // Calculate maximum duration for scaling the heat map
    final maxDuration = monthDays.isEmpty
        ? const Duration(hours: 1)
        : monthDays
            .map((day) => day.durPoint.dur)
            .reduce((max, duration) => duration > max ? duration : max);

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, currentMonth, stats),
            const SizedBox(height: 16),
            _buildMonthCalendar(context, monthDays, maxDuration),
            const SizedBox(height: 16),
            _buildMonthStats(context, stats),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, String currentMonth, Map<String, dynamic> stats) {
    final totalDuration = stats['totalDuration'] as Duration;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentMonth,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Monthly Overview',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month,
                size: 18,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(totalDuration),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCalendar(
      BuildContext context, List<DayModel> monthDays, Duration maxDuration) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekdayOfMonth =
        firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    // Create a mapping of day of month to DayModel for quick lookup
    final dayModelMap = <int, DayModel>{};
    for (final day in monthDays) {
      final dayOfMonth = day.durPoint.dt.day;
      dayModelMap[dayOfMonth] = day;
    }

    // Adjust for start of week (assuming Monday is start of week)
    final leadingEmptyCells = firstWeekdayOfMonth - 1;
    final totalCells = leadingEmptyCells + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((day) => SizedBox(
                    width: 32,
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        ...List.generate(rows, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (colIndex) {
                final cellIndex = rowIndex * 7 + colIndex;
                final dayOfMonth = cellIndex - leadingEmptyCells + 1;

                // Check if this cell belongs to the current month
                if (dayOfMonth < 1 || dayOfMonth > daysInMonth) {
                  return const SizedBox(width: 32, height: 32);
                }

                final isToday = dayOfMonth == now.day;
                final dayModel = dayModelMap[dayOfMonth];
                final hasDuration =
                    dayModel != null && dayModel.durPoint.dur.inMinutes > 0;

                // Calculate intensity based on duration
                double intensity = 0;
                if (hasDuration) {
                  intensity =
                      dayModel.durPoint.dur.inMinutes / maxDuration.inMinutes;
                  intensity = intensity.clamp(
                      0.1, 1.0); // Ensure at least light color if any activity
                }

                final color = hasDuration
                    ? HSLColor.fromColor(Theme.of(context).colorScheme.primary)
                        .withLightness(0.9 -
                            (intensity *
                                0.5)) // Lighter to darker based on duration
                        .toColor()
                    : Colors.transparent;

                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayOfMonth',
                      style: TextStyle(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color: hasDuration
                            ? intensity > 0.5
                                ? Colors.white
                                : Colors.black87
                            : isToday
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthStats(BuildContext context, Map<String, dynamic> stats) {
    final activeDays = stats['activeDays'] as int;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final completionRate = daysPassed > 0 ? (activeDays / daysPassed * 100) : 0;
    final maxDurationDay = stats['maxDurationDay'] as DayModel?;
    final averageDuration = stats['averageDuration'] as Duration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Insights',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(
              context,
              'Active Days',
              '$activeDays / $daysInMonth',
              Icons.check_circle_outline,
              subtitle: '${completionRate.toStringAsFixed(0)}% of month',
            ),
            _buildStatItem(
              context,
              'Best Day',
              maxDurationDay != null
                  ? '${maxDurationDay.durPoint.dt.day}'
                  : 'None',
              Icons.emoji_events,
              subtitle: maxDurationDay != null
                  ? _formatDurationShort(maxDurationDay.durPoint.dur)
                  : 'No data',
            ),
            _buildStatItem(
              context,
              'Daily Average',
              _formatDurationShort(averageDuration),
              Icons.trending_up,
              subtitle: 'Active days only',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    String? subtitle,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.tertiary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours${hours == 1 ? ' hr ' : ' hrs '}$minutes min';
    } else {
      return '$minutes min';
    }
  }

  String _formatDurationShort(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
