// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/3.2_data_providers.dart/current_status_provider.dart';
import 'package:ten_thousands_hours/providers/ticker_provider.dart';

import '../../0_data_model/time_stamp.dart';

class HDLebelsPainter extends ConsumerWidget {
  const HDLebelsPainter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final lastTP = ref.watch(latestTimeStampProvider);
    final nowHour = ref.watch(ticPro).hour;
    final active = ref.watch(latestTimeStampProvider).type == TPType.resume;
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: CustomPaint(
        painter: HDLebelsPainterPainter(active, nowHour),
      ),
    );
  }
}

class HDLebelsPainterPainter extends CustomPainter {
  final bool active;
  final int currentHour;
  const HDLebelsPainterPainter(this.active, this.currentHour);

  @override
  void paint(Canvas canvas, Size size) {
    final double x = (currentHour / 24) * size.width;
    Paint paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // Path p = Path();
    // final hourVal = HDServices.hourlyXval;
    if (!active) {
      paint.color = Colors.grey;
    }
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, 25),
      paint,
    );

    // canvas.drawLine(
    //   Offset(x, size.height + 0),
    //   Offset(x, size.height + 20),
    //   paint,
    // );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
