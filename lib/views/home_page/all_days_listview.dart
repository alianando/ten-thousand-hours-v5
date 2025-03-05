import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';

import '../../providers/time_data_provider.dart';

class AllDaysListview extends ConsumerWidget {
  const AllDaysListview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeData = ref.watch(timeDataProvider);
    return ListView.builder(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      itemCount: timeData.days.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Text(
            timeData.days[index].durPoint.dt.toString(),
          ),
          title: Text(
            '${DtUtils.dateString(timeData.days[index].dt)}, Dur: ${DtUtils.durToHMS(timeData.days[index].durPoint.dur)}',
          ),
          trailing: Text(index.toString()),
          subtitle: CustomPaint(
            size: const Size(double.infinity, 5),
            painter: VerticalDurPainter(timeData.days[index].durPoint.dur),
            // painter: DurationPainter(
            //   timeData.days.map((day) => day.dur).toList(),
            // ),
          ),
          onTap: () {
            // Navigator.pushNamed(context, '/second');
          },
        );
      },
    );
  }
}

class VerticalDurPainter extends CustomPainter {
  final Duration duration;
  final Duration maxDur;

  VerticalDurPainter(this.duration, {this.maxDur = const Duration(hours: 12)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // final double barWidth = size.width / durations.length;
    final double barWidth =
        (duration.inSeconds / maxDur.inSeconds) * size.width;
    final double barHeight = size.height; // Assuming max duration is 24 hours
    final rect = Rect.fromLTWH(0, 0, barWidth, barHeight);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class DurationPainter extends CustomPainter {
  final List<Duration> durations;

  DurationPainter(this.durations);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final double barWidth = size.width / durations.length;
    for (int i = 0; i < durations.length; i++) {
      final double barHeight = (durations[i].inMinutes / 1440) *
          size.height; // Assuming max duration is 24 hours
      final rect = Rect.fromLTWH(
          i * barWidth, size.height - barHeight, barWidth, barHeight);
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
