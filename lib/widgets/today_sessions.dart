import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/time_data_provider.dart';

final todaySessionsPro = Provider((ref) {
  return ref.watch(timeDataPro).todayEntry.sessions;
});

class TodaySessions extends ConsumerWidget {
  const TodaySessions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      // height: 200,
      child: ListView(
        shrinkWrap: true,
        physics: const ScrollPhysics(),
        children: ref.watch(todaySessionsPro).map((session) {
          return ListTile(
            title: Text(session.$3.toString()),
            // subtitle: Text(session.desc),
          );
        }).toList(),
      ),
    );
  }
}
