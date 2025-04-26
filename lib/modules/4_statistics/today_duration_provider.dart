import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/0_data_model/time_stamp.dart';
import 'package:ten_thousands_hours/modules/3.2_data_providers.dart/current_status_provider.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';

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

class CurrentDurationView extends ConsumerWidget {
  const CurrentDurationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastEvent = ref.watch(latestTimeStampProvider);
    if (lastEvent.dt.hour == 0 &&
        lastEvent.dt.minute == 0 &&
        lastEvent.dt.second == 0) {
      return const Text('Did not worked today.');
    }
    final ticker = ref.watch(ticPro);
    final interval = ticker.difference(lastEvent.dt);
    if (lastEvent.typ == TPType.pause) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ' Achieved ${TimeFormatter.formatDuration(lastEvent.dur)} at ${TimeFormatter.formatTimeCompact(lastEvent.dt)}',
            style: const TextStyle(
              fontSize: 20,
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ' and resting for ${TimeFormatter.formatDuration(interval)}',
            style: const TextStyle(
              fontSize: 19,
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    final dur = lastEvent.dur + interval;
    String msg = ' ${TimeFormatter.formatDuration(interval)}';
    if (lastEvent.dur == Duration.zero) {
      // msg = '$msg = ${dur.inMinutes}min';
    } else {
      msg =
          '$msg+ ${TimeFormatter.formatDuration(lastEvent.dur)} = ${dur.inMinutes}min';
    }
    return Text(
      msg,
      style: const TextStyle(
        fontSize: 20,
        color: Colors.blueGrey,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class TodayDurationProviderDebugView extends ConsumerWidget {
  const TodayDurationProviderDebugView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dur = ref.watch(todayDurProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today Duration Provider $dur'),
      ],
    );
  }
}
