import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_data/model/time_data.dart';
import 'package:ten_thousands_hours/providers/ticker_provider.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';

import '../../models/time_data/model/day_model/day_model.dart';
import '../../models/time_data/model/session_data.dart';
import '../../models/time_data/model/stat_data.dart';
import '../../providers/time_data_provider.dart';

class GraphButtons extends ConsumerWidget {
  const GraphButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      // height: 5,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {
              final timeData = ref.read(timeDataProvider);
              ref.read(timeDataProvider.notifier).updateSession(
                    startDt: timeData.sessionData.dayStartTime,
                    endDt: timeData.sessionData.dayEndTime,
                  );
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              final oldStartTime =
                  ref.read(timeDataProvider).sessionData.sessionStartDt;
              DateTime newStartTime = oldStartTime.add(
                const Duration(minutes: 30),
              );
              final tic = ref.read(ticPro);
              if (newStartTime.isAfter(tic)) {
                newStartTime = tic;
              }
              ref.read(timeDataProvider.notifier).updateSession(
                    startDt: newStartTime,
                  );
            },
            icon: const Icon(Icons.arrow_forward),
          ),
          IconButton(
            onPressed: () {
              final sessionData = ref.read(timeDataProvider).sessionData;
              final oldSesEnd = sessionData.sessionEndDt;
              final newSesEnd = oldSesEnd.subtract(
                const Duration(minutes: 30),
              );
              final tic = ref.read(ticPro);
              if (newSesEnd.isAfter(tic)) {
                ref.read(timeDataProvider.notifier).updateSession(
                      endDt: newSesEnd,
                    );
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ],
      ),
    );
  }
}

class GraphStack extends ConsumerWidget {
  const GraphStack({super.key});

  List<T> getItemsAtIndices<T>(List<T> items, List<int> targetIndices) {
    final result = <T>[];

    for (final index in targetIndices) {
      // Check if the index is valid
      if (index >= 0 && index < items.length) {
        result.add(items[index]);
      }
    }

    return result;
  }

  List<Offset> getCordinatesAtIndex(List<DayModel> items, index) {
    return items[index].coordinates;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const double height = 230;
    const double width = double.infinity;
    final timeData = ref.watch(timeDataProvider);
    return Stack(
      children: [
        GraphWrapper(
          GridLabelPainter(
            sessionData: timeData.sessionData,
            statData: timeData.statData,
          ),
          height: height,
          width: width,
        ),
        GraphWrapper(
          PreviousDaysPathPainter(
            previousDaysCoordinates: getItemsAtIndices(
              timeData.days.map((day) => day.coordinates).toList(),
              timeData.weekIndices,
            ),
          ),
          height: height,
          width: width,
        ),
        const TodayPathGraph(height),
      ],
    );
  }
}

class GraphWrapper extends ConsumerWidget {
  final CustomPainter painter;
  final double height;
  final double width;
  const GraphWrapper(
    this.painter, {
    required this.height,
    required this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: painter,
      ),
    );
  }
}

class GridLabelPainter extends CustomPainter {
  final SessionData sessionData;
  final StatData statData;

  GridLabelPainter({required this.sessionData, required this.statData});

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

    // Draw Session Start and End Time.
    TextPainter textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 10,
    );
    textPainter.text = TextSpan(
      text: DtUtils.dtToHMS(sessionData.sessionStartDt),
      style: textStyle,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(0, size.height + 5),
    );
    textPainter.text = TextSpan(
      text: DtUtils.dtToHMS(sessionData.sessionEndDt),
      style: textStyle,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width, size.height + 5),
    );

    // draw max dur line
    textPainter.text = TextSpan(
      text: DtUtils.durToHMS(statData.maxDurReleventDays),
      style: textStyle,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(0, -textPainter.height - 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

final todayPathCoo = Provider<List<Offset>>((ref) {
  final timeData = ref.watch(timeDataProvider);
  return timeData.today.coordinates;
});

class TodayPathGraph extends ConsumerWidget {
  final double height;
  const TodayPathGraph(this.height, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinates = ref.watch(todayPathCoo);
    if (coordinates.isNotEmpty) {
      return GraphWrapper(
        TodayPathPainter(coordinates: coordinates),
        height: height,
        width: double.infinity,
      );
    }
    return const SizedBox();
  }
}

class TodayPathPainter extends CustomPainter {
  final List<Offset> coordinates;

  TodayPathPainter({required this.coordinates});

  @override
  void paint(Canvas canvas, Size size) {
    // final paint = Paint()
    //   ..color = Colors.blue
    //   ..strokeWidth = 2.0
    //   ..strokeWidth = 1
    //   ..style = PaintingStyle.stroke
    //   ..strokeCap = StrokeCap.round;

    // for (int i = 0; i < coordinates.length - 1; i++) {
    //   canvas.drawLine(coordinates[i], coordinates[i + 1], paint);
    // }
    drawPath(canvas, size);
    // drawEndCap(canvas, size);
    drawMarker(canvas, size);
  }

  void drawPath(Canvas canvas, Size size) {
    Path p = Path();
    for (int i = 0; i < coordinates.length; i++) {
      final Offset o = coordinates[i];
      if (i == 0) {
        p.moveTo(o.dx * size.width, (1 - o.dy) * size.height);
      } else {
        p.lineTo(o.dx * size.width, (1 - o.dy) * size.height);
      }
    }
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(p, paint);
  }

  void drawEndCap(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(
        coordinates.last.dx * size.width,
        (1 - coordinates.last.dy) * size.height,
      ),
      5,
      paint,
    );
  }

  void drawMarker(Canvas canvas, Size size) {
    if (coordinates.length < 2) {
      return;
    }
    final bool active =
        coordinates.last.dy > coordinates[coordinates.length - 2].dy;
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    if (active) {
      paint.color = Colors.green;
    } else {
      paint.color = Colors.red;
    }

    // final c1 = findThirdVertex(
    //   Offset(
    //     coordinates.last.dx * size.width,
    //     (1 - coordinates.last.dy) * size.height,
    //   ),
    //   Offset(
    //     coordinates[coordinates.length - 2].dx * size.width,
    //     (1 - coordinates[coordinates.length - 2].dy) * size.height,
    //   ),
    //   0.05,
    // );
    // final c2 = findThirdVertex(
    //   Offset(
    //     coordinates.last.dx * size.width,
    //     (1 - coordinates.last.dy) * size.height,
    //   ),
    //   Offset(
    //     coordinates[coordinates.length - 2].dx * size.width,
    //     (1 - coordinates[coordinates.length - 2].dy) * size.height,
    //   ),
    //   1,
    // );

    // final c3 = findPointC(
    //   Offset(
    //     coordinates.last.dx * size.width,
    //     (1 - coordinates.last.dy) * size.height,
    //   ),
    //   Offset(
    //     coordinates[coordinates.length - 2].dx * size.width,
    //     (1 - coordinates[coordinates.length - 2].dy) * size.height,
    //   ),
    // );
    // canvas.drawLine(
    //   Offset(
    //     coordinates.last.dx * size.width,
    //     (1 - coordinates.last.dy) * size.height,
    //   ),
    //   c3,
    //   paint,
    // );

    // canvas.drawLine(
    //   c1,
    //   c2,
    //   paint,
    // );
    // canvas.drawLine(
    //   c1,
    //   c2,
    //   paint,
    // );
    canvas.drawLine(
      Offset(
        coordinates.last.dx * size.width,
        (1 - coordinates.last.dy) * size.height - 10,
      ),
      Offset(
        coordinates.last.dx * size.width,
        (1 - coordinates.last.dy) * size.height - 40,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(
        coordinates.last.dx * size.width,
        (1 - coordinates.last.dy) * size.height + 10,
      ),
      Offset(
        coordinates.last.dx * size.width,
        (1 - coordinates.last.dy) * size.height + 40,
      ),
      paint,
    );
    // canvas.drawRect(
    //   Rect.fromLTWH(
    //     coordinates.last.dx * size.width - x,
    //     (1 - coordinates.last.dy) * size.height - y,
    //     x * 2,
    //     y * 2,
    //   ),
    //   paint,
    // );
  }

  Offset findPointC(Offset a, Offset b) {
    // Calculate the differences
    double dx = b.dx - a.dx;
    double dy = b.dy - a.dy;

    // Since CAB is 90 degrees, we can find C by rotating the vector (dx, dy)
    // 90 degrees counter-clockwise gives us (-dy, dx)
    double cx = a.dx - dy;
    double cy = a.dy + dx;
    double cx2 = a.dx + dy; // C's x-coordinate (clockwise)
    double cy2 = a.dy - dx; // C's y-coordinate (clockwise)

    // return Offset(cx, cy);
    return Offset(cx2, cy2);
  }

  /// Finds the third vertex of a right triangle given two vertices and a scaling factor.
  Offset findThirdVertex(Offset A, Offset B, double k) {
    // Vector AB
    Offset AB = B - A;

    // Vector perpendicular to AB.  We swap the coordinates and negate one.
    // The correct calculation is:
    Offset AC_perp = Offset(-AB.dy, AB.dx);

    // Calculate coordinates of C
    Offset C = A + AC_perp * k;

    return C;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class PreviousDaysPathPainter extends CustomPainter {
  final List<List<Offset>> previousDaysCoordinates;

  PreviousDaysPathPainter({required this.previousDaysCoordinates});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (var dayCoordinates in previousDaysCoordinates) {
      Path path = Path();
      for (int i = 0; i < dayCoordinates.length; i++) {
        final Offset o = dayCoordinates[i];
        if (i == 0) {
          path.moveTo(o.dx * size.width, (1 - o.dy) * size.height);
        } else {
          path.lineTo(o.dx * size.width, (1 - o.dy) * size.height);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
