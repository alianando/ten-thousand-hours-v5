import 'package:flutter_riverpod/flutter_riverpod.dart';

final ticPro = NotifierProvider<TickerNot, DateTime>(TickerNot.new);

class TickerNot extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void tic() {
    state = DateTime.now();
  }
}
