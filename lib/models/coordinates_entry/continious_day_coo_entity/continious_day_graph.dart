import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/coordinates_entry/continious_day_coo_entity/continious_day_coo_providers.dart';
import 'package:ten_thousands_hours/models/coordinates_entry/coordinate_model.dart';

class EventsGraphStack extends ConsumerWidget {
  final double height;
  final double width;
  const EventsGraphStack({
    super.key,
    this.height = 230,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: MonthEventsPainter(
              coordinates: ref.watch(continiousOtherDaysCooPro),
            ),
          ),
        )
      ],
    );
  }
}

class MonthEventsPainter extends CustomPainter {
  final ListOfListOfC coordinates;

  const MonthEventsPainter({required this.coordinates});

  @override
  void paint(Canvas canvas, Size size) {
    if (coordinates.list.isEmpty) {
      return;
    }

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final dayCoordinates in coordinates.list) {
      final path = Path();
      for (int i = 0; i < dayCoordinates.length; i++) {
        final coordinate = dayCoordinates[i];

        final x = coordinate.x * size.width;
        final y = size.height - coordinate.y * size.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
