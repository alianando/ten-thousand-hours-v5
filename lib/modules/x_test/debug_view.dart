import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/0_data_model/time_stamp.dart';
import 'package:ten_thousands_hours/modules/2_indices/indices_provider.dart';
import 'package:ten_thousands_hours/modules/3.2_data_providers.dart/current_status_provider.dart';

import '../1_time_record/time_record_provider.dart';
import '../3_days/relevent_days_provider.dart';
import '../3_days/today_record_provider.dart';
import '../4_statistics/today_duration_provider.dart';
import '../6_graphs/1_primary_graph/graph_view/pg_stack.dart';
import '../6_graphs/1_primary_graph/pg_other_day_points_provider.dart';
import '../6_graphs/1_primary_graph/pg_today_points_provider.dart';
import '../6_graphs/2_dur_graph/dur_graph_stack.dart';
import '../6_graphs/3_hour_distribution_graph/hd_stack.dart';

class DebugView extends ConsumerWidget {
  const DebugView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug View'),
        backgroundColor:
            ref.watch(latestTimeStampProvider).type == TPType.resume
                ? Colors.redAccent
                : Colors.white,
        actions: const [EventButton()],
      ),
      body: ListView(
        shrinkWrap: true,
        physics: const ScrollPhysics(),
        children: const [
          Text('Debug View'),
          CurrentDurationView(),
          // TodayRecordProviderDebugView(),
          // TodayDurationProviderDebugView(),
          // PGStackView(),
          HDStackView(),
          SizedBox(height: 10),
          DurGraphStack(),
          // IndicesProviderDebugView(),
          // TodayRecordProviderDebugView(),
          // TodayPrimaryGraphPointsProviderDebug(),
          // PgOtherDayPointsProviderDebugView(),
          // ReleventDaysProviderDebugView(),
          // TimeRecordProviderDebugView(),
        ],
      ),
    );
  }
}
