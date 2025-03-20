import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../1_time_record/day_record.dart';
import '../1_time_record/time_record_provider.dart';
import '../2_indices/indices_provider.dart';

final releventDaysProvider = Provider<List<DayEntry>>((ref) {
  final indices = ref.watch(indicesProvider);
  final timeRecord = ref.read(timeRecordProvider);

  final releventIndices = indices.monthIndices
    ..removeWhere((index) => index == indices.todayIndex);
  debugPrint('ReleventDaysProvider.build()');
  return releventIndices.map((index) => timeRecord.days[index]).toList();
});

class ReleventDaysProviderDebugView extends ConsumerWidget {
  const ReleventDaysProviderDebugView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final releventDays = ref.watch(releventDaysProvider);
    if (releventDays.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Relevent Days Provider'),
          for (final day in releventDays)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('   dt: ${day.dt}'),
                Text('   durPoint: ${day.durPoint}'),
                Text('   events: ${day.events.length}'),
              ],
            ),
        ],
      );
    } else {
      return const Text('No relevent days');
    }
  }
}
