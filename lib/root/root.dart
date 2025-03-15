import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ticker_layer.dart';

class _RootState extends ConsumerState<Root> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  Widget build(BuildContext context) {
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
