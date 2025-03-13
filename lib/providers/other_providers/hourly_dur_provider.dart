import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/app_data/coordinates/hourly_dur_distribution.dart';
import 'package:ten_thousands_hours/widgets/hourly_dur_distribution.dart';

import '../time_data_provider.dart';

final hourlyDurProvider = Provider<HourlyDurDistributionModel>((ref) {
  final timeData = ref.watch(timeDataPro);
  debugPrint(
    'hourlyDurProvider: ${timeData.coordinates.hourlyDurDistribution.avgDurSet}',
  );
  return timeData.coordinates.hourlyDurDistribution;
});
