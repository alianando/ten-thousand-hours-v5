import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/5_coordinates/c.dart';
import 'package:ten_thousands_hours/modules/6_graphs/1_primary_graph/pg_other_day_points_provider.dart';

import '../1_primary_graph/pg_today_points_provider.dart';

class DgTodayView extends ConsumerWidget {
  const DgTodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: CustomPaint(
        painter: PgTodayPainter(
          ref.watch(todayPrimaryGraphPointsProvider).last,
        ),
      ),
    );
  }
}

class PgTodayPainter extends CustomPainter {
  final C todayC;
  const PgTodayPainter(this.todayC);
  @override
  void paint(Canvas canvas, Size size) {
    // double maxZ = 0;
    // for (int i = 0; i < dayPoints.length; i++) {
    //   if (dayPoints[i].z > maxZ) {
    //     maxZ = dayPoints[i].z;
    //   }
    // }
    // maxZ = maxZ + 1;
    // final rectWidth = size.width / (maxZ);
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    Path p = Path();
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        (1 - todayC.y) * size.height,
        1,
        todayC.y * size.height,
      ),
      paint,
    );
    // for (int i = 0; i < dayPoints.length; i++) {
    //   final c = dayPoints[i];
    //   // p.moveTo((c.z / maxZ) * size.width, size.height);
    //   // p.lineTo((c.z / maxZ) * size.width, (1 - c.y) * size.height);
    //   canvas.drawRect(
    //     Rect.fromLTWH(
    //       (c.z / maxZ) * size.width,
    //       (1 - c.y) * size.height,
    //       rectWidth,
    //       c.y * size.height,
    //     ),
    //     paint,
    //   );
    // }
    canvas.drawPath(p, paint);
    // canvas.drawCircle(Offset.zero, 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
