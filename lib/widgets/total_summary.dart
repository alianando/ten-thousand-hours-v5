import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_data/time_point/time_point.dart';
import 'package:ten_thousands_hours/providers/time_data_provider.dart';

import '../utils/dt_utils.dart';
import 'tripple_rail.dart';

class TotalSummary extends ConsumerWidget {
  const TotalSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ref.watch(timeDataPro);
    int startedDaysAgo = time.todayEntry.dt
        .difference(
          time.dayEntries.first.dt,
        )
        .inDays;

    Duration activeAvg = time.statData.totalDur ~/ time.dayEntries.length;
    if (startedDaysAgo == 0) startedDaysAgo = 1;
    Duration avg = time.statData.totalDur ~/ startedDaysAgo;
    return ListView(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      children: [
        const TripleRail(
          leading: Text('Overall'),
          // trailing: Text(DtUtils.dateString(todayEntry.dt)),
        ),
        TripleRail(
          leading: const Text('  - Started'),
          middle: const Text('-'),
          trailing: Text(
            '$startedDaysAgo days ago',
          ),
        ),
        TripleRail(
          leading: const Text('  - Worked'),
          middle: const Text('-'),
          trailing: Text(
            '${time.dayEntries.length} days',
          ),
        ),
        TripleRail(
          leading: const Text('  - Total worked'),
          middle: const Text('-'),
          trailing: Text(
            TimeFormatter.formatDuration(time.statData.totalDur),
          ),
        ),
        TripleRail(
          leading: const Text('  - Avg(Active days)'),
          middle: const Text('-'),
          trailing: Text(
            TimeFormatter.formatDuration(activeAvg),
          ),
        ),
        TripleRail(
          leading: const Text('  - Avg(Since Start)'),
          middle: const Text('-'),
          trailing: Text(
            TimeFormatter.formatDuration(avg),
          ),
        ),
        const MaxDurInDay(),
      ],
    );
  }
}

final maxDurInDayPro = Provider((ref) {
  final time = ref.watch(timeDataPro);

  var maxDurPoint = TimePoint(
    dt: time.todayEntry.dt,
    dur: time.statData.todayDur,
    typ: TimePointTyp.pause,
  );
  for (var day in time.dayEntries) {
    if (day.durPoint.dur > maxDurPoint.dur) {
      maxDurPoint = day.durPoint;
    }
  }
  return maxDurPoint;
});

class MaxDurInDay extends ConsumerWidget {
  const MaxDurInDay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxDur = ref.watch(maxDurInDayPro);
    return TripleRail(
      leading: const Text('Best day ->'),
      middle: Text('${DtUtils.dateString(maxDur.dt)} ->'),
      trailing: Text(
        TimeFormatter.formatDuration(maxDur.dur),
      ),
    );
  }
}
