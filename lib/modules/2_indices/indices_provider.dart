import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/1_time_record/time_record_provider.dart';

import 'indices_model.dart';

final todayIndexProvider = Provider<int>((ref) {
  final indices = ref.watch(indicesProvider);
  return indices.todayIndex;
});

final weekIndicesProvider = Provider<List<int>>((ref) {
  final indices = ref.watch(indicesProvider);
  return indices.weekIndices;
});

final monthIndicesProvider = Provider<List<int>>((ref) {
  final indices = ref.watch(indicesProvider);
  return indices.monthIndices;
});

final relaventIndicesProvider = Provider<List<int>>((ref) {
  final indices = ref.watch(indicesProvider);
  final timeRecord = ref.watch(timeRecordProvider);

  return timeRecord.allDays
      .where(
        (day) => day.dt.isAfter(
          timeRecord.allDays.last.dt.subtract(const Duration(days: 15)),
        ),
      )
      .map((day) => timeRecord.days.indexOf(day))
      .toList();
});

final indicesProvider = NotifierProvider<IndicesNotifier, Indices>(
  IndicesNotifier.new,
);

class IndicesNotifier extends Notifier<Indices> {
  @override
  Indices build() {
    final days = ref.watch(timeRecordProvider).days;
    final now = DateTime.now();
    final weekStartDt = _getFirstDayOfWeek(now);
    final monthStartDt = DateTime(now.year, now.month, 1);

    int todayIndex = -1;
    final weekIndices = <int>[];
    final monthIndices = <int>[];

    for (int i = days.length - 1; i >= 0; i--) {
      final dt = days[i].dt;
      // if (dt.isBefore(monthStartDt)) {
      //   break;
      // }
      monthIndices.add(i);

      if (!dt.isBefore(weekStartDt)) {
        weekIndices.add(i);
      }
      if (_isSameDay(dt, now)) {
        todayIndex = i;
      }
    }
    // debugPrint('IndicesNotifier.build()');
    return Indices(
      todayIndex: todayIndex,
      weekIndices: weekIndices,
      monthIndices: monthIndices,
    );
  }

  // Helper to get the first day of the current week
  DateTime _getFirstDayOfWeek(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  // Check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

class IndicesProviderDebugView extends ConsumerWidget {
  const IndicesProviderDebugView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indices = ref.watch(indicesProvider);
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Indices:'),
          Text(' Today: ${indices.todayIndex}'),
          Text(' Week: ${indices.weekIndices}'),
          Text(' Month: ${indices.monthIndices}'),
        ],
      ),
    );
  }
}
