import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/providers/time_data_provider.dart';

import 'package:ten_thousands_hours/root/ticker_layer.dart';

class _RootState extends ConsumerState<Root> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.read(timeDataProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(timeDataProvider, (pre, next) {});
    return const TickerLayer();
  }
}

class Root extends ConsumerStatefulWidget {
  const Root({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RootState();
}
