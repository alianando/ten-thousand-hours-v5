import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/6_graphs/1_primary_graph/pg_other_day_points_provider.dart';

import '../../../5_coordinates/c.dart';

class PgOtherDaysView extends ConsumerWidget {
  const PgOtherDaysView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: CustomPaint(
        painter: PgOtherDayPainter(
          dayPoints: ref.watch(pgOtherDayPointsProvider),
        ),
      ),
    );
  }
}

class PgOtherDayPainter extends CustomPainter {
  final List<List<C>> dayPoints;
  const PgOtherDayPainter({required this.dayPoints});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke;
    Path p = Path();
    for (int i = 0; i < dayPoints.length; i++) {
      p.moveTo(0, size.height);
      for (int j = 0; j < dayPoints[i].length; j++) {
        p.lineTo(
          dayPoints[i][j].x * size.width,
          (1 - dayPoints[i][j].y) * size.height,
        );
      }
    }
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
