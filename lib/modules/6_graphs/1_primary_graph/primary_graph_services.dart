import 'package:flutter/material.dart';

import '../../../utils/dt_utils.dart';
import '../../1_time_record/time_stamp.dart';
import '../../5_coordinates/c.dart';

class PrimaryGraphService {
  const PrimaryGraphService._();

  static List<C> generateCoordinates({
    required List<TimeStamp> timePoints,
    required DateTime sessionStartTime,
    required DateTime sessionEndTime,
    required Duration maxSessionDur,
    required Duration minSessionDur,
    double z = 0,
    bool debug = false,
  }) {
    if (timePoints.isEmpty) {
      return [];
    }

    // Ensure session end is after start
    if (sessionEndTime.isBefore(sessionStartTime)) {
      final temp = sessionStartTime;
      sessionStartTime = sessionEndTime;
      sessionEndTime = temp;
    }

    final sessionStartDt = DtHelper.correctDt(
      sessionStartTime,
      timePoints.isNotEmpty ? timePoints.first.dt : DateTime.now(),
    );

    // Ensure there's at least a minimum duration
    final sessionDur = sessionEndTime.difference(sessionStartTime);
    final sessionDurInMilliseconds = sessionDur.inMilliseconds <= 0
        ? const Duration(seconds: 1).inMilliseconds
        : sessionDur.inMilliseconds;

    if (debug) {
      debugPrint('## -- sessionDurInMilliseconds: $sessionDurInMilliseconds');
    }

    return timePoints
        .map((point) => generateCoordinate(
              point: point,
              correctedSesStartDt: sessionStartDt,
              sessionDurInMillisec: sessionDurInMilliseconds,
              maxDur: maxSessionDur,
              minDur: minSessionDur,
              z: z,
              debug: debug,
            ))
        .whereType<C>()
        .toList();
  }

  /// Generates a single coordinate for visualization
  static C? generateCoordinate({
    required TimeStamp point,
    required DateTime correctedSesStartDt,
    required int sessionDurInMillisec,
    required Duration maxDur,
    required Duration minDur,
    double z = 0,
    bool debug = false,
  }) {
    if (debug) {
      debugPrint('## -- at: ${point.dt}');
    }
    final timeDiffInMillisec =
        point.dt.difference(correctedSesStartDt).inMilliseconds;
    if (debug) {
      debugPrint('## -- timeDiffInMilliseconds: $timeDiffInMillisec');
    }

    final x = timeDiffInMillisec / sessionDurInMillisec;
    if (debug) {
      debugPrint('## -- x: $x');
    }
    // Only generate coordinates within the session timeframe
    if (x >= 0 && x <= 1) {
      // Prevent division by zero and handle edge cases
      final denominator = (maxDur - minDur).inMilliseconds.abs();
      if (debug) {
        debugPrint(
            '## -- maxDur: $maxDur, minDur: $minDur, denominator: $denominator');
      }
      if (debug) {
        debugPrint('## -- point.dur.inSeconds: ${point.dur}');
      }
      final y = denominator > 0
          ? point.dur.inMilliseconds / denominator
          : point.dur.inMilliseconds > 0
              ? 1.0
              : 0.0;

      if (debug) {
        debugPrint('## -- : [$x, $y]');
      }
      return C(x, y, z);
    }
    if (debug) {
      debugPrint('## -- [null]');
    }
    return null;
  }
}
