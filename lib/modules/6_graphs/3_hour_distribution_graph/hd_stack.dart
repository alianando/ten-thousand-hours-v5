import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hd_hour_indicator_painter.dart';
import 'today_hd_painter.dart';

class HDStackView extends ConsumerWidget {
  const HDStackView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text('Day View'),
        ),
        SizedBox(
          height: 230,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Stack(
              children: [
                HdHourIndicatorPainter(),
                TodayHdPainter(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
