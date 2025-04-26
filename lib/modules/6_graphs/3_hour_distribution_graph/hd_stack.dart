import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/1_time_record/time_record_provider.dart';
import 'package:ten_thousands_hours/modules/6_graphs/3_hour_distribution_graph/1_hd_today_paint.dart';
import 'package:ten_thousands_hours/modules/6_graphs/3_hour_distribution_graph/dh_day_index_provider.dart';

import '2_hd_lebels_painter.dart';
import 'day_hour_duration_provider.dart';
import 'hd_avg_distribution_painter.dart';
import 'hd_hour_indicator_painter.dart';
import 'today_hd_painter.dart';

class HDStackView extends ConsumerStatefulWidget {
  const HDStackView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HDStackViewState();
}

class _HDStackViewState extends ConsumerState<HDStackView> {
  @override
  void initState() {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(hourly_distribution_day_index_provider.notifier).increase();
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8),
          // child: _DateWidget(),
          child: Text('Hourly Distribution Graph'),
        ),
        SizedBox(
          height: 150,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Stack(
              children: [
                HdHourIndicatorPainter(),
                HDTodayPaint(),
                HDLebelsPainter(),
                // HdAvgDistributionPainter(),
                // TodayHdPainter(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateWidget extends ConsumerWidget {
  const _DateWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(hourly_distribution_day_index_provider);
    final dt = ref.read(timeRecordProvider).days[index].dt;
    return Text(dt.toString());
  }
}
