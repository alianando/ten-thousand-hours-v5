import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/3_days/relevent_days_provider.dart';
import 'package:ten_thousands_hours/modules/4_statistics/relevent_max_dur_provider.dart';
import 'package:ten_thousands_hours/modules/5_coordinates/c.dart';

class DgOtherDayView extends ConsumerWidget {
  const DgOtherDayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxDurInMiliSec = ref.watch(releventMaxDurProvider).inMilliseconds;
    final releventDays = ref.watch(releventDaysProvider);
    final DateTime now = DateTime.now();
    List<C> cordinates = releventDays.map((e) {
      final y = (e.lastRecordedDur.inMilliseconds / maxDurInMiliSec).toDouble();
      final z = (e.dt.difference(now).inDays.abs()).toDouble();
      return C(0, y, z);
    }).toList();
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: CustomPaint(
        painter: PgOtherDayPainter(
          cordinates,
          // ref.watch(pgOtherDayPointsProvider).map((e) => e.last).toList(),
        ),
      ),
    );
  }
}

class PgOtherDayPainter extends CustomPainter {
  final List<C> dayPoints;
  const PgOtherDayPainter(this.dayPoints);
  @override
  void paint(Canvas canvas, Size size) {
    double maxZ = 0;
    for (int i = 0; i < dayPoints.length; i++) {
      if (dayPoints[i].z > maxZ) {
        maxZ = dayPoints[i].z;
      }
    }
    maxZ = maxZ + 1;
    final rectWidth = size.width / (maxZ);
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    Path p = Path();
    for (int i = 0; i <= maxZ; i++) {
      final x = i * rectWidth;
      canvas.drawLine(
        Offset(x, size.height + 4),
        Offset(x, size.height + 10),
        paint,
      );
    }
    for (int i = 0; i < dayPoints.length; i++) {
      final c = dayPoints[i];
      // p.moveTo((c.z / maxZ) * size.width, size.height);
      // p.lineTo((c.z / maxZ) * size.width, (1 - c.y) * size.height);
      canvas.drawRect(
        Rect.fromLTWH(
          (c.z / maxZ) * size.width,
          (1 - c.y) * size.height,
          rectWidth,
          c.y * size.height,
        ),
        paint,
      );
    }
    canvas.drawPath(p, paint);
    // canvas.drawCircle(Offset.zero, 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
