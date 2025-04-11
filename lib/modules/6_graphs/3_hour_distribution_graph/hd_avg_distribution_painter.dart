import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'avg_hd_distribution_provider.dart';

class HdAvgDistributionPainter extends ConsumerWidget {
  const HdAvgDistributionPainter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avgDis = ref.watch(avgHDistributionProvider);
    return SizedBox(
      height: double.infinity,
      width: double.infinity,
      child: CustomPaint(
        painter: HdAvgDistributionPainterPainter(avgDis),
      ),
    );
  }
  //   final avgDis = ref.watch(avgHDistributionProvider);
  //   avgDis.when(data: (val) {
  //     return SizedBox(
  //       height: double.infinity,
  //       width: double.infinity,
  //       child: CustomPaint(
  //         painter: HdAvgDistributionPainterPainter(val),
  //       ),
  //     );
  //   }, error: (_, __) {
  //     return const SizedBox(
  //       height: double.infinity,
  //       width: double.infinity,
  //       child: Center(
  //         child: Text('Error'),
  //       ),
  //     );
  //   }, loading: () {
  //     return const SizedBox(
  //       height: double.infinity,
  //       width: double.infinity,
  //       child: Center(
  //         child: CircularProgressIndicator(),
  //       ),
  //     );
  //   });
  //   return const SizedBox(
  //     height: double.infinity,
  //     width: double.infinity,
  //     child: Text('Outside of when()'),
  //   );
  // }
}

class HdAvgDistributionPainterPainter extends CustomPainter {
  final Map<double, double> points;
  const HdAvgDistributionPainterPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // var p = Path();
    // final hourVal = points.keys.toList();
    // final durVal = points.values.toList();
    points.forEach((key, value) {
      final double x = key * size.width;
      final double y = (1 - value) * size.height;
      // p.addOval(Rect.fromCircle(center: Offset(x, y), radius: 2));
      canvas.drawLine(Offset(x, size.height), Offset(x, y), paint);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
