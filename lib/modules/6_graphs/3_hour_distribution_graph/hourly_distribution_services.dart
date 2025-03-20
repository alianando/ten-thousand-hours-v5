import 'package:ten_thousands_hours/root/root.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';

import '../../5_coordinates/c.dart';

class HDServices {
  const HDServices._();
  static final dayStart = DateTime(1999, 3, 3);
  static final dayEnd = DtHelper.dayEndDt(dayStart);
  static final xRange = dayEnd.difference(dayStart).inMilliseconds;

  static Map<int, double> hourlyXval = {
    1: const Duration(hours: 1).inMilliseconds / xRange,
    2: const Duration(hours: 2).inMilliseconds / xRange,
    3: const Duration(hours: 3).inMilliseconds / xRange,
    4: const Duration(hours: 4).inMilliseconds / xRange,
    5: const Duration(hours: 5).inMilliseconds / xRange,
    6: const Duration(hours: 6).inMilliseconds / xRange,
    7: const Duration(hours: 7).inMilliseconds / xRange,
    8: const Duration(hours: 8).inMilliseconds / xRange,
    9: const Duration(hours: 9).inMilliseconds / xRange,
    10: const Duration(hours: 10).inMilliseconds / xRange,
    11: const Duration(hours: 11).inMilliseconds / xRange,
    12: const Duration(hours: 12).inMilliseconds / xRange,
    13: const Duration(hours: 13).inMilliseconds / xRange,
    14: const Duration(hours: 14).inMilliseconds / xRange,
    15: const Duration(hours: 15).inMilliseconds / xRange,
    16: const Duration(hours: 16).inMilliseconds / xRange,
    17: const Duration(hours: 17).inMilliseconds / xRange,
    18: const Duration(hours: 18).inMilliseconds / xRange,
    19: const Duration(hours: 19).inMilliseconds / xRange,
    20: const Duration(hours: 20).inMilliseconds / xRange,
    21: const Duration(hours: 21).inMilliseconds / xRange,
    22: const Duration(hours: 22).inMilliseconds / xRange,
    23: const Duration(hours: 23).inMilliseconds / xRange,
    24: 1,
  };
  static Map<double, double> getHourlyDistribution(
    List<C> coordinates, {
    bool debug = false,
  }) {
    pout('Generate Hourly Distribution', debug, level: 2);
    Map<double, double> output = {};
    int hourConsidering = 1;
    for (int i = 0; i < coordinates.length - 1; i++) {
      // pout('Loop $i', debug, level: 3);
      final first = coordinates[i];
      final second = coordinates[i + 1];
      // pout('x: ${first.x} - ${second.x}', debug, level: 4);
      bool moveToNext = false;

      while (!moveToNext) {
        // pout('hour : $hourConsidering', debug, level: 4);
        final targetX = hourlyXval[hourConsidering];
        // pout('targetX: $targetX', debug, level: 4);
        if (targetX == first.x) {
          output[targetX!] = first.y;
          hourConsidering++;
        } else if (targetX! < second.x) {
          if (first.y == second.y) {
            /// this session is unactive.
            output[targetX] = first.y;
            hourConsidering++;
          } else {
            /// active session.
            final fraction = (targetX - first.x) / (second.x - first.x);
            double y = (second.y - first.y) * fraction;
            output[targetX] = first.y;
            hourConsidering++;
          }
        } else {
          moveToNext = true;
        }
        // hourConsidering++;
        // if (hourConsidering == 24) {
        //   moveToNext = true;
        // }
      }
      if (hourConsidering >= 24) {
        break;
      }
    }
    pout('output $output', debug, level: 2);
    return output;
  }
}
