import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/providers/ticker_provider.dart';

import '../../models/time_data/model/time_data.dart';
import '../../models/time_data/model/time_point.dart';
import '../../providers/time_data_provider.dart';

final eventStatusProvider = StateProvider<bool>((ref) {
  final timeData = ref.watch(timeDataProvider);
  return timeData.days[timeData.indices.today].events.last.typ ==
      TimePointTyp.resume;
});

class EventButton extends ConsumerWidget {
  const EventButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(eventStatusProvider);
    return IconButton(
      onPressed: () {
        final tic = ref.read(ticPro);
        ref.read(timeDataProvider.notifier).addTimePoint(dt: tic);
      },
      icon: Icon(active ? Icons.pause : Icons.play_arrow),
    );
  }
}
