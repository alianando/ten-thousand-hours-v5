import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_entry_entity/time_entry_provider/time_entry_provider.dart';
import 'package:ten_thousands_hours/models/time_entry_entity/time_point/time_point.dart';
import 'package:ten_thousands_hours/providers/ticker_provider.dart';
import 'package:ten_thousands_hours/providers/time_data_provider.dart';

import '../utils/dt_utils.dart';
import 'tripple_rail.dart';

final totalSumPro = Provider((ref) {
  // final tic = ref.watch(ticPro);
  final time = ref.watch(timeEntryP);
  int startedDaysAgo = 0;
  Duration totalDur = time.days.fold<Duration>(
    const Duration(),
    (previousValue, element) => previousValue + element.durPoint.dur,
  );
  Duration activeAvg = const Duration();
  Duration avg = const Duration();

  if (time.days.isNotEmpty) {
    startedDaysAgo = time.days.last.dt.difference(time.days.first.dt).inDays;
    activeAvg = totalDur ~/ time.days.length;
  }
  if (startedDaysAgo == 0) startedDaysAgo = 1;
  avg = totalDur ~/ startedDaysAgo;

  return {
    'startedDaysAgo': startedDaysAgo,
    'activeAvg': activeAvg,
    'avg': avg,
    'dayEntries': time.days.length,
    'totalDur': totalDur,
  };
});

class TotalSummary extends ConsumerWidget {
  const TotalSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final time = ref.watch(timeEntryP);
    final data = ref.watch(totalSumPro);
    final startedDaysAgo = data['startedDaysAgo'];
    final activeAvg = data['activeAvg'] as Duration;
    final avg = data['avg'] as Duration;
    final dayEntries = data['dayEntries'];
    final totalDur = data['totalDur'] as Duration;
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
            '$dayEntries days',
          ),
        ),
        TripleRail(
          leading: const Text('  - Total worked'),
          middle: const Text('-'),
          trailing: Text(
            TimeFormatter.formatDuration(totalDur),
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
  final time = ref.watch(timeEntryP);

  var maxDurPoint = TimePoint(
    dt: DateTime(1999),
    dur: const Duration(),
    typ: TimePointTyp.pause,
  );
  for (var day in time.days) {
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
