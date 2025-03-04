import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/providers/storage_pro.dart';
import 'package:ten_thousands_hours/providers/time_data_provider.dart';

import 'package:ten_thousands_hours/root/ticker_layer.dart';

import '../utils/dt_utils.dart';

class _RootState extends ConsumerState<Root> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.read(timeDataProvider.notifier).testinit();
      ref.read(timeDataProvider.notifier).init();
      // localStorageCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    // final logger = Logger();
    ref.listen(timeDataProvider, (pre, next) {
      // debugPrint(next.today.coordinates.last.dx.toString());
      // logger.d(next.days[next.statData.todayIndex].toJson());
      // debugPrint(
      //   '${next.days[next.statData.todayIndex].coordinates.last.dx}',
      // );
      // final String dataString = jsonEncode(next.toJson());
      // debugPrint(
      //   '${DateTime.now()} :${next.days[next.statData.todayIndex].coordinates.last.dx}',
      // );
    });
    // ref.listen(appDataProvider, (previous, next) {
    //   final String dataString = jsonEncode(next.toJson());
    //   ref.read(storageProvider).updateAppState(dataString);
    //   // debugPrint(dataString);
    // });
    // ref.listen(todayDataPro, (pre, next) {
    //   if (next.lastUpdate == DateTime(1999)) {
    //     //* this means today data is not updated from.
    //     return;
    //   }
    //   if (next.lastUpdate.isAfter(ref.read(appDataProvider).lastUpdate)) {
    //     ref.read(appDataProvider.notifier).updateToday(next);
    //   }
    // });
    return const TickerLayer();
  }
}

class Root extends ConsumerStatefulWidget {
  const Root({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RootState();
}
