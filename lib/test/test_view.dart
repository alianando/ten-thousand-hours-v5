import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ten_thousands_hours/models/time_data/model/time_data.dart';
import 'package:ten_thousands_hours/providers/ticker_provider.dart';
import 'package:ten_thousands_hours/providers/time_data_provider.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';
import 'package:ten_thousands_hours/widgets/tripple_rail.dart';

import '../models/time_data/model/session_data.dart';
import '../models/time_data/model/stat_data.dart';

class TestView extends ConsumerWidget {
  const TestView({super.key});

  Future<void> getSpecificRow({bool debug = false}) async {
    try {
      if (debug) {
        debugPrint('fetching from supabase');
      }
      final response = await Supabase.instance.client
          .from('time_data_db')
          .select()
          .eq('id', 1);
      if (response.isNotEmpty) {
        final data = response.first;
        if (data['time_points'] == null) {
          debugPrint('No time points');
          return;
        }
        final timeDataJson = data['time_points'];
        final timeData = TimeData.fromJson(timeDataJson);
        debugPrint('Time Data Found');
        // compare
        // if okay then update
        return;
      }
      return;
    } catch (e) {
      debugPrint('Error fetching data: $e');
      return Future.error(e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double screenWidth = MediaQuery.of(context).size.width;
    final tic = ref.watch(ticPro);
    final timeData = ref.watch(timeDataProvider);
    final today = timeData.days[timeData.indices.today];
    return Scaffold(
      appBar: AppBar(
        title: Text(DtUtils.dtToHMS(tic)),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(timeDataProvider.notifier).getFromSupabase();
            },
            icon: const Icon(Icons.restore_page),
          ),
          IconButton(
            onPressed: () {
              final session = ref.read(timeDataProvider).sessionData;

              ref.read(timeDataProvider.notifier).updateSession(
                    startDt: session.dayStartTime,
                    endDt: session.dayEndTime,
                  );
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              final td = ref.read(timeDataProvider);
              final oldStartTime = td.sessionData.sessionStartDt;
              DateTime newStartTime = oldStartTime.add(
                const Duration(minutes: 30),
              );
              if (newStartTime.isAfter(
                td.days[td.indices.today].lastUpdate,
              )) {
                newStartTime = td.days[td.indices.today].lastUpdate;
              }
              ref.read(timeDataProvider.notifier).updateSession(
                    startDt: newStartTime,
                  );
            },
            icon: const Icon(Icons.arrow_forward),
          ),
          IconButton(
            onPressed: () {
              final oldEndTime =
                  ref.read(timeDataProvider).sessionData.sessionEndDt;
              final newEndTime =
                  oldEndTime.subtract(const Duration(minutes: 30));
              final before = newEndTime.isBefore(
                timeData.days[timeData.indices.today].lastUpdate,
              );
              if (before == false) {
                ref
                    .read(timeDataProvider.notifier)
                    .updateSession(endDt: newEndTime);
              }
            },
            icon: const Icon(Icons.arrow_back),
          ),
          IconButton(
            onPressed: () {
              ref.read(timeDataProvider.notifier).addTimePoint(dt: tic);
              // test1();
              // ref.read(t1Pro.notifier);
            },
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 25, 10, 0),
            child: Stack(
              children: [
                GraphWrapper(TodayPathPainter(
                  coordinates: today.coordinates,
                )),
                GraphWrapper(GridLabelPainter(
                  sessionData: timeData.sessionData,
                  statData: timeData.statData,
                )),
              ],
            ),
          ),
          SessionLabels(
            sessionData: timeData.sessionData,
            screenWidth: screenWidth,
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            itemCount: today.events.length,
            itemBuilder: (_, i) {
              return Text(
                today.events[i].toString(),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class GraphWrapper extends ConsumerWidget {
  final CustomPainter painter;
  const GraphWrapper(this.painter, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth,
      height: 150,
      child: CustomPaint(
        painter: painter,
      ),
    );
  }
}

class SessionLabels extends ConsumerWidget {
  final SessionData sessionData;
  final double screenWidth;
  const SessionLabels({
    super.key,
    required this.sessionData,
    required this.screenWidth,
  });

  void showInvalidTimeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invalid Time'),
          content: const Text(
            'The selected time cannot be in the past. Please choose a valid time.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> selectEndTime(BuildContext context, WidgetRef ref) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(sessionData.sessionEndDt),
    );

    if (picked != null) {
      final newTime = DateTime(
        sessionData.sessionEndDt.year,
        sessionData.sessionEndDt.month,
        sessionData.sessionEndDt.day,
        picked.hour,
        picked.minute,
      );
      if (newTime.isBefore(DateTime.now())) {
        showInvalidTimeDialog(context);
      } else {
        ref.read(timeDataProvider.notifier).updateSession(
              endDt: newTime,
            );
      }
    }
  }

  Future<void> selectStartTime(BuildContext context, WidgetRef ref) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(sessionData.sessionStartDt),
    );

    if (picked != null) {
      /// check if before current time
      final newTime = DateTime(
        sessionData.sessionStartDt.year,
        sessionData.sessionStartDt.month,
        sessionData.sessionStartDt.day,
        picked.hour,
        picked.minute,
      );
      if (newTime.isAfter(DateTime.now())) {
        showInvalidTimeDialog(context);
      } else {
        ref.read(timeDataProvider.notifier).updateSession(
              startDt: newTime,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 50,
      width: screenWidth,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        child: TripleRail(
          leading: GestureDetector(
            onTap: () {
              debugPrint('On tap session start dt');
              selectStartTime(context, ref);
            },
            child: Text(
              DtUtils.dtToHMS(sessionData.sessionStartDt),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ),
          trailing: GestureDetector(
            onTap: () {
              debugPrint('On tap session end dt');
              selectEndTime(context, ref);
            },
            child: Text(
              DtUtils.dtToHMS(sessionData.sessionEndDt),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ),
          // : Text(DtUtils.durToLabel(sessionData.dur)),
        ),
      ),
    );
  }
}

class SessionEndLabel extends ConsumerWidget {
  const SessionEndLabel({
    super.key,
    required this.screenWidth,
    required this.sessionEndDt,
  });

  final double screenWidth;
  final DateTime sessionEndDt;

  void showInvalidTimeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invalid Time'),
          content: const Text(
            'The selected time cannot be in the past. Please choose a valid time.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> selectTime(BuildContext context, WidgetRef ref) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(sessionEndDt),
    );

    if (picked != null) {
      /// check if before current time
      if (picked.hour < DateTime.now().hour ||
          (picked.hour == DateTime.now().hour &&
              picked.minute < DateTime.now().minute)) {
        showInvalidTimeDialog(context);
      }
      if ((picked.hour == sessionEndDt.hour &&
          picked.minute == sessionEndDt.minute)) {
        // do nothing
      } else {
        /// update session end time
        ref.read(timeDataProvider.notifier).updateSession(
              endDt: DateTime(
                sessionEndDt.year,
                sessionEndDt.month,
                sessionEndDt.day,
                picked.hour,
                picked.minute,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 30,
      width: screenWidth,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            right: 15,
            child: GestureDetector(
              onTap: () {
                debugPrint('On tap session end dt');
                selectTime(context, ref);
              },
              child: Text(
                DtUtils.dtToHMS(sessionEndDt),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SessionStartLabel extends ConsumerWidget {
  const SessionStartLabel({
    super.key,
    required this.screenWidth,
    required this.sessionStartDt,
  });

  final double screenWidth;
  final DateTime sessionStartDt;

  void showInvalidTimeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invalid Time'),
          content: const Text(
            'The selected time cannot be in the future. Please choose a valid time.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> selectTime(BuildContext context, WidgetRef ref) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(sessionStartDt),
    );

    if (picked != null) {
      /// check if before current time
      final newTime = DateTime(
        sessionStartDt.year,
        sessionStartDt.month,
        sessionStartDt.day,
        picked.hour,
        picked.minute,
      );
      if (newTime.isAfter(DateTime.now())) {
        showInvalidTimeDialog(context);
      } else {
        ref.read(timeDataProvider.notifier).updateSession(
              startDt: newTime,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 30,
      width: screenWidth,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 15,
            child: GestureDetector(
              onTap: () {
                debugPrint('On tap session start dt');
                selectTime(context, ref);
              },
              child: Text(
                DtUtils.dtToHMS(sessionStartDt),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TodayPathPainter extends CustomPainter {
  final List<Offset> coordinates;

  TodayPathPainter({required this.coordinates});

  @override
  void paint(Canvas canvas, Size size) {
    // if (coordinates.isEmpty) {
    //   return;
    // }
    // debugPrint(coordinates.toString());
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
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(p, paint);
    canvas.drawCircle(
      Offset(
        coordinates.last.dx * size.width,
        (1 - coordinates.last.dy) * size.height,
      ),
      5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class GridLabelPainter extends CustomPainter {
  final SessionData sessionData;
  final StatData statData;
  GridLabelPainter({
    required this.sessionData,
    required this.statData,
  });
  final int extraLength = 30;
  final double textGap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    // y1 and y2 line.
    Path p = Path();
    p.moveTo(0, 0);
    p.lineTo(0, size.height + extraLength);
    p.moveTo(size.width, 0);
    p.lineTo(size.width, size.height + extraLength);
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    canvas.drawPath(p, paint);
    // y1 and y2 labels
    // TextPainter textPainter = TextPainter(
    //   text: TextSpan(
    //     text: DtUtils.dtToHMS(sessionData.sessionStartDt),
    //     style: const TextStyle(
    //       color: Colors.black,
    //       fontSize: 12,
    //     ),
    //   ),
    //   textDirection: TextDirection.ltr,
    // );

    // textPainter.layout();
    // textPainter.paint(
    //   canvas,
    //   Offset(textGap, size.height + extraLength - textPainter.height),
    // );
    // textPainter = TextPainter(
    //   text: TextSpan(
    //     text: DtUtils.dtToHMS(sessionData.sessionEndDt),
    //     style: const TextStyle(
    //       color: Colors.black,
    //       fontSize: 12,
    //     ),
    //   ),
    //   textDirection: TextDirection.ltr,
    // );

    // textPainter.layout();
    // textPainter.paint(
    //   canvas,
    //   Offset(
    //     size.width - textGap - textPainter.width,
    //     size.height + extraLength - textPainter.height,
    //   ),
    // );

    /// max dur label
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: DtUtils.durToLabel(
          statData.maxDurReleventDays,
        ),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width - textGap * 2 - textPainter.width,
        -1 - textPainter.height / 2,
      ),
    );

    /// y1 and y2 line.
    Path yLine = Path();
    yLine.moveTo(0, 0);
    yLine.lineTo(size.width - textGap * 3 - textPainter.width, 0);
    yLine.moveTo(size.width - textGap * 1, 0);
    yLine.lineTo(size.width, 0);
    // yLine.moveTo(size.width, 0);
    // yLine.lineTo(size.width, size.height + extraLength);
    canvas.drawPath(yLine, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class SessionEndPainter extends CustomPainter {
  final SessionData sessionData;
  SessionEndPainter({required this.sessionData});
  final int extraLength = 30;
  final double textGap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    // y1 and y2 line.
    // Path p = Path();
    // p.moveTo(0, 0);
    // p.lineTo(0, size.height + extraLength);
    // p.moveTo(size.width, 0);
    // p.lineTo(size.width, size.height + extraLength);
    // Paint paint = Paint()
    //   ..color = Colors.black
    //   ..strokeWidth = 1.1
    //   ..style = PaintingStyle.stroke;
    // canvas.drawPath(p, paint);
    // y1 and y2 labels
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: DtUtils.dtToHMS(sessionData.sessionEndDt),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width - textGap - textPainter.width,
        size.height + extraLength - textPainter.height,
      ),
    );
    // textPainter = TextPainter(
    //   text: TextSpan(
    //     text: DtUtils.dtToHMS(sessionData.sessionEndDt),
    //     style: const TextStyle(
    //       color: Colors.black,
    //       fontSize: 12,
    //     ),
    //   ),
    //   textDirection: TextDirection.ltr,
    // );

    // textPainter.layout();
    // textPainter.paint(
    //   canvas,
    //   Offset(
    //     size.width - textGap - textPainter.width,
    //     size.height + extraLength - textPainter.height,
    //   ),
    // );

    // /// y1 and y2 line.
    // Path yLine = Path();
    // yLine.moveTo(0, 0);
    // yLine.lineTo(size.width - textGap * 3 - textPainter.width, 0);
    // yLine.moveTo(size.width - textGap * 1, 0);
    // yLine.lineTo(size.width, 0);
    // // yLine.moveTo(size.width, 0);
    // // yLine.lineTo(size.width, size.height + extraLength);
    // canvas.drawPath(yLine, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
