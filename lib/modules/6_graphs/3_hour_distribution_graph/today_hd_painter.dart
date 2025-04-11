import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/6_graphs/3_hour_distribution_graph/day_hour_duration_provider.dart';
import 'package:ten_thousands_hours/modules/6_graphs/3_hour_distribution_graph/hourly_distribution_services.dart';

import 'today_hd_provider.dart';

class TodayHdPainter extends ConsumerWidget {
  const TodayHdPainter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dayHourDurationProvider);
    Map<double, double> normalized = {};
    data.forEach((key, value) {
      normalized[key / 24] =
          value.inMilliseconds / const Duration(hours: 1).inMilliseconds;
    });
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: CustomPaint(
        painter: TodayHdPainterPainter(
          normalized,
          // ref.watch(dayHourDurationProvider),
        ),
      ),
    );
  }
}

class TodayHdPainterPainter extends CustomPainter {
  final Map<double, double> values;
  const TodayHdPainterPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // Path p = Path();
    // final hourVal = HDServices.hourlyXval;

    for (var val in values.entries) {
      final double x = val.key;
      final double y = val.value;
      canvas.drawLine(
        Offset(x * size.width, size.height),
        Offset(x * size.width, (1 - y) * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
