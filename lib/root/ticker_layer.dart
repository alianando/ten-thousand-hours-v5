import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/coordinates/coordinates_model.dart';
import 'package:ten_thousands_hours/providers/time_entry/tme_entry_db_pro.dart';

import '../main.dart';
import '../providers/tic_provider.dart';

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
      // ref.read(dayTotalDurCoordinatesProvider.notifier).handelDtUpdate(
      //       dt: present,
      //       sameDay: false,
      //     );
    });
    ref.listen(timeEntryControllerProvider, (past, present) {
      if (present.hasValue) {
        ref.read(timeEntryLastUpdatedP.notifier).updateTime();
      }
      // ref.read(dayTotalDurCoordinatesProvider.notifier).handelDtUpdate(
      //       dt: present,
      //       sameDay: false,
      //     );
    });
    return const MyApp();
  }
}
