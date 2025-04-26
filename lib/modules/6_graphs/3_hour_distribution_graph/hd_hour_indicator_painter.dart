import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/6_graphs/3_hour_distribution_graph/hourly_distribution_services.dart';

class HdHourIndicatorPainter extends ConsumerWidget {
  const HdHourIndicatorPainter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: CustomPaint(
        painter: HdHourIndicatorPainterPainter(
            // dayPoints: ref.watch(todayPrimaryGraphPointsProvider),
            ),
      ),
    );
  }
}

class HdHourIndicatorPainterPainter extends CustomPainter {
  const HdHourIndicatorPainterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i <= 24; i++) {
      final double x = (i / 24) * size.width;
      canvas.drawLine(
        Offset(x, size.height + 4),
        Offset(x, size.height + 10),
        paint,
      );
      textPainter.text = TextSpan(
        text: i.toString(),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 9,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
