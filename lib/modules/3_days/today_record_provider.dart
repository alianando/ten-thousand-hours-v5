import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/1_time_record/day_record.dart';

import '../1_time_record/time_record_provider.dart';
import '../2_indices/indices_provider.dart';

final todayProvider = Provider<DayEntry>((ref) {
  final indices = ref.watch(indicesProvider);
  final timeRecord = ref.read(timeRecordProvider);
  debugPrint('todayProvider');
  if (indices.todayIndex < 0) {
    return DayRecordService.createDay(DateTime.now());
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
        Text('   durPoint: ${today.durPoint}'),
        Text('   events: ${today.events.length}'),
      ],
    );
  }
}
