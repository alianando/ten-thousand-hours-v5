import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/1_time_record/time_record_provider.dart';

// ignore: non_constant_identifier_names
final hourly_distribution_day_index_provider =
    NotifierProvider<hourly_distribution_day_index_notifier, int>(
        hourly_distribution_day_index_notifier.new);

// ignore: camel_case_types
class hourly_distribution_day_index_notifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void increase() async {
    bool keepChanging = true;
    while (keepChanging) {
      final increased = state + 1;
      final days = ref.read(timeRecordProvider).days;
      if (increased >= days.length) {
        state = days.length - 1;
        keepChanging = false;
      } else {
        state = increased;
        await Future.delayed(const Duration(seconds: 1), () {});
      }
    }
  }
}
