import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_data/model/time_point/time_point.dart';

import '../../providers/time_data_provider.dart';

final todayEventsListviewProvider = Provider<List<TimePoint>>((ref) {
  final timeData = ref.watch(timeDataProvider);
  return timeData.days[timeData.indices.today].events;
});

class TodayEventsListview extends ConsumerWidget {
  const TodayEventsListview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(todayEventsListviewProvider);
    if (events.isNotEmpty) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const ScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return ListTile(
            title: Text(event.typ.toString()),
            subtitle: Text(event.dt.toString()),
            leading: Text(index.toString()),
            trailing: Text(event.dur.inSeconds.toString()),
          );
        },
      );
    }
    return const Center(
      child: Text('No events today'),
    );
  }
}
