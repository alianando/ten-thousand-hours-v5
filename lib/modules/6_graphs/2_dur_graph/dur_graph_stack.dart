import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dg_other_day_painter.dart';
import 'dg_today_painter.dart';

class DurGraphStack extends ConsumerWidget {
  const DurGraphStack({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text('Daily Duration Graph'),
        ),
        SizedBox(
          height: 120,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Stack(
              children: [
                DgOtherDayView(),
                DgTodayView(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
