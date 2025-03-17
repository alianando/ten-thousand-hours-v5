import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_entry_entity/day_entry/day_services.dart';
import 'package:ten_thousands_hours/models/time_entry_entity/time_entry_provider/time_entry_provider.dart';

import '../time_entry_entity/day_entry/day_model.dart';
import 'indices_model.dart';

final todayEntryP = Provider<DayEntry>((ref) {
  final indices = ref.watch(indicesP.notifier);
  return indices.todayEntry;
});

final weekEntriesP = Provider<List<DayEntry>>((ref) {
  final indices = ref.watch(indicesP.notifier);
  return indices.weekEntries;
});

final monthEntriesP = Provider<List<DayEntry>>((ref) {
  final indices = ref.watch(indicesP.notifier);
  final monthEntries = indices.monthEntries;
  debugPrint('monthEntriesP');
  monthEntries.map((e) => debugPrint(e.toString()));
  return monthEntries;
});

final indicesP = NotifierProvider<IndicesNot, IndicesModel>(
  IndicesNot.new,
);

class IndicesNot extends Notifier<IndicesModel> {
  @override
  IndicesModel build() {
    final days = ref.watch(timeEntryP).days;
    if (days.isEmpty) {
      return const IndicesModel(
        todayIndex: -1,
        weekIndices: [],
        monthIndices: [],
      );
    }
    final now = DateTime.now();
    final weekStartDt = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    );
    int todayIndex = -1;
    List<int> weekIndices = [];
    List<int> monthIndices = [];
    days.sort((a, b) => a.dt.compareTo(b.dt));

    for (int i = days.length - 1; i >= 0; i--) {
      final dayDt = days[i].dt;
      if (dayDt.year != now.year || dayDt.month != now.month) {
        break;
      }
      monthIndices.add(i);
      if (dayDt.isAfter(weekStartDt)) {
        weekIndices.add(i);
      }
      if (dayDt.day == now.day) {
        todayIndex = i;
      }
    }

    return IndicesModel(
      todayIndex: todayIndex,
      weekIndices: weekIndices,
      monthIndices: monthIndices,
    );
  }

  // a method that returns todayEntry
  DayEntry get todayEntry {
    final days = ref.watch(timeEntryP).days;

    if (days.isEmpty || state.todayIndex == -1) {
      return DayModelService.createNewDay(DateTime.now());
    }
    return days[state.todayIndex];
  }

  // a method that returns weekEntries
  List<DayEntry> get weekEntries {
    final days = ref.watch(timeEntryP).days;
    return state.weekIndices.map((e) => days[e]).toList();
  }

  // a method that returns monthEntries
  List<DayEntry> get monthEntries {
    final days = ref.watch(timeEntryP).days;
    return state.monthIndices.map((e) => days[e]).toList();
  }
}
