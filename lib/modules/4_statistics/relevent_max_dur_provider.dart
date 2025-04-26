import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../3_days/relevent_days_provider.dart';
import 'today_duration_provider.dart';

final releventMaxDurProvider = Provider<Duration>((ref) {
  final otherReleventDays = ref.watch(releventDaysProvider);
  final todayDur = ref.watch(todayDurProvider);
  Duration maxDur = todayDur;
  for (final day in otherReleventDays) {
    if (day.lastRecordedDur > maxDur) {
      maxDur = day.lastRecordedDur;
    }
  }
  if (maxDur == Duration.zero) {
    return const Duration(milliseconds: 1);
  }
  return maxDur;
});
