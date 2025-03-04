import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:ten_thousands_hours/models/time_data/model/time_data.dart';
import 'package:ten_thousands_hours/views/home_page/current_time_point.dart';
import 'package:ten_thousands_hours/views/home_page/event_button.dart';
import 'package:ten_thousands_hours/views/home_page/month_view.dart';
import 'package:ten_thousands_hours/views/home_page/today_events_listview.dart';

import '../../models/time_data/model/time_point.dart';
import '../../providers/time_data_provider.dart';
import 'all_days_listview.dart';
import 'main_graph.dart';
import 'week_data.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('10,000 Hours'),
        actions: [
          IconButton(
            onPressed: () {
              final data = ref.read(timeDataProvider);
              final logger = Logger();
              logger.d(data.toJson());
              final updatedData = TimeDataServices.recalculate(data);
              logger.d(updatedData.toJson());
              ref.read(timeDataProvider.notifier).saveTimeData(updatedData);
              ref.read(timeDataProvider.notifier).setNewData(updatedData);
            },
            icon: const Icon(Icons.lock_reset),
          ),
          const EventButton(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            shrinkWrap: true,
            physics: const ScrollPhysics(),
            children: const [
              GraphButtons(),
              GraphStack(),
              SizedBox(height: 20),
              CurrentTimePoint(),
              WeekData(),
              MonthView(),
              // TodayEventsListview(),
              // AllDaysListview(),
              // Misellinious(),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveEventButton extends ConsumerWidget {
  const ActiveEventButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeData = ref.read(timeDataProvider);
    final active = timeData.today.events.last.typ == TimePointTyp.resume;
    return IconButton(
      onPressed: () {
        ref.read(timeDataProvider.notifier).addTimePoint(dt: DateTime.now());
      },
      icon: active ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
    );
  }
}

class Misellinious extends ConsumerWidget {
  const Misellinious({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      children: [
        const Center(child: Text('Misellinious')),
        ElevatedButton(
          onPressed: () {
            final timeJson = ref.read(timeDataProvider).toJson();
          },
          child: const Text('Print Time Data Json'),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(timeDataProvider.notifier).saveTimeData(
                  TimeData.fromJson(exampleData),
                );
            // final output = TimeLogic.ticDifferentDay(
            //   oldData: TimeData.fromJson(exampleData),
            //   tic: DateTime.now(),
            // );
            // debugPrint(output.days.length.toString());
            // debugPrint(
            //   output.days[output.statData.todayIndex].lastUpdate.toString(),
            // );
          },
          child: const Text('Debug'),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(timeDataProvider.notifier).clearData();
          },
          child: const Text('Clear Data'),
        ),
      ],
    );
  }
}
