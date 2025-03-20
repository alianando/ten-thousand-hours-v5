import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/1_time_record/time_stamp.dart';

import '../../providers/ticker_provider.dart';
import '../3_days/today_record_provider.dart';

final todayDurProvider = Provider<Duration>((ref) {
  final ticker = ref.watch(ticPro);
  final today = ref.watch(todayProvider);
  final dur = today.events.last.dur +
      ((today.events.last.typ == TPType.resume)
          ? ticker.difference(today.events.last.dt)
          : Duration.zero);
  return dur;
});

class TodayDurationProviderDebugView extends ConsumerWidget {
  const TodayDurationProviderDebugView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dur = ref.watch(todayDurProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today Duration Provider'),
        Text('   dur: $dur'),
      ],
    );
  }
}
