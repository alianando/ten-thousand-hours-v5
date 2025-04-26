// ignore: file_names
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/0_data_model/day_record.dart';
import 'package:ten_thousands_hours/modules/0_data_model/time_stamp.dart';
import 'package:ten_thousands_hours/modules/3_days/today_record_provider.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';

import '../../../providers/ticker_provider.dart';
import 'hourly_distribution_services.dart';

final hdTodayCoordinateProvider = Provider<Map<int, double>>((ref) {
  final todayEntry = ref.watch(todayProvider);

  var todayTPs = todayEntry.timeStapms;
  final timeAt = ref.watch(ticPro);
  todayTPs = TimeStampService.insertTimePoint(todayTPs, timeAt, false);
  final output = HDServices.dayHourlyDurDistribution(
    todayEntry.copyWith(events: todayTPs),
  );
  return output;
});
