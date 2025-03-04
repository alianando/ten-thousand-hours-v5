import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ten_thousands_hours/models/time_data/model/day_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/time_point.dart';
import 'package:ten_thousands_hours/providers/time_data_provider.dart';

final weekDataProvider = Provider((ref) {
  final timeData = ref.watch(timeDataProvider);
  final weekIndices = timeData.indices.weekIndices;
  final weekDays = weekIndices.map((index) => timeData.days[index]).toList();

  // Calculate total duration for the week
  final totalDuration = weekDays.fold<Duration>(
    Duration.zero,
    (total, day) => total + day.durPoint.dur,
  );

  return {
    'weekDays': weekDays,
    'totalDuration': totalDuration,
  };
});

class WeekData extends ConsumerWidget {
  const WeekData({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekData = ref.watch(weekDataProvider);
    final weekDays = weekData['weekDays'] as List<DayModel>;
    final totalDuration = weekData['totalDuration'] as Duration;

    // Find the day with maximum duration for relative scaling
    final maxDuration = weekDays.isEmpty
        ? Duration.zero
        : weekDays
            .map((day) => day.durPoint.dur)
            .reduce((value, element) => value > element ? value : element);

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, totalDuration),
            const SizedBox(height: 16),
            _buildDayList(context, weekDays, maxDuration),
            const Divider(height: 32),
            _buildWeekSummary(context, weekDays, totalDuration),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Duration totalDuration) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final dateFormat = DateFormat('MMM d');
    final weekRange =
        '${dateFormat.format(startOfWeek)} - ${dateFormat.format(endOfWeek)}';

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Week',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              weekRange,
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
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time_filled,
                size: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(totalDuration),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayList(
      BuildContext context, List<DayModel> weekDays, Duration maxDuration) {
    final today = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: List.generate(7, (index) {
        final dayOfWeek = index + 1; // 1 = Monday, 7 = Sunday
        final isToday = today.weekday == dayOfWeek;
        final dayName = dayNames[index];

        // Find the corresponding day data
        final dayData = weekDays.firstWhere(
          (day) => _getDayOfWeek(day.lastUpdate) == dayOfWeek,
          orElse: () => DayModel(
            // Default empty day
            lastUpdate:
                today.subtract(Duration(days: today.weekday - dayOfWeek)),
            durPoint: TimePoint(
              dt: DateTime.now(),
              dur: Duration.zero,
              typ: TimePointTyp.pause,
            ),
            events: [],
            coordinates: [],
          ),
        );

        return _buildDayRow(
          context,
          dayName,
          dayData.durPoint.dur,
          maxDuration,
          isToday,
          dayOfWeek <= today.weekday, // Is past or today
        );
      }),
    );
  }

  Widget _buildDayRow(
    BuildContext context,
    String dayName,
    Duration duration,
    Duration maxDuration,
    bool isToday,
    bool isPastOrToday,
  ) {
    // Calculate progress percentage (avoid division by zero)
    final double percentage = maxDuration.inSeconds > 0
        ? duration.inSeconds / maxDuration.inSeconds
        : 0.0;

    // Color strategy
    final baseColor = Theme.of(context).colorScheme.primary;

    Color getBarColor() {
      if (!isPastOrToday) return Colors.grey.shade300; // Future day
      if (duration.inMinutes == 0) return Colors.grey.shade300; // No activity
      if (isToday) return baseColor; // Today
      return baseColor.withOpacity(0.7); // Past day with activity
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              dayName,
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        width: constraints.maxWidth * percentage,
                        decoration: BoxDecoration(
                          color: getBarColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    },
                  ),
                  if (duration.inSeconds > 0)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            _formatDurationCompact(duration),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: percentage > 0.7
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSummary(
    BuildContext context,
    List<DayModel> weekDays,
    Duration totalDuration,
  ) {
    // Calculate averages and trends
    final daysWithActivity =
        weekDays.where((day) => day.durPoint.dur.inSeconds > 0).length;
    final averageDuration = daysWithActivity > 0
        ? Duration(seconds: totalDuration.inSeconds ~/ daysWithActivity)
        : Duration.zero;

    // Get the most productive day
    DayModel? mostProductiveDay;
    if (weekDays.isNotEmpty) {
      mostProductiveDay = weekDays.reduce(
          (curr, next) => curr.durPoint.dur > next.durPoint.dur ? curr : next);
    }

    final dateFormat = DateFormat('EEEE');
    final mostProductiveDayName = mostProductiveDay != null &&
            mostProductiveDay.durPoint.dur.inSeconds > 0
        ? dateFormat.format(mostProductiveDay.lastUpdate)
        : 'None yet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Insights',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInsightItem(
              context,
              'Active Days',
              '$daysWithActivity/7',
              Icons.calendar_today,
            ),
            _buildInsightItem(
              context,
              'Daily Average',
              _formatDurationCompact(averageDuration),
              Icons.access_time,
            ),
            _buildInsightItem(
              context,
              'Best Day',
              mostProductiveDayName,
              Icons.emoji_events,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightItem(
      BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ),
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
                ),
          ),
        ],
      ),
    );
  }

  int _getDayOfWeek(DateTime date) {
    // Returns 1 for Monday, 7 for Sunday
    return date.weekday;
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

  String _formatDurationCompact(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '0m';
    }
  }
}
