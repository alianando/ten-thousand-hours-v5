import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/3_days/relevent_days_provider.dart';
import 'package:ten_thousands_hours/modules/5_coordinates/c.dart';
import 'package:ten_thousands_hours/modules/6_graphs/1_primary_graph/pg_other_day_points_provider.dart';

import '../../4_statistics/relevent_max_dur_provider.dart';
import '../../4_statistics/today_duration_provider.dart';
import '../1_primary_graph/pg_today_points_provider.dart';

final dgTotalDaysProvider = Provider<int>((ref) {
  final releventDays = ref.watch(releventDaysProvider);
  if (releventDays.isEmpty) return 0;
  final DateTime now = DateTime.now();
  final maxZ = releventDays.last.dt.difference(now).inDays.abs() + 1;
  return maxZ;
});

class DgTodayView extends ConsumerWidget {
  const DgTodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxZ = ref.watch(dgTotalDaysProvider).toDouble();
    final todayDur = ref.watch(todayDurProvider).inMilliseconds;
    final maxDurInMiliSec = ref.watch(releventMaxDurProvider).inMilliseconds;
    final y = (todayDur / maxDurInMiliSec).toDouble();
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: CustomPaint(
        painter: PgTodayPainter(
          y,
          maxZ.toInt(),
          // ref.watch(pgTodayPointsProvider).map((e) => e.last).toList(),
        ),
      ),
    );
  }
}

class PgTodayPainter extends CustomPainter {
  final double y;
  final int maxZ;
  const PgTodayPainter(this.y, this.maxZ);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    Path p = Path();
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        (1 - y) * size.height,
        // maxZ / size.width,
        // maxZ.toDouble(),
        10.0,
        y * size.height,
      ),
      paint,
    );
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
