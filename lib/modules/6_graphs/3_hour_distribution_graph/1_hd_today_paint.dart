// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/6_graphs/3_hour_distribution_graph/0_hd_today_coor_pro.dart';

class HDTodayPaint extends ConsumerWidget {
  const HDTodayPaint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coo = ref.watch(hdTodayCoordinateProvider);
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: CustomPaint(
        painter: HDTodayPaintPainter(coo),
        // child: Text(coo.toString()),
      ),
    );
  }
}

class HDTodayPaintPainter extends CustomPainter {
  final Map<int, double> points;
  const HDTodayPaintPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;
    points.forEach((key, value) {
      final x = (key / 24) * size.width;
      final y = size.height - (value * size.height);
      // canvas.drawCircle(Offset(x, y), 4.0, paint);
      canvas.drawLine(Offset(x, size.height), Offset(x, y), paint);
    });
    // Path path = Path();
    // path.moveTo(0, size.height);
    // for (int i = 0; i < points.length; i++) {
    //   final x = (i / points.length) * size.width;
    //   final y = size.height - (points[i] ?? 0) * size.height;
    //   path.lineTo(x, y);
    // }
    // path.lineTo(size.width, size.height);
    // path.close();

    // canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
