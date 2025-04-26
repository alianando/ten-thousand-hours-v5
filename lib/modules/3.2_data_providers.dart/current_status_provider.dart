import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../0_data_model/time_stamp.dart';
import '../3_days/today_record_provider.dart';

final latestTimeStampProvider = Provider<TimeStamp>((ref) {
  final today = ref.watch(todayProvider);
  return today.lastTimeStapm;
});

// true if the last time stamp is a resume type
// false if the last time stamp is a pause type
final status = Provider<bool>((ref) {
  final today = ref.watch(todayProvider);
  return today.lastTimeStapm.typ == TPType.resume;
});
