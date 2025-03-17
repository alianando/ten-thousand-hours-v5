import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/indices_entry/indices_provider.dart';
import 'package:ten_thousands_hours/models/time_entry_entity/time_entry_provider/time_entry_provider.dart';
import 'package:ten_thousands_hours/providers/time_data_provider.dart';

import '../main.dart';
import '../models/coordinates_entry/continious_day_coo_entity/continious_day_coo_providers.dart';
import '../providers/ticker_provider.dart';

class TickerLayer extends ConsumerStatefulWidget {
  const TickerLayer({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TickerLayerState();
}

class _TickerLayerState extends ConsumerState<TickerLayer> {
  late Timer _updater;
  final int _interval = 1;

  void _startUpdater() {
    final ticker = ref.read(ticPro.notifier);
    _updater = Timer.periodic(Duration(seconds: _interval), (timer) {
      ticker.tic();
    });
  }

  @override
  void initState() {
    super.initState();
    _startUpdater();
  }

  @override
  void dispose() {
    _updater.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ticPro, (past, present) {
      // ref.read(timeDataPro.notifier).handelDtUpdate();
      // final todayPoints = ref.read(timeEntryP).days.first.events;
      // ref.read(continiousTodayCooPro.notifier).calculate(todayPoints);
    });
    ref.listen(indicesP, (past, present) {
      debugPrint('indicesP');
      debugPrint(present.toString());
    });
    ref.listen(continiousOtherDaysCooPro, (past, present) {
      debugPrint('continiousOtherDaysCooPro');
      debugPrint(present.toString());
    });
    return const MyApp();
  }
}
