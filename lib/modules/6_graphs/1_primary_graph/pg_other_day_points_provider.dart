import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/6_graphs/1_primary_graph/primary_graph_services.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';

import '../../3_days/relevent_days_provider.dart';
import '../../4_statistics/relevent_max_dur_provider.dart';
import '../../5_coordinates/c.dart';

final pgOtherDayPointsProvider = Provider<List<List<C>>>((ref) {
  final otherDays = ref.watch(releventDaysProvider);
  final releventMaxDur = ref.watch(releventMaxDurProvider);
  List<List<C>> otherDayPoints = [];
  final todayStartDt = DtHelper.dayStartDt(DateTime.now());
  final todayEndDt = DtHelper.dayEndDt(todayStartDt);
  for (int i = 0; i < otherDays.length; i++) {
    final day = otherDays[i];

    final z = todayStartDt.difference(day.dt).inDays.toDouble();
    List<C> dayPoints = PrimaryGraphService.generateCoordinates(
      timePoints: day.events,
      sessionStartTime: todayStartDt,
      sessionEndTime: todayEndDt,
      maxSessionDur: releventMaxDur,
      minSessionDur: Duration.zero,
      z: z,
    );
    otherDayPoints.add(dayPoints);
  }
  return otherDayPoints;
});

class PgOtherDayPointsProviderDebugView extends ConsumerWidget {
  const PgOtherDayPointsProviderDebugView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(pgOtherDayPointsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('PG Other Day Points Provider'),
        ListView.builder(
          shrinkWrap: true,
          physics: const ScrollPhysics(),
          itemCount: days.length,
          itemBuilder: (_, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$index day'),
                Text('Last point ${days[index].last}')
                // ListView.builder(
                //   shrinkWrap: true,
                //   physics: const ScrollPhysics(),
                //   itemCount: days[index].length,
                //   itemBuilder: (_, p) {
                //     return Text(days[index].last.y.toString());
                //   },
                // )
              ],
            );
          },
        ),
      ],
    );
  }
}
