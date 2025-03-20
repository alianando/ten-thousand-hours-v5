import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/ticker_provider.dart';
import '../../../utils/dt_utils.dart';
import '../../1_time_record/time_stamp.dart';
import '../../3_days/today_record_provider.dart';
import '../../4_statistics/relevent_max_dur_provider.dart';
import '../../5_coordinates/c.dart';
import 'primary_graph_services.dart';

final todayPrimaryGraphPointsProvider = Provider<List<C>>((ref) {
  final points = ref.watch(todayProvider).events;
  final releventMaxDur = ref.watch(releventMaxDurProvider);

  final sessionStartTime = DtHelper.dayStartDt(points.first.dt);
  final sessionEndTime = DtHelper.dayEndDt(points.first.dt);
  List<C> todayPoints = PrimaryGraphService.generateCoordinates(
    timePoints: points,
    sessionStartTime: sessionStartTime,
    sessionEndTime: sessionEndTime,
    maxSessionDur: releventMaxDur,
    minSessionDur: const Duration(),
  );
  final now = ref.watch(ticPro);
  final nowPoint = TimeStamp(
    now,
    points.last.typ == TPType.resume
        ? points.last.dur + now.difference(points.last.dt)
        : points.last.dur,
    points.last.typ,
  );
  final nowPointCoordinate = PrimaryGraphService.generateCoordinate(
    point: nowPoint,
    correctedSesStartDt: sessionStartTime,
    sessionDurInMillisec:
        sessionEndTime.difference(sessionStartTime).inMilliseconds,
    maxDur: releventMaxDur,
    minDur: const Duration(),
    debug: false,
  );
  if (nowPointCoordinate != null) {
    todayPoints.add(nowPointCoordinate);
  }
  return todayPoints;
});

class TodayPrimaryGraphPointsProviderDebug extends ConsumerWidget {
  const TodayPrimaryGraphPointsProviderDebug({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(todayPrimaryGraphPointsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text('Today Primary Graph Points Provider'),
        ...points.map((point) => Text('   $point')),
        const Divider(),
      ],
    );
  }
}
