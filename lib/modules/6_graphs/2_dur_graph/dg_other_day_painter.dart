import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/5_coordinates/c.dart';
import 'package:ten_thousands_hours/modules/6_graphs/1_primary_graph/pg_other_day_points_provider.dart';

class DgOtherDayView extends ConsumerWidget {
  const DgOtherDayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: CustomPaint(
        painter: PgOtherDayPainter(
          ref.watch(pgOtherDayPointsProvider).map((e) => e.last).toList(),
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
