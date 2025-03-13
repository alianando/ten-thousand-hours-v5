import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_data/time_point/time_point.dart';
import 'package:ten_thousands_hours/providers/time_data_provider.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';
import 'package:ten_thousands_hours/widgets/tripple_rail.dart';

import '../providers/ticker_provider.dart';

final todayEntryPro = Provider((ref) {
  final todayEntry = ref.watch(timeDataPro).todayEntry;
  return todayEntry;
});

class TodaySummary extends ConsumerWidget {
  const TodaySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayEntry = ref.watch(todayEntryPro);
    return ListView(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      children: [
        TripleRail(
          leading: const Text('Today'),
          trailing: Text(DtUtils.dateString(todayEntry.dt)),
        ),
        TripleRail(
          leading: const Text('  - Status'),
          trailing: Text(
            todayEntry.durPoint.typ.toString().split('.').last.toUpperCase(),
          ),
        ),
        const TripleRail(
          leading: Text('  - Worked'),
          trailing: TodayDurWidget(),
        ),
      ],
    );
  }
}

class TodayDurWidget extends ConsumerWidget {
  const TodayDurWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tic = ref.watch(ticPro);
    final today = ref.read(todayEntryPro);
    // final tic = DateTime.now();
    if (today.durPoint.typ == TimePointTyp.pause) {
      return Text(TimeFormatter.formatDuration(today.durPoint.dur));
    } else {
      if (today.durPoint.dur == Duration.zero) {
        return Text(
          TimeFormatter.formatDuration(tic.difference(today.durPoint.dt)),
        );
      }
      return Text(
        '${TimeFormatter.formatDuration(today.durPoint.dur)} + ${TimeFormatter.formatDuration(tic.difference(today.durPoint.dt))}',
      );
    }
  }
}
