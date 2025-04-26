import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/0_data_model/day_record.dart';
import 'package:ten_thousands_hours/modules/0_data_model/time_stamp.dart';

import '../1_time_record/time_record_provider.dart';
import '../2_indices/indices_provider.dart';

final todayProvider = Provider<DayEntry>((ref) {
  final indices = ref.watch(indicesProvider);
  final timeRecord = ref.read(timeRecordProvider);
  // debugPrint('todayProvider');
  if (indices.todayIndex < 0) {
    return DayEntry.create(DateTime.now());
  }

  return timeRecord.days[indices.todayIndex];
});

class TodayRecordProviderDebugView extends ConsumerWidget {
  const TodayRecordProviderDebugView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today Record Provider'),
        Text('   dt: ${today.dt}'),
        Text('   durPoint: ${today.lastRecordedDur}'),
        Text('   events: ${today.events.length}'),
        for (var event in today.events)
          Text(
            '    ${event.dt.hour}:${event.date.minute}:${event.date.second} ${event.typ == TPType.pause ? 'pase' : 'resume'} ${event.dur}',
          ),
      ],
    );
  }
}

final statusProvider = Provider<TPType>((ref) {
  final today = ref.watch(todayProvider);
  return today.lastTimeStapm.typ;
});

class EventButton extends ConsumerWidget {
  const EventButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(statusProvider);
    return IconButton(
      onPressed: () {
        ref.read(timeRecordProvider.notifier).addActiveEvent();
      },
      icon: status == TPType.pause
          ? const Icon(Icons.play_arrow)
          : const Icon(Icons.pause),
    );
  }
}
