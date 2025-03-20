import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../5_coordinates/c.dart';
import '../pg_today_points_provider.dart';

class PgTodayView extends ConsumerWidget {
  const PgTodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: CustomPaint(
        painter: PgTodayPainter(
          dayPoints: ref.watch(todayPrimaryGraphPointsProvider),
        ),
      ),
    );
  }
}

class PgTodayPainter extends CustomPainter {
  final List<C> dayPoints;
  const PgTodayPainter({required this.dayPoints});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    Path p = Path();
    // canvas.rotate(0.05);
    p.moveTo(0, size.height);

    for (int j = 0; j < dayPoints.length; j++) {
      p.lineTo(
        dayPoints[j].x * size.width,
        (1 - dayPoints[j].y) * size.height,
      );
    }
    canvas.drawPath(p, paint);
    canvas.drawCircle(
      Offset(dayPoints.last.x * size.width, dayPoints.last.y * size.height),
      5,
      paint,
    );
    canvas.drawLine(
      Offset(
        dayPoints.last.x * size.width,
        dayPoints.last.y * size.height,
      ),
      Offset(
        dayPoints.last.x * size.width,
        (1 - dayPoints.last.y) * size.height,
      ),
      paint,
    );
    canvas.rotate(90);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
