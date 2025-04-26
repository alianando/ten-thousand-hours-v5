import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/1_time_record/time_record_provider.dart';

import 'listener_layer.dart';
import 'ticker_layer.dart';

class _RootState extends ConsumerState<Root> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.read(timeEntryP.notifier).retrieveTimeEntry(debug: true);
      ref.read(timeRecordProvider.notifier).retrieveRecord(debug: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // return const TickerLayer();
    return ReactiveLayer(const TickerLayer());
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
