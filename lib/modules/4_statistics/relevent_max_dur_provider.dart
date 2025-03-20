import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../3_days/relevent_days_provider.dart';
import 'today_duration_provider.dart';

final releventMaxDurProvider = Provider<Duration>((ref) {
  final otherReleventDays = ref.watch(releventDaysProvider);
  final todayDur = ref.watch(todayDurProvider);
  Duration maxDur = todayDur;
  for (final day in otherReleventDays) {
    if (day.durPoint.dur > maxDur) {
      maxDur = day.durPoint.dur;
    }
  }
  return maxDur;
});
