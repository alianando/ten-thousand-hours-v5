import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_data/model/day_entry/day_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/day_entry/day_services.dart';
import '../../providers/record_provider.dart';
import '../../models/time_data/model/time_entry/time_entry.dart';
import '../../models/time_data/model/time_point/time_point.dart';
import 'dart:math' as math;

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeEntry = ref.watch(timeEntryProvider);
    final statistics = ref.read(timeEntryProvider.notifier).getStatistics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Analysis Report'),
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final timeData = ref.read(timeEntryProvider);
              final targetDay = timeData.days.last;
              debugPrint(targetDay.toString());
              debugPrint(targetDay.events.toString());
              final sansitized = DayModelService.sanitize(targetDay);
              debugPrint(sansitized.toString());
              debugPrint(sansitized.events.toString());
              // ref.read(timeEntryProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(timeEntry),
              const Divider(thickness: 2),
              _buildCurrentStatus(timeEntry),
              const Divider(),
              _buildSummaryStatistics(statistics),
              const Divider(),
              _buildDailyActivity(timeEntry),
              const Divider(),
              _buildTimeDistribution(timeEntry),
              const Divider(),
              _buildStreakAnalysis(statistics),
              //  _buildScientificGraphs(timeEntry),
              const Divider(),
              _buildSimpleGraph(timeEntry),
              const SizedBox(height: 20),
              _buildActionRow(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TimeEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TIME TRACKING ANALYSIS',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Report generated: ${DateTime.now().toString().substring(0, 19)}',
          style: const TextStyle(fontFamily: 'Courier'),
        ),
        Text(
          'Data last updated: ${entry.lastUpdate.toString().substring(0, 19)}',
          style: const TextStyle(fontFamily: 'Courier'),
        ),
        const SizedBox(height: 8),
        Text(
          'Total days recorded: ${entry.days.length}',
          style: const TextStyle(fontFamily: 'Courier'),
        ),
        Text(
          'Active days: ${entry.days.where((day) => day.hasActivity).length}',
          style: const TextStyle(fontFamily: 'Courier'),
        ),
      ],
    );
  }

  Widget _buildCurrentStatus(TimeEntry entry) {
    final isTracking = entry.isCurrentlyTracking;
    final today = entry.today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CURRENT STATUS',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Status: ${isTracking ? "ACTIVE" : "INACTIVE"}',
          style: TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            color: isTracking ? Colors.green[800] : Colors.red[800],
          ),
        ),
        if (today != null) ...[
          Text(
            'Today\'s duration: ${_formatDuration(today.totalDuration)}',
            style: const TextStyle(fontFamily: 'Courier'),
          ),
          Text(
            'Events today: ${today.events.length}',
            style: const TextStyle(fontFamily: 'Courier'),
          ),
          if (today.sessions.isNotEmpty)
            Text(
              'Sessions today: ${today.sessions.length}',
              style: const TextStyle(fontFamily: 'Courier'),
            ),
        ],
      ],
    );
  }

  Widget _buildSummaryStatistics(Map<String, dynamic> statistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUMMARY STATISTICS',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total time accumulated: ${_formatDuration(statistics['totalDuration'] as Duration)}',
          style: const TextStyle(fontFamily: 'Courier'),
        ),
        Text(
          'Average daily activity: ${_formatDuration(statistics['averageDaily'] as Duration)}',
          style: const TextStyle(fontFamily: 'Courier'),
        ),
        Text(
          'Current streak: ${statistics['currentStreak']} days',
          style: const TextStyle(fontFamily: 'Courier'),
        ),
        Text(
          'Active days count: ${statistics['activeDaysCount']}',
          style: const TextStyle(fontFamily: 'Courier'),
        ),
      ],
    );
  }

  Widget _buildDailyActivity(TimeEntry entry) {
    // Show the last 7 days activity
    final recentDays = List<DayEntry>.from(entry.days)
      ..sort((a, b) => b.dt.compareTo(a.dt));

    final lastSevenDays = recentDays.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT DAILY ACTIVITY',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (lastSevenDays.isEmpty)
          const Text(
            'No recent activity recorded.',
            style:
                TextStyle(fontFamily: 'Courier', fontStyle: FontStyle.italic),
          )
        else
          ...lastSevenDays.map((day) {
            final date =
                '${day.dt.year}-${day.dt.month.toString().padLeft(2, '0')}-${day.dt.day.toString().padLeft(2, '0')}';
            final duration = _formatDuration(day.totalDuration);
            final sessionsCount = day.sessions.length;

            return Text(
              '$date: $duration ($sessionsCount sessions)',
              style: const TextStyle(fontFamily: 'Courier'),
            );
          }),
      ],
    );
  }

  Widget _buildTimeDistribution(TimeEntry entry) {
    // Get hours distribution from the last active day
    final activeDays = entry.days.where((day) => day.hasActivity).toList()
      ..sort((a, b) => b.dt.compareTo(a.dt));

    if (activeDays.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOURLY DISTRIBUTION',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No activity data available.',
            style:
                TextStyle(fontFamily: 'Courier', fontStyle: FontStyle.italic),
          ),
        ],
      );
    }

    final lastActiveDay = activeDays.first;
    final hourlyData = lastActiveDay.hourlyDistribution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOURLY DISTRIBUTION (${_formatDate(lastActiveDay.dt)})',
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...hourlyData.entries
            .sorted((a, b) => a.key.compareTo(b.key))
            .map((entry) {
          final hour = entry.key;
          final duration = entry.value;
          final barLength = (duration.inMinutes / 15).clamp(1, 20).toInt();
          final bar = '|${'█' * barLength}';

          return Text(
            '${hour.toString().padLeft(2, '0')}:00 $bar ${_formatDuration(duration)}',
            style: const TextStyle(fontFamily: 'Courier'),
          );
        }),
        const SizedBox(height: 8),
        if (lastActiveDay.mostProductiveHour != null)
          Text(
            'Most productive hour: ${lastActiveDay.mostProductiveHour.toString().padLeft(2, '0')}:00',
            style: const TextStyle(
                fontFamily: 'Courier', fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildStreakAnalysis(Map<String, dynamic> statistics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STREAK ANALYSIS',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Current streak: ${statistics['currentStreak']} days',
          style: const TextStyle(fontFamily: 'Courier'),
        ),
        const Text(
          'Streak pattern: ',
          style: TextStyle(fontFamily: 'Courier'),
        ),
        Text(
          _generateStreakPattern(statistics['currentStreak'] as int),
          style: const TextStyle(fontFamily: 'Courier'),
        ),
      ],
    );
  }

  Widget _buildScientificGraphs(TimeEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(thickness: 1),
        const Text(
          'SCIENTIFIC TIME ANALYSIS',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildDurationTimeGraph(entry), // Add this new graph first
        const SizedBox(height: 20),
        _buildDailyProgressGraph(entry),
        const SizedBox(height: 20),
        _buildWeeklyPatternGraph(entry),
      ],
    );
  }

  Widget _buildDailyProgressGraph(TimeEntry entry) {
    // Get today's data or return placeholder if not available
    final today = entry.today;
    if (today == null || !today.hasActivity) {
      return const Text(
        'No activity data available for today.',
        style: TextStyle(fontFamily: 'Courier', fontStyle: FontStyle.italic),
      );
    }

    // Extract hourly data
    final hourlyData = today.hourlyDistribution;
    final hours = List.generate(24, (i) => i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DAILY ACTIVITY DISTRIBUTION (24-HOUR)',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Time labels
        Row(
          children: [
            const SizedBox(width: 50), // Align with graph
            Expanded(
              child: Text(
                '00   04   08   12   16   20   24',
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // ASCII Art Graph
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.grey[100],
          ),
          child: Row(
            children: [
              // Y-axis labels
              const SizedBox(
                width: 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('60m',
                        style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                    Text('45m',
                        style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                    Text('30m',
                        style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                    Text('15m',
                        style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                    Text('0m',
                        style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                  ],
                ),
              ),
              // Graph content
              Expanded(
                child: CustomPaint(
                  size: const Size(double.infinity, 120),
                  painter: DailyProgressPainter(
                    hourlyData: hourlyData,
                    hours: hours,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Stats about the graph
        Text(
          'Peak activity: ${today.mostProductiveHour != null ? "${today.mostProductiveHour.toString().padLeft(2, '0')}:00" : "N/A"}',
          style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
        ),
        Text(
          'Active hours: ${hourlyData.keys.length}/24',
          style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
        ),
        Text(
          'Mean activity per active hour: ${hourlyData.isEmpty ? "0m" : _formatDuration(Duration(microseconds: hourlyData.values.fold(0, (sum, duration) => sum + duration.inMicroseconds) ~/ hourlyData.values.length))}',
          style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildWeeklyPatternGraph(TimeEntry entry) {
    // Get the last 7 days of data
    final recentDays = List<DayEntry>.from(entry.days)
      ..sort((a, b) => a.dt.compareTo(b.dt))
      ..reversed;

    final last7Days = recentDays.take(7).toList();

    if (last7Days.isEmpty) {
      return const Text(
        'Insufficient data for weekly analysis.',
        style: TextStyle(fontFamily: 'Courier', fontStyle: FontStyle.italic),
      );
    }

    // Extract daily totals and find maximum for scaling
    final dailyTotals =
        last7Days.map((day) => day.totalDuration.inMinutes).toList();
    final maxMinutes =
        dailyTotals.isEmpty ? 60 : dailyTotals.reduce((a, b) => a > b ? a : b);

    // Create day labels
    final dayLabels = last7Days
        .map((day) =>
            '${day.dt.day.toString().padLeft(2, '0')}/${day.dt.month.toString().padLeft(2, '0')}')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WEEKLY ACTIVITY PATTERNS',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // ASCII Art Bar Graph
        Container(
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            color: Colors.grey[100],
          ),
          child: Row(
            children: [
              // Y-axis labels
              SizedBox(
                width: 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${maxMinutes}m',
                        style: const TextStyle(
                            fontFamily: 'Courier', fontSize: 10)),
                    Text('${(maxMinutes * 0.75).round()}m',
                        style: const TextStyle(
                            fontFamily: 'Courier', fontSize: 10)),
                    Text('${(maxMinutes * 0.5).round()}m',
                        style: const TextStyle(
                            fontFamily: 'Courier', fontSize: 10)),
                    Text('${(maxMinutes * 0.25).round()}m',
                        style: const TextStyle(
                            fontFamily: 'Courier', fontSize: 10)),
                    const Text('0m',
                        style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                  ],
                ),
              ),
              // Graph content
              Expanded(
                child: CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: WeeklyPatternPainter(
                    dailyTotals: dailyTotals,
                    dayLabels: dayLabels,
                    maxMinutes: maxMinutes.toDouble(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Correlation analysis
        Text(
          'Coefficient of variation: ${_calculateCoV(dailyTotals)}%',
          style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
        ),
        Text(
          'Weekly pattern: ${_determineWeeklyPattern(dailyTotals)}',
          style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSimpleGraph(TimeEntry entry) {
    // Create a simple ASCII/text based graph of the last 14 days
    final recentDays = List<DayEntry>.from(entry.days)
      ..sort((a, b) => a.dt.compareTo(b.dt));

    final last14Days = recentDays.reversed.take(14).toList();

    if (last14Days.isEmpty) {
      return const SizedBox();
    }

    // Find the maximum duration for scaling
    final maxDuration =
        last14Days.map((day) => day.totalDuration.inMinutes).reduce(math.max);

    if (maxDuration == 0) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'ACTIVITY GRAPH (LAST 14 DAYS)',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...last14Days.map((day) {
          final date =
              '${day.dt.month.toString().padLeft(2, '0')}-${day.dt.day.toString().padLeft(2, '0')}';
          final mins = day.totalDuration.inMinutes;
          final scaled = (mins / maxDuration * 30).round();
          final bar = scaled > 0 ? '█' * scaled : '';

          return Text(
            '$date | $bar ${mins}m',
            style: const TextStyle(fontFamily: 'Courier'),
          );
        }),
        const SizedBox(height: 8),
        Text(
          'Max: ${maxDuration}m',
          style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildActionRow(WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            ref.read(timeEntryProvider.notifier).addActiveEvent(DateTime.now());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            foregroundColor: Colors.black,
          ),
          child: Text(ref.read(timeEntryProvider).isCurrentlyTracking
              ? 'PAUSE TRACKING'
              : 'START TRACKING'),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _generateStreakPattern(int streakCount) {
    if (streakCount <= 0) return '[ ]';

    final buffer = StringBuffer('[');
    for (var i = 0; i < streakCount; i++) {
      buffer.write('■');
    }
    buffer.write(']');
    return buffer.toString();
  }
}

extension ListSortExtension<E> on Iterable<E> {
  List<E> sorted(int Function(E a, E b) compare) {
    final list = toList();
    list.sort(compare);
    return list;
  }
}

class DailyProgressPainter extends CustomPainter {
  final Map<int, Duration> hourlyData;
  final List<int> hours;

  DailyProgressPainter({required this.hourlyData, required this.hours});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Draw grid lines
    for (int i = 1; i < 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()..color = Colors.grey[300]!,
      );
    }

    // Draw X axis
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      paint,
    );

    // Draw Y axis
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, size.height),
      paint,
    );

    // Draw hour markers
    for (int hour in hours) {
      final x = size.width * (hour / 24);
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height - 5),
        paint,
      );
    }

    // Draw data points and connecting lines
    final points = <Offset>[];
    const maxMinutes = 60.0; // Assuming 60 minutes max per hour for scaling

    for (int hour in hours) {
      final minutes = hourlyData[hour]?.inMinutes.toDouble() ?? 0;
      final x = size.width * (hour / 24);
      final y = size.height * (1 - (minutes / maxMinutes)).clamp(0.0, 1.0);

      points.add(Offset(x, y));

      // Draw dot for data point
      if (hourlyData.containsKey(hour)) {
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
    }

    // Draw connecting lines between points
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      // Only connect points that have data
      if (hourlyData.containsKey(hours[i - 1]) ||
          hourlyData.containsKey(hours[i])) {
        // If either point has data, connect them
        final prev = points[i - 1];
        final curr = points[i];

        // Create a curved line for smoother appearance
        path.cubicTo(
          prev.dx + (curr.dx - prev.dx) / 2,
          prev.dy,
          prev.dx + (curr.dx - prev.dx) / 2,
          curr.dy,
          curr.dx,
          curr.dy,
        );
      } else {
        // Move without drawing a line
        path.moveTo(points[i].dx, points[i].dy);
      }
    }

    // Draw the path
    canvas.drawPath(path, paint);

    // Fill area under the graph with semi-transparent fill
    final fillPath = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      if (hourlyData.containsKey(hours[i - 1]) ||
          hourlyData.containsKey(hours[i])) {
        final prev = points[i - 1];
        final curr = points[i];
        fillPath.cubicTo(
          prev.dx + (curr.dx - prev.dx) / 2,
          prev.dy,
          prev.dx + (curr.dx - prev.dx) / 2,
          curr.dy,
          curr.dx,
          curr.dy,
        );
      } else {
        fillPath.moveTo(points[i].dx, points[i].dy);
      }
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // Fill with semi-transparent gray
    canvas.drawPath(
        fillPath, fillPaint..color = Colors.grey[500]!.withOpacity(0.3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WeeklyPatternPainter extends CustomPainter {
  final List<int> dailyTotals;
  final List<String> dayLabels;
  final double maxMinutes;

  WeeklyPatternPainter({
    required this.dailyTotals,
    required this.dayLabels,
    required this.maxMinutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final barPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.fill;

    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw grid lines
    for (int i = 1; i < 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()..color = Colors.grey[300]!,
      );
    }

    // Draw axes
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      paint,
    );

    // Calculate bar width and spacing
    final barCount = dailyTotals.length;
    final totalBarWidth = size.width * 0.7; // Leave space for margins
    final barWidth = totalBarWidth / barCount;
    final spacing = size.width * 0.3 / (barCount + 1);

    // Draw bars and labels
    for (int i = 0; i < dailyTotals.length; i++) {
      final minutes = dailyTotals[i].toDouble();
      final normalizedHeight = (minutes / maxMinutes).clamp(0.0, 1.0);
      final barHeight = size.height * normalizedHeight;

      final left = spacing + i * (barWidth + spacing);
      final top = size.height - barHeight;
      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);

      // Draw bar
      canvas.drawRect(rect, barPaint);
      canvas.drawRect(rect, paint); // Draw outline

      // Draw cross-hatching for scientific paper look
      if (barHeight > 10) {
        final hatchPaint = Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..strokeWidth = 1;

        for (double y = top + 5; y < size.height; y += 5) {
          canvas.drawLine(
            Offset(left, y),
            Offset(left + barWidth, y),
            hatchPaint,
          );
        }
      }

      // Draw day label
      textPaint.text = TextSpan(
        text: dayLabels[i],
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontFamily: 'Courier',
        ),
      );
      textPaint.layout();
      textPaint.paint(canvas,
          Offset(left + (barWidth - textPaint.width) / 2, size.height + 5));

      // Draw minute value on top of bar if tall enough
      if (barHeight > 20) {
        textPaint.text = TextSpan(
          text: '${dailyTotals[i]}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 9,
            fontFamily: 'Courier',
          ),
        );
        textPaint.layout();
        textPaint.paint(
            canvas, Offset(left + (barWidth - textPaint.width) / 2, top - 12));
      }
    }

    // Draw trend line
    if (dailyTotals.length > 1) {
      final points = <Offset>[];

      for (int i = 0; i < dailyTotals.length; i++) {
        final minutes = dailyTotals[i].toDouble();
        final normalizedHeight = (minutes / maxMinutes).clamp(0.0, 1.0);
        final y = size.height * (1 - normalizedHeight);
        final x = spacing + i * (barWidth + spacing) + barWidth / 2;

        points.add(Offset(x, y));
      }

      // Draw dashed trend line
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      final dashPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      // Draw dashed line
      for (int i = 1; i < points.length; i++) {
        final p1 = points[i - 1];
        final p2 = points[i];

        // Simple dash pattern
        final dx = p2.dx - p1.dx;
        final dy = p2.dy - p1.dy;
        final dist = math.sqrt(dx * dx + dy * dy);
        const dashLength = 3.0;
        final dashCount = (dist / (2 * dashLength)).floor();

        for (int j = 0; j < dashCount; j++) {
          final start = j * 2 * dashLength / dist;
          final end = start + dashLength / dist;

          canvas.drawLine(
            Offset(p1.dx + dx * start, p1.dy + dy * start),
            Offset(p1.dx + dx * end, p1.dy + dy * end),
            dashPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Helper methods for analysis
String _calculateCoV(List<int> values) {
  if (values.isEmpty) return '0.0';

  final mean = values.reduce((a, b) => a + b) / values.length;
  if (mean == 0) return '0.0';

  final squaredDiffs = values.map((v) => math.pow(v - mean, 2));
  final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;
  final stdDev = math.sqrt(variance);

  final cov = (stdDev / mean) * 100;
  return cov.toStringAsFixed(1);
}

String _determineWeeklyPattern(List<int> dailyTotals) {
  if (dailyTotals.length < 3) return 'Insufficient data';

  // Simple trend analysis
  int increases = 0;
  int decreases = 0;

  for (int i = 1; i < dailyTotals.length; i++) {
    if (dailyTotals[i] > dailyTotals[i - 1]) {
      increases++;
    } else if (dailyTotals[i] < dailyTotals[i - 1]) {
      decreases++;
    }
  }

  if (increases > decreases) {
    return 'Upward trend';
  } else if (decreases > increases) {
    return 'Downward trend';
  } else {
    return 'Steady pattern';
  }
}

Widget _buildDurationTimeGraph(TimeEntry entry) {
  // Get today and yesterday's data
  final today = entry.today;
  final recentDays = List<DayEntry>.from(entry.days)
    ..sort((a, b) => b.dt.compareTo(a.dt));

  final yesterday = recentDays.length > 1 ? recentDays[1] : null;

  if (today == null || !today.hasActivity) {
    return const Text(
      'No activity data available for duration graph.',
      style: TextStyle(fontFamily: 'Courier', fontStyle: FontStyle.italic),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'DURATION VS TIME ANALYSIS',
        style: TextStyle(
          fontFamily: 'Courier',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      // Graph title and metadata
      Row(
        children: [
          Expanded(
            child: Text(
              'Continuous Duration | ${HomePage._formatDate(DateTime.now())}',
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'TOTAL: ${_formatDuration(today.totalDuration)}',
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      // X-axis time labels
      Row(
        children: [
          const SizedBox(width: 50), // Align with graph
          Expanded(
            child: Text(
              '06:00   09:00   12:00   15:00   18:00   21:00',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      // Graph container
      Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          color: Colors.grey[100],
        ),
        child: Row(
          children: [
            // Y-axis labels (duration in hours)
            const SizedBox(
              width: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('8h',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                  Text('6h',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                  Text('4h',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                  Text('2h',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                  Text('0h',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10)),
                ],
              ),
            ),
            // Graph content
            Expanded(
              child: CustomPaint(
                size: const Size(double.infinity, 180),
                painter: DurationTimeGraphPainter(
                  today: today,
                  yesterday: yesterday,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      // Legend and statistics
      Row(
        children: [
          Container(
            width: 12,
            height: 4,
            color: Colors.black,
          ),
          const SizedBox(width: 4),
          const Text(
            'TODAY',
            style: TextStyle(fontFamily: 'Courier', fontSize: 10),
          ),
          const SizedBox(width: 16),
          Container(
            width: 12,
            height: 4,
            color: Colors.grey,
          ),
          const SizedBox(width: 4),
          const Text(
            'YESTERDAY',
            style: TextStyle(fontFamily: 'Courier', fontSize: 10),
          ),
          const SizedBox(width: 16),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'TIME POINTS',
            style: TextStyle(fontFamily: 'Courier', fontSize: 10),
          ),
        ],
      ),
      const SizedBox(height: 8),
      // Key statistics about the duration profile
      _buildDurationStatistics(today, yesterday),
    ],
  );
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes}m ${seconds}s';
  } else if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  } else {
    return '${seconds}s';
  }
}

Widget _buildDurationStatistics(DayEntry today, DayEntry? yesterday) {
  // Calculate statistics about today's activity
  final currentRate = today.totalDuration.inMinutes /
      ((DateTime.now().hour - 6) * 60 + DateTime.now().minute);

  final projectedTotal = currentRate > 0
      ? Duration(minutes: (currentRate * 15 * 60).round())
      : Duration.zero;

  final sessions = today.sessions;
  final avgSessionLength = sessions.isNotEmpty
      ? Duration(
          microseconds:
              sessions.fold(0, (sum, s) => sum + s.$3.inMicroseconds) ~/
                  sessions.length)
      : Duration.zero;

  final todayEvents = today.events.length;

  final yesterdayComparison = yesterday != null
      ? (today.totalDuration.inMinutes /
                  math.max(1, yesterday.totalDuration.inMinutes) *
                  100 -
              100)
          .round()
      : 0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Avg accumulation rate: ${(currentRate * 60).toStringAsFixed(1)} min/hr',
        style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
      ),
      Text(
        'Projected daily total: ${_formatDuration(projectedTotal)}',
        style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
      ),
      Text(
        'Avg session length: ${_formatDuration(avgSessionLength)} (${sessions.length} sessions)',
        style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
      ),
      Text(
        'Time point events: $todayEvents',
        style: const TextStyle(fontFamily: 'Courier', fontSize: 11),
      ),
      if (yesterday != null)
        Text(
          'vs yesterday: ${yesterdayComparison >= 0 ? '+$yesterdayComparison%' : '$yesterdayComparison%'}',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 11,
            color:
                yesterdayComparison >= 0 ? Colors.green[700] : Colors.red[700],
          ),
        ),
    ],
  );
}

class DurationTimeGraphPainter extends CustomPainter {
  final DayEntry today;
  final DayEntry? yesterday;

  DurationTimeGraphPainter({required this.today, this.yesterday});

  @override
  void paint(Canvas canvas, Size size) {
    // Setup paints
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    final todayPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final yesterdayPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final annotationPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw grid
    // Vertical grid lines (every 3 hours from 6:00)
    for (int i = 0; i <= 5; i++) {
      final x = size.width * (i / 5);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Horizontal grid lines (every 2 hours)
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (1 - i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw yesterday's duration curve if available
    if (yesterday != null && yesterday!.hasActivity) {
      final yesterdayPoints =
          _calculateDurationPoints(yesterday!, size, maxHours: 8);

      if (yesterdayPoints.isNotEmpty) {
        final path = Path();
        path.moveTo(yesterdayPoints.first.dx, yesterdayPoints.first.dy);

        for (int i = 1; i < yesterdayPoints.length; i++) {
          path.lineTo(yesterdayPoints[i].dx, yesterdayPoints[i].dy);
        }

        canvas.drawPath(path, yesterdayPaint);
      }
    }

    // Draw today's duration curve
    final todayPoints =
        _calculateDurationPoints(today, size, maxHours: 8, extendToNow: true);

    if (todayPoints.isNotEmpty) {
      final path = Path();
      path.moveTo(todayPoints.first.dx, todayPoints.first.dy);

      for (int i = 1; i < todayPoints.length; i++) {
        path.lineTo(todayPoints[i].dx, todayPoints[i].dy);
      }

      canvas.drawPath(path, todayPaint);

      // Draw dots at each time point
      for (int i = 0; i < todayPoints.length; i++) {
        canvas.drawCircle(todayPoints[i], 3, pointPaint);
      }

      // Add annotations for significant time points
      if (todayPoints.length > 1) {
        // Mark the start point
        _drawTimeAnnotation(
            canvas,
            todayPoints.first,
            "${today.events.first.dt.hour}:${today.events.first.dt.minute.toString().padLeft(2, '0')}",
            annotationPaint);

        // Mark the current/last point
        _drawTimeAnnotation(
            canvas,
            todayPoints.last,
            "${today.events.last.dt.hour}:${today.events.last.dt.minute.toString().padLeft(2, '0')}",
            annotationPaint);

        // Find and mark the steepest segment (highest productivity)
        int steepestIndex = 0;
        double maxSlope = 0;

        for (int i = 1; i < todayPoints.length; i++) {
          if (todayPoints[i].dx > todayPoints[i - 1].dx) {
            final slope = (todayPoints[i - 1].dy - todayPoints[i].dy) /
                (todayPoints[i].dx - todayPoints[i - 1].dx);
            if (slope > maxSlope) {
              maxSlope = slope;
              steepestIndex = i;
            }
          }
        }

        if (steepestIndex > 0) {
          final midpoint = Offset(
            (todayPoints[steepestIndex - 1].dx +
                    todayPoints[steepestIndex].dx) /
                2,
            (todayPoints[steepestIndex - 1].dy +
                    todayPoints[steepestIndex].dy) /
                2,
          );

          canvas.drawCircle(
              midpoint, 5, pointPaint..style = PaintingStyle.stroke);

          final productiveHour = today.events[steepestIndex].dt.hour;
          _drawTimeAnnotation(
              canvas, midpoint, "Peak: ${productiveHour}h", annotationPaint,
              above: true);
        }
      }
    }

    // Mark current time with vertical line
    final now = DateTime.now();
    final currentX = _timeToX(now.hour, now.minute, size);

    if (currentX >= 0 && currentX <= size.width) {
      final dashPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1;

      // Draw dashed line for current time
      for (double y = 0; y < size.height; y += 8) {
        canvas.drawLine(
            Offset(currentX, y), Offset(currentX, y + 4), dashPaint);
      }

      // Draw "NOW" label
      final textPainter = TextPainter(
          text: const TextSpan(
            text: "NOW",
            style: TextStyle(
              color: Colors.black,
              fontSize: 9,
              fontFamily: 'Courier',
            ),
          ),
          textDirection: TextDirection.ltr);

      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(currentX - textPainter.width / 2,
              size.height - textPainter.height));
    }

    // Draw "GOAL" line if appropriate
    final goalPaint = Paint()
      ..color = Colors.green[700]!
      ..strokeWidth = 1;

    // Example: Draw a goal line at 4 hours
    final goalY = size.height * (1 - 4 / 8);

    // Draw horizontal dashed line
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, goalY), Offset(x + 4, goalY), goalPaint);
    }

    // Draw "GOAL" label
    final goalTextPainter = TextPainter(
        text: TextSpan(
          text: "GOAL: 4h",
          style: TextStyle(
            color: Colors.green[700],
            fontSize: 9,
            fontFamily: 'Courier',
          ),
        ),
        textDirection: TextDirection.ltr);

    goalTextPainter.layout();
    goalTextPainter.paint(
        canvas, Offset(4, goalY - goalTextPainter.height - 2));
  }

  // Helper to draw time annotations
  void _drawTimeAnnotation(
      Canvas canvas, Offset point, String text, Paint paint,
      {bool above = false}) {
    final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 9,
            fontFamily: 'Courier',
          ),
        ),
        textDirection: TextDirection.ltr);

    textPainter.layout();

    final yOffset = above ? -textPainter.height - 8 : 8;
    textPainter.paint(
        canvas, Offset(point.dx - textPainter.width / 2, point.dy + yOffset));
  }

  double _timeToX(int hour, int minute, Size size) {
    // Convert time to x coordinate (6:00 - 21:00 range)
    final totalMinutes = hour * 60 + minute;
    const startMinutes = 6 * 60; // 6:00 AM
    const endMinutes = 21 * 60; // 9:00 PM

    if (totalMinutes < startMinutes) return -10; // Before graph start
    if (totalMinutes > endMinutes) return size.width + 10; // After graph end

    return size.width *
        (totalMinutes - startMinutes) /
        (endMinutes - startMinutes);
  }

  // Convert duration to y coordinate
  double _durationToY(Duration duration, Size size, double maxHours) {
    final hours = duration.inMinutes / 60;
    return size.height * (1 - (hours / maxHours).clamp(0.0, 1.0));
  }

  // Calculate duration points for graphing
  List<Offset> _calculateDurationPoints(DayEntry day, Size size,
      {required double maxHours, bool extendToNow = false}) {
    final points = <Offset>[];
    Duration currentDuration = Duration.zero;
    TimePointTyp lastType = TimePointTyp.pause;
    DateTime? lastTime;

    // Process all events to build duration curve
    for (final event in day.events) {
      // Skip points outside our time range (6:00-21:00)
      if (event.dt.hour < 6) continue;
      if (event.dt.hour > 21) break;

      // Add starting point at 6 AM if needed
      if (points.isEmpty && event.dt.hour > 6) {
        final x = _timeToX(6, 0, size);
        final y = _durationToY(Duration.zero, size, maxHours);
        points.add(Offset(x, y));
      }

      // Calculate point
      final x = _timeToX(event.dt.hour, event.dt.minute, size);

      // Calculate latest duration
      if (lastTime != null && lastType == TimePointTyp.resume) {
        currentDuration += event.dt.difference(lastTime);
      }

      // Store the point
      final y = _durationToY(currentDuration, size, maxHours);
      points.add(Offset(x, y));

      lastTime = event.dt;
      lastType = event.typ;
    }

    // If we're still active, extend to now
    if (extendToNow && lastType == TimePointTyp.resume && lastTime != null) {
      final now = DateTime.now();
      if (now.hour >= 6 && now.hour <= 21) {
        currentDuration += now.difference(lastTime);
        final x = _timeToX(now.hour, now.minute, size);
        final y = _durationToY(currentDuration, size, maxHours);
        points.add(Offset(x, y));
      }
    }

    return points;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
