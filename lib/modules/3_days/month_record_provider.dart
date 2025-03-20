import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/1_time_record/day_record.dart';

import '../1_time_record/time_record_provider.dart';
import '../2_indices/indices_provider.dart';

final monthRecordProvider = Provider<List<DayEntry>>((ref) {
  final indices = ref.watch(indicesProvider);
  final timeRecord = ref.watch(timeRecordProvider);

  final monthIndices = indices.monthIndices;
  debugPrint('MonthRecordProvider.build()');
  return monthIndices.map((index) => timeRecord.days[index]).toList();
});

class MonthRecordProviderDebugView extends ConsumerWidget {
  const MonthRecordProviderDebugView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthRecords = ref.watch(monthRecordProvider);
    if (monthRecords.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Month Record Provider'),
          for (final record in monthRecords)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('   dt: ${record.dt}'),
                Text('   durPoint: ${record.durPoint}'),
                Text('   events: ${record.events.length}'),
              ],
            ),
        ],
      );
    } else {
      return const Text('No records for this month');
    }
  }
}
