import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_data/time_point/time_point.dart';

import '../providers/time_data_provider.dart';
import '../utils/dt_utils.dart';
import '../views/main_graph.dart';

final pastReleventDayCoordsPro = Provider((ref) {
  final time = ref.watch(timeDataPro);

  return time.coordinates.session.unactiveObjects;
});

class DaysTotalDurGraph extends ConsumerWidget {
  const DaysTotalDurGraph({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double height = 230;
    const double width = double.infinity;
    // final appDataProvider = ref.watch(timeDataPro);
    return Stack(
      children: [
        GraphWrapper(
          DaysTotalDurGraphPainter(
            coords: ref
                .watch(pastReleventDayCoordsPro)
                .map((day) => day.last)
                .toList(),
            daysDt:
                ref.read(timeDataPro).dayEntries.map((day) => day.dt).toList(),
            timePoints: ref
                .read(timeDataPro)
                .dayEntries
                .map((day) => day.durPoint)
                .toList(),
          ),
          height: height,
          width: width,
        ),
      ],
    );
  }
}

class DaysTotalDurGraphPainter extends CustomPainter {
  final List<Offset> coords;
  final List<TimePoint> timePoints;
  final List<DateTime> daysDt;

  DaysTotalDurGraphPainter({
    required this.coords,
    this.daysDt = const [],
    this.timePoints = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
    double barWidth = size.width;
    if (coords.isNotEmpty) {
      barWidth = size.width / coords.length;
    }

    TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 10,
    );

    for (int i = 0; i < coords.length; i++) {
      final barLeft = size.width - (i + 1) * barWidth;
      final xMiddle = barLeft + barWidth / 2;
      final barHeight = coords[i].dy * size.height;
      final barTop = size.height - barHeight;
      canvas.drawRect(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
        paint,
      );
      // canvas.drawLine(
      //   Offset(xMiddle, barTop),
      //   Offset(xMiddle, barHeight),
      //   paint,
      // );
      textPainter.text = TextSpan(
        text: '${daysDt[i].month}/${daysDt[i].day}',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(xMiddle - textPainter.width / 2, 5),
      );

      textPainter.text = TextSpan(
        text: '${timePoints[i].dur.inMinutes}m',
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          xMiddle - textPainter.width / 2,
          barTop - textPainter.height - 2,
        ),
      );
    }

    // Draw Session Start and End Time.
    // TextPainter textPainter = TextPainter(
    //   textAlign: TextAlign.center,
    //   textDirection: TextDirection.ltr,
    // );
    // const textStyle = TextStyle(
    //   color: Colors.black,
    //   fontSize: 10,
    // );
    // textPainter.text = TextSpan(
    //   text: DtUtils.dtToHMS(sessionData.sessionStartDt),
    //   style: textStyle,
    // );
    // textPainter.layout();
    // textPainter.paint(
    //   canvas,
    //   Offset(0, size.height + 5),
    // );
    // textPainter.text = TextSpan(
    //   text: DtUtils.dtToHMS(sessionData.sessionEndDt),
    //   style: textStyle,
    // );
    // textPainter.layout();
    // textPainter.paint(
    //   canvas,
    //   Offset(size.width - textPainter.width, size.height + 5),
    // );

    // // draw max dur line
    // textPainter.text = TextSpan(
    //   text: DtUtils.durToHMS(statData.maxDurReleventDays),
    //   style: textStyle,
    // );
    // textPainter.layout();
    // textPainter.paint(
    //   canvas,
    //   Offset(0, -textPainter.height - 2),
    // );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
