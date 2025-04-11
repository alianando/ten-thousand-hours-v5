import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/3_days/relevent_days_provider.dart';
import 'package:ten_thousands_hours/modules/6_graphs/3_hour_distribution_graph/hourly_distribution_services.dart';

// final avgHDistributionProvider =
//     FutureProvider.autoDispose<Map<double, double>>((ref) async {
//   final pastDays = ref.watch(releventDaysProvider);
//   final output = HDServices.avgHourlyDurDistribution(pastDays);
//   final normalizedOutput = HDServices.normalizedDistribution(output);

//   return normalizedOutput;
// });

final avgHDistributionProvider = Provider((ref) {
  final pastDays = ref.watch(releventDaysProvider);
  if (pastDays.isEmpty) {
    return <double, double>{};
  }
  final output = HDServices.avgHourlyDurDistribution(pastDays);
  final normalizedOutput = HDServices.normalizedDistribution(output);
  debugPrint('avgHDistributionProvider.build()');
  // debugPrint('avgHDistributionProvider: $normalizedOutput');
  // return <double, double>{};

  return normalizedOutput;
});
