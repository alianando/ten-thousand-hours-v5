import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/models/time_entry.dart';
import 'package:ten_thousands_hours/providers/time_entry_provider.dart';

class Cor {
  final double x;
  final double y;
  final double z;
  final DateTime dt;
  final Duration dur;

  const Cor(
      {required this.x,
      required this.y,
      required this.z,
      required this.dt,
      this.dur = const Duration()});

  factory Cor.fromJson(Map<String, dynamic> json) {
    return Cor(
      x: json['x'],
      y: json['y'],
      z: json['z'],
      dt: DateTime.parse(json['dt']),
      dur: Duration(milliseconds: json['dur']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'dt': dt.toIso8601String(),
      'dur': dur.inMilliseconds,
    };
  }
}

class DayTotalDurCoordinates {
  final List<Cor> cors;
  // final double maxY;
  const DayTotalDurCoordinates({required this.cors});
}

class DayTotalDurCoordinatesNot extends Notifier<DayTotalDurCoordinates> {
  @override
  DayTotalDurCoordinates build() {
    return const DayTotalDurCoordinates(cors: []);
  }

  void handelDtUpdate({required DateTime dt, required bool sameDay}) async {
    if (sameDay == false) {
      calculateEverything();
    } else {
      final todayUpdatedCor = await calculatToDay();
      bool todayIsMax = false;
      for (final cor in state.cors) {
        if (cor.dur < todayUpdatedCor.dur) {
          todayIsMax = true;
        }
      }
      List<Cor> cors = List.from(state.cors);
      if (todayIsMax) {
        for (int i = 0; i < cors.length; i++) {
          final cor = state.cors[i];
          cors[i] = Cor(
            x: cor.x,
            y: cor.y / todayUpdatedCor.y,
            z: cor.z,
            dt: cor.dt,
            dur: cor.dur,
          );
        }
      }
      state = DayTotalDurCoordinates(cors: cors);
    }
  }

  void calculateEverything({bool debug = false}) async {
    final dt = DateTime.now();
    List<Cor> cors = [];
    bool done = false;
    int dayDistance = 0;
    while (!done) {
      if (dayDistance == 0) {
        final cor = await calculatToDay();
        cors.add(cor);
        continue;
      }
      final targetDay = dt.subtract(Duration(days: dayDistance));
      final events = await getEventsForDay(targetDay);
      if (events.isEmpty) {
        cors.add(
          Cor(
            x: dayDistance.toDouble(),
            y: 0,
            z: dayDistance.toDouble(),
            dt: targetDay,
            dur: const Duration(),
          ),
        );
        continue;
      }
      final lastEvent = events.last;
      if (lastEvent.resume == false) {
        cors.add(
          Cor(
            x: dayDistance.toDouble(),
            y: lastEvent.dayDur.inMilliseconds.toDouble(),
            z: dayDistance.toDouble(),
            dt: targetDay,
            dur: lastEvent.dayDur,
          ),
        );
        continue;
      }
      final dur = DateTime(
        targetDay.year,
        targetDay.month,
        targetDay.day,
        23,
        59,
        59,
      ).difference(lastEvent.dt);
      cors.add(
        Cor(
          x: dayDistance.toDouble(),
          y: dur.inMilliseconds.toDouble(),
          z: dayDistance.toDouble(),
          dt: targetDay,
          dur: dur,
        ),
      );
      if (targetDay.day == 1 && targetDay.month == dt.month) {
        done = true;
      }
      dayDistance++;
    }

    /// calculate the max y value
    double maxY = 0;
    for (final cor in cors) {
      if (cor.y > maxY) {
        maxY = cor.y;
      }
    }

    /// normalize the y value
    for (int i = 0; i < cors.length; i++) {
      final cor = cors[i];
      cors[i] = Cor(
        x: cor.x,
        y: cor.y / maxY,
        z: cor.z,
        dt: cor.dt,
        dur: cor.dur,
      );
    }
    if (debug) {
      debugPrint('cors: $cors');
    }
    state = DayTotalDurCoordinates(cors: cors);
  }

  Future<List<TimeEntry>> getEventsForDay(DateTime dt) async {
    final events = ref.read(timeEntriesForDayProvider(dt));
    events.when(data: (data) {
      return data;
    }, error: (error, statckSome) {
      debugPrint('error: at DayTotalDurCoordinatesNot.getEventsForDay()');
      debugPrint('error: $error');
    }, loading: () {
      debugPrint('loading: at DayTotalDurCoordinatesNot.getEventsForDay()');
    });
    return [];
  }

  Future<Cor> calculatToDay() async {
    final dur = ref.read(todayDurationProvider);
    dur.when(
      data: (data) {
        final durInMisiSec = data.inMilliseconds;
        return Cor(
          x: 0,
          y: durInMisiSec.toDouble(),
          z: 0,
          dt: DateTime.now(),
          dur: data,
        );
      },
      error: (error, stackTrace) {
        debugPrint(
          'error: at DayTotalDurCoordinatesNot.calculateDayTotalDur()',
        );
        debugPrint('error: $error');
      },
      loading: () {
        debugPrint(
          'loading: at DayTotalDurCoordinatesNot.calculateDayTotalDur()',
        );
      },
    );
    return Cor(x: 0, y: 0, z: 0, dt: DateTime.now(), dur: const Duration());
  }
}

// final dayTotalDurCoordinatesProvider =
//     NotifierProvider<DayTotalDurCoordinatesNot, DayTotalDurCoordinates>(
//   DayTotalDurCoordinatesNot.new,
// );
