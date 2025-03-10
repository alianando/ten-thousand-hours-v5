import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_data/model/time_point/time_point.dart';
import 'package:ten_thousands_hours/providers/time_data_provider.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';
import 'package:ten_thousands_hours/widgets/tripple_rail.dart';

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
          leading: const Text('  current Status'),
          trailing: Text(todayEntry.durPoint.typ.toString().split('.').last),
        ),
        TripleRail(
          //leading: const Text('  DUR'),
          // middle: Text(),
          trailing: Text(
            '${DtUtils.durToHM(todayEntry.durPoint.dur)}+${DtUtils.durToHMS(todayEntry.durPoint.dur)}',
          ),
        ),
      ],
    );
  }
}
