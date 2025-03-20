import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/6_graphs/3_hour_distribution_graph/hourly_distribution_services.dart';

import '../../5_coordinates/c.dart';
import '../1_primary_graph/pg_other_day_points_provider.dart';

final todayHdProvider = Provider<Map<double, double>>((ref) {
  final cooList = ref.watch(pgOtherDayPointsProvider);
  if (cooList.isEmpty) {
    return {};
  }
  // List<C> coordinates = cooList.last;
  List<C> coordinates = cooList[cooList.length - 6];
  // if (cooList.length >= 2) {
  //   coordinates = cooList[cooList.length - 4];
  // }
  debugPrint('Today_HourlyDistibution_Provider.dart');
  final val = HDServices.getHourlyDistribution(coordinates, debug: true);
  return val;
});
