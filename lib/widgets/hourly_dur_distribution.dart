import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_data/time_point/time_point.dart';
import 'package:ten_thousands_hours/root/root.dart';
import '../models/time_data/day_entry/day_model.dart';
import '../providers/other_providers/hourly_dur_provider.dart';

class HourlyDurDistribution extends ConsumerWidget {
  final double height;
  final double width;
  final bool showLabels;
  final bool showGrid;
  final bool showAxis;

  const HourlyDurDistribution({
    super.key,
    this.height = 200,
    this.width = double.infinity,
    this.showLabels = false,
    this.showGrid = true,
    this.showAxis = true,
  });

  Map<int, Duration> getHourlyData(
    List<DayEntry> days,
    List<int> excludeIndices, {
    bool debug = false,
  }) {
    final hourlyData = <int, Duration>{};
    int numberOfDays = 0;
    for (int i = 0; i < days.length; i++) {
      if (excludeIndices.contains(i)) {
        continue;
      }
      numberOfDays++;
      final day = days[i];
      pout(day.toString(), debug);
      pout(day.events.toString(), debug);
      // Duration cumulativeDur = Duration.zero;
      Duration previousDuration = Duration.zero;
      for (int j = 1; j <= 24; j++) {
        final targetTime = DateTime(
          day.dt.year,
          day.dt.month,
          day.dt.day,
          j,
        );
        final dur = TPService.calculateDuration(targetTime, day.events);
        if (dur == Duration.zero) {
          continue;
        }
        // final hourDur = dur - cumulativeDur;
        final hourDur = dur - previousDuration;
        previousDuration = dur;
        if (hourDur == Duration.zero) {
          continue;
        }
        // pout('at $j dur = $hourDur = $dur - $previousDuration ', debug);
        // cumulativeDur += dur;
        if (hourlyData.containsKey(j)) {
          hourlyData[j] = hourlyData[j]! + hourDur;
        } else {
          hourlyData[j] = hourDur;
        }
      }
    }
    for (int j = 1; j <= 24; j++) {
      if (hourlyData.containsKey(j)) {
        hourlyData[j] = hourlyData[j]! ~/ numberOfDays;
      } else {
        hourlyData[j] = Duration.zero;
      }
    }

    return hourlyData;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current time entry data
    // final timeData = ref.watch(timeDataPro);

    // Get today's data or the most recent day with activity
    // final DayEntry? activeDay = timeData.todayEntry.hasActivity == true
    //     ? timeData.todayEntry
    //     : timeData.days.where((d) => d.hasActivity).toList()
    //           ..sort((a, b) => b.dt.compareTo(a.dt))
    //           .firstOrNull;
    // final DayEntry? activeDay = ref.watch(timeDataPro).todayEntry;

    // if (activeDay == null) {
    //   return Center(
    //     child: Text(
    //       'No activity data available',
    //       style: TextStyle(
    //         fontFamily: 'Courier',
    //         fontSize: 14,
    //         color: Colors.grey[700],
    //       ),
    //     ),
    //   );
    // }

    // final timeData = ref.watch(timeDataPro).dayEntries;
    // Get hourly distribution data
    // // final hourlyData = ref.watch(hourlyDurProvider);
    // final days = ref.watch(daysForHourlyDurPro);
    final hourlyDis = ref.watch(hourlyDurProvider);
    final hourlyData = hourlyDis.avgDurSet;
    debugPrint('hourlyData at widget: $hourlyData');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and metadata
        const Text(
          'HOURLY DISTRIBUTION ANALYSIS',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Text(
        //   'Date: ${activeDay.dt.year}-${activeDay.dt.month.toString().padLeft(2, '0')}-${activeDay.dt.day.toString().padLeft(2, '0')}',
        //   style: const TextStyle(
        //     fontFamily: 'Courier',
        //     fontSize: 12,
        //   ),
        // ),
        const SizedBox(height: 16),

        // The actual graph
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: HourlyDistributionPainter(
              hourlyData: hourlyData,
              showGrid: showGrid,
              showAxis: showAxis,
            ),
          ),
        ),

        // Show labels if enabled
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Text(
                    '00   03   06   09   12   15   18   21   24',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 10,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Add statistics about the distribution
        const SizedBox(height: 16),
        // _buildStatistics(hourlyData, activeDay),
      ],
    );
  }

  Widget _buildStatistics(Map<int, Duration> hourlyData, DayEntry day) {
    // Calculate some interesting statistics
    final activeHours = hourlyData.length;
    final mostProductiveHour = day.mostProductiveHour;
    final totalMinutes = hourlyData.values
        .fold<int>(0, (sum, duration) => sum + duration.inMinutes);
    final averageMinutesPerActiveHour =
        activeHours > 0 ? totalMinutes / activeHours : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active hours: $activeHours/24',
          style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
        ),
        Text(
          'Most productive hour: ${mostProductiveHour != null ? "${mostProductiveHour.toString().padLeft(2, '0')}:00" : "N/A"}',
          style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
        ),
        Text(
          'Avg. minutes per active hour: ${averageMinutesPerActiveHour.toStringAsFixed(1)}',
          style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
        ),
        Text(
          'Distribution pattern: ${_analyzeDistributionPattern(hourlyData)}',
          style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
        ),
      ],
    );
  }

  String _analyzeDistributionPattern(Map<int, Duration> hourlyData) {
    if (hourlyData.isEmpty) return 'No pattern';

    // Check if most activity is in morning (4-12)
    final morningMinutes = _sumMinutesInRange(hourlyData, 4, 11);
    // Check if most activity is in afternoon (12-17)
    final afternoonMinutes = _sumMinutesInRange(hourlyData, 12, 17);
    // Check if most activity is in evening (18-23)
    final eveningMinutes = _sumMinutesInRange(hourlyData, 18, 23);
    // Check if most activity is in night (0-3)
    final nightMinutes = _sumMinutesInRange(hourlyData, 0, 3);

    final total =
        morningMinutes + afternoonMinutes + eveningMinutes + nightMinutes;

    if (total == 0) return 'No pattern';

    final parts = <String>[];
    if (morningMinutes / total > 0.5) parts.add('Morning-focused');
    if (afternoonMinutes / total > 0.5) parts.add('Afternoon-focused');
    if (eveningMinutes / total > 0.5) parts.add('Evening-focused');
    if (nightMinutes / total > 0.5) parts.add('Night-focused');

    if (parts.isEmpty) {
      // No single period dominates, so it's distributed
      return 'Distributed';
    }

    return parts.join(', ');
  }

  int _sumMinutesInRange(
      Map<int, Duration> hourlyData, int startHour, int endHour) {
    int sum = 0;
    for (int hour = startHour; hour <= endHour; hour++) {
      if (hourlyData.containsKey(hour)) {
        sum += hourlyData[hour]!.inMinutes;
      }
    }
    return sum;
  }
}

class HourlyDistributionPainter extends CustomPainter {
  final Map<int, Duration> hourlyData;
  final bool showGrid;
  final bool showAxis;

  HourlyDistributionPainter({
    required this.hourlyData,
    this.showGrid = true,
    this.showAxis = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Setup paints
    final axisPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    final barPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.fill;

    final barOutlinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Calculate max minutes for scaling
    final maxMinutes = hourlyData.values.fold<int>(
        30, // minimum of 30 minutes to maintain scale
        (max, duration) => duration.inMinutes > max ? duration.inMinutes : max);

    // Draw grid and axes if requested
    if (showAxis) {
      // Y axis
      canvas.drawLine(Offset(30, 0), Offset(30, size.height), axisPaint);

      // X axis
      canvas.drawLine(
          Offset(30, size.height), Offset(size.width, size.height), axisPaint);
    }

    if (showGrid) {
      // Draw horizontal grid lines
      for (int i = 1; i <= 4; i++) {
        final y = size.height * (1 - i / 4);
        canvas.drawLine(Offset(30, y), Offset(size.width, y), gridPaint);
      }

      // Draw vertical grid lines (every 3 hours)
      for (int hour = 3; hour < 24; hour += 3) {
        final x = 30 + (hour / 24) * (size.width - 30);
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
    }

    // Draw y-axis labels
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: 9,
      fontFamily: 'Courier',
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw minute markers
    for (int i = 0; i <= 4; i++) {
      final minutes = (maxMinutes * i / 4).round();
      final y = size.height * (1 - i / 4);

      textPainter.text = TextSpan(
        text: '${minutes}m',
        style: textStyle,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(5, y - textPainter.height / 2),
      );
    }

    // Calculate bar width
    final barWidth = (size.width - 30) / 24 - 2;

    // Draw bars for each hour
    for (int hour = 0; hour < 24; hour++) {
      final duration = hourlyData[hour] ?? Duration.zero;
      final minutes = duration.inMinutes.toDouble();

      // Skip empty hours for cleaner look
      if (minutes == 0) continue;

      // Calculate bar position and size
      final x = 30 + (hour / 24) * (size.width - 30) + 1;
      final barHeight = size.height * (minutes / maxMinutes);

      // Draw the bar
      final rect =
          Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight);

      // Fill the bar
      canvas.drawRect(rect, barPaint);

      // Draw bar outline
      canvas.drawRect(rect, barOutlinePaint);

      // Add cross-hatching for scientific paper look
      if (barHeight > 15) {
        final hatchPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 0.5;

        for (double y = size.height - barHeight + 3; y < size.height; y += 3) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x + barWidth, y),
            hatchPaint,
          );
        }
      }

      // Add minute value on top of taller bars
      if (barHeight > 20) {
        textPainter.text = TextSpan(
          text: '${minutes.toInt()}',
          style: textStyle.copyWith(fontSize: 8),
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            x + (barWidth - textPainter.width) / 2,
            size.height - barHeight - textPainter.height - 2,
          ),
        );
      }
    }

    // Highlight the most productive hour if it exists
    final mostProductiveHour =
        hourlyData.entries.fold<MapEntry<int, Duration>?>(
      null,
      (max, entry) => max == null || entry.value > max.value ? entry : max,
    );

    if (mostProductiveHour != null) {
      final hour = mostProductiveHour.key;
      final minutes = mostProductiveHour.value.inMinutes.toDouble();
      final x = 30 + (hour / 24) * (size.width - 30) + 1;
      final barHeight = size.height * (minutes / maxMinutes);

      final highlightRect =
          Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight);

      // Draw star above most productive hour
      final starPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final starCenter = Offset(
        x + barWidth / 2,
        size.height - barHeight - 10,
      );

      _drawStar(canvas, starCenter, 5, starPaint);
    }
  }

  // Helper method to draw a star
  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();

    for (int i = 0; i < 5; i++) {
      final angle = -pi / 2 + 2 * pi * i / 5;
      final point = Offset(
        center.dx + size * cos(angle),
        center.dy + size * sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
