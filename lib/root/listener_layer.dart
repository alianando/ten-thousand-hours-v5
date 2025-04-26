import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/1_time_record/time_record_provider.dart';
import 'package:ten_thousands_hours/modules/2_indices/indices_provider.dart';
import 'package:ten_thousands_hours/providers/ticker_provider.dart';

import '../modules/3_days/relevent_days_provider.dart';
import '../modules/3_days/today_record_provider.dart';

class ReactiveLayer extends ConsumerWidget {
  final Widget child;
  const ReactiveLayer(this.child, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int tikP = 0;
    int tRPNum = 0;
    int iP = 0;
    int tP = 0;
    int rDP = 0;

    debugPrint('@@ [ReactiveLayer] $tRPNum $iP $tP $rDP');
    ref.listen(ticPro, (previous, next) {
      tikP = tikP + 1;
      debugPrint('## @@ [tickerProvider] $tikP sec');
    });
    ref.listen(timeRecordProvider, (previous, next) {
      tRPNum = tRPNum + 1;
      debugPrint('## @@ [timeRecordProvider] $tRPNum');
    });
    ref.listen(indicesProvider, (previous, next) {
      iP = iP + 1;
      debugPrint('## @@ [indicesProvider] $iP');
    });
    ref.listen(todayProvider, (previous, next) {
      tP = tP + 1;
      debugPrint('## @@ [todayProvider] $tP');
    });
    ref.listen(releventDaysProvider, (previous, next) {
      rDP = rDP + 1;
      debugPrint('## @@ [releventDaysProvider] $rDP');
    });
    return child;
  }
}
