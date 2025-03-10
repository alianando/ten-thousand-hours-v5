import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/mock_data.dart';
import 'package:ten_thousands_hours/providers/time_data_provider.dart';
import 'package:ten_thousands_hours/providers/record_provider.dart';

import 'package:ten_thousands_hours/root/ticker_layer.dart';

class _RootState extends ConsumerState<Root> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.read(timeEntryProvider.notifier).updateEntry(
      //       const MockData().mockTimeEntry,
      //     );
      // ref.read(timeEntryProvider.notifier).init();
      ref.read(timeDataPro.notifier).initTimeData(debug: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(timeDataPro, (previous, current) {
      // debugPrint(current.indices.monthIndices.toString());
      // debugPrint('AppData changed: ${current.dayEntries.length}');
      // current.printAppData();
    });
    return const TickerLayer();
  }
}

class Root extends ConsumerStatefulWidget {
  const Root({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RootState();
}

void pout(String message, bool debug, {int level = 0}) {
  if (debug) {
    String space = '';
    for (int i = 0; i < level; i++) {
      space += '  ';
    }
    debugPrint('$space$message');
  }
}
