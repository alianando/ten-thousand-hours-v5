import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/0_data_model/time_stamp.dart';

import '../0_data_model/day_record.dart';
import '../1_time_record/time_record_provider.dart';
import '../2_indices/indices_provider.dart';

final releventDaysProvider = Provider<List<DayEntry>>((ref) {
  final releventIndecies = ref.watch(relaventIndicesProvider);
  debugPrint('relaventDaysProvider Build ${releventIndecies.length} days');
  final timeRecord = ref.read(timeRecordProvider);
  return releventIndecies.map((index) => timeRecord.days[index]).toList()
    ..sort((a, b) => a.dt.compareTo(b.dt));
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
          const Divider(),
          const Text('Relevent Days Provider'),
          for (final day in releventDays)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Container(
                // border around the container
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day ${day.dt.year}-${day.dt.month}-${day.dt.day}'),
                    Text('total duration: ${day.lastRecordedDur}'),
                    Text('events: ${day.events.length}'),
                    for (var event in day.events)
                      Text(
                        '  ${event.dt.hour}:${event.date.minute}:${event.date.second} ${event.typ == TPType.pause ? 'pase' : 'resume'} ${event.dur}',
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
    } else {
      return const Text('No relevent days');
    }
  }
}
