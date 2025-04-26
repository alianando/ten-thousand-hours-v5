import 'package:flutter/cupertino.dart';
import 'package:ten_thousands_hours/modules/0_data_model/day_record.dart';
import 'package:ten_thousands_hours/root/root.dart';
import 'package:ten_thousands_hours/utils/dt_utils.dart';

import '../../0_data_model/time_stamp.dart';
import '../../5_coordinates/c.dart';

class HDServices {
  const HDServices._();
  static final dayStart = DateTime(1999, 3, 3);
  static final dayEnd = DtHelper.dayEndDt(dayStart);
  static final dayDurInMiliSec = dayEnd.difference(dayStart).inMilliseconds;

  static Map<int, double> normalizedHourVal = {
    0: 0.0,
    1: const Duration(hours: 1).inMilliseconds / dayDurInMiliSec,
    2: const Duration(hours: 2).inMilliseconds / dayDurInMiliSec,
    3: const Duration(hours: 3).inMilliseconds / dayDurInMiliSec,
    4: const Duration(hours: 4).inMilliseconds / dayDurInMiliSec,
    5: const Duration(hours: 5).inMilliseconds / dayDurInMiliSec,
    6: const Duration(hours: 6).inMilliseconds / dayDurInMiliSec,
    7: const Duration(hours: 7).inMilliseconds / dayDurInMiliSec,
    8: const Duration(hours: 8).inMilliseconds / dayDurInMiliSec,
    9: const Duration(hours: 9).inMilliseconds / dayDurInMiliSec,
    10: const Duration(hours: 10).inMilliseconds / dayDurInMiliSec,
    11: const Duration(hours: 11).inMilliseconds / dayDurInMiliSec,
    12: const Duration(hours: 12).inMilliseconds / dayDurInMiliSec,
    13: const Duration(hours: 13).inMilliseconds / dayDurInMiliSec,
    14: const Duration(hours: 14).inMilliseconds / dayDurInMiliSec,
    15: const Duration(hours: 15).inMilliseconds / dayDurInMiliSec,
    16: const Duration(hours: 16).inMilliseconds / dayDurInMiliSec,
    17: const Duration(hours: 17).inMilliseconds / dayDurInMiliSec,
    18: const Duration(hours: 18).inMilliseconds / dayDurInMiliSec,
    19: const Duration(hours: 19).inMilliseconds / dayDurInMiliSec,
    20: const Duration(hours: 20).inMilliseconds / dayDurInMiliSec,
    21: const Duration(hours: 21).inMilliseconds / dayDurInMiliSec,
    22: const Duration(hours: 22).inMilliseconds / dayDurInMiliSec,
    23: const Duration(hours: 23).inMilliseconds / dayDurInMiliSec,
    24: 1,
  };

  /// Calculates the duration spent during each hour of the day
  ///
  /// @param day The DayEntry containing TimeStamp events
  /// @param debug Optional flag to enable debugging output
  /// @return Map where keys are hours (0-23) and values are normalized durations (0.0-1.0)
  static Map<int, double> dayHourlyDurDistribution(
    DayEntry day, {
    bool debug = false,
  }) {
    pout('Calculate hourly duration distribution', debug, level: 1);

    // Initialize output map with zeros for all 24 hours.
    Map<int, double> output = {};
    for (int hour = 0; hour < 24; hour++) {
      output[hour] = 0.0;
    }

    // Get a copy of events that are sorted and filtered to this day only
    // final events = List<TimeStamp>.from(day.events)
    //   ..sort((a, b) => a.dt.compareTo(b.dt));
    final events = day.timeStapms;

    // Skip calculation if we have fewer than 2 events
    if (events.length < 2) {
      pout('Not enough events to calculate distribution', debug, level: 2);
      return output;
    }

    // Process events to find active periods
    TimeStamp? lastResumeEvent;
    const oneHour = Duration(minutes: 59, seconds: 59, milliseconds: 999);
    final oneHourInMillis = oneHour.inMilliseconds;
    // final oneHourInMillis = const Duration(hours: 1).inMilliseconds;

    for (int i = 0; i < events.length; i++) {
      final currentEvent = events[i];

      // When we find a resume event, mark the start of an active period
      if (lastResumeEvent == null && currentEvent.isResume) {
        lastResumeEvent = currentEvent;
      }
      // When we find a pause after a resume, calculate the active duration
      else if (currentEvent.type == TPType.pause && lastResumeEvent != null) {
        final startTime = lastResumeEvent.dt;
        final endTime = currentEvent.dt;

        // Process this active period hour by hour
        var currentTime = startTime;
        while (currentTime.isBefore(endTime)) {
          // Calculate the end of the current hour
          final hourEndTime = DateTime(
            currentTime.year,
            currentTime.month,
            currentTime.day,
            currentTime.hour,
            59,
            59,
            999,
          );

          // Determine the end of this segment (either end of hour or end of active period)
          final segmentEnd =
              endTime.isBefore(hourEndTime) ? endTime : hourEndTime;

          // Calculate duration of this segment
          final segmentDuration = segmentEnd.difference(currentTime);

          // Add to the appropriate hour bucket
          final hour = currentTime.hour;
          final normalizedDuration =
              segmentDuration.inMilliseconds / oneHourInMillis;

          // Add to existing value (accumulate if multiple active periods in same hour)
          output[hour] = (output[hour] ?? 0.0) + normalizedDuration;

          // Cap at 1.0 (full hour)
          if (output[hour]! > 1.0) {
            output[hour] = 1.0;
          }

          // Move to the start of next hour
          currentTime = hourEndTime.add(const Duration(milliseconds: 1));

          // Break if we've reached the end of the active period
          if (currentTime.isAfter(endTime)) {
            break;
          }
        }

        // Reset for next active period
        lastResumeEvent = null;
      }
    }

    // Handle case where the last event is a resume (ongoing tracking)
    if (lastResumeEvent != null) {
      final startTime = lastResumeEvent.dt;
      final endTime = DateTime.now();

      // Only process if the ongoing session is on the same day
      if (startTime.year == endTime.year &&
          startTime.month == endTime.month &&
          startTime.day == endTime.day) {
        // Same hour-by-hour processing as above
        var currentTime = startTime;
        while (currentTime.isBefore(endTime)) {
          final hourEndTime = DateTime(
            currentTime.year,
            currentTime.month,
            currentTime.day,
            currentTime.hour,
            59,
            59,
            999,
          );

          final segmentEnd =
              endTime.isBefore(hourEndTime) ? endTime : hourEndTime;

          final segmentDuration = segmentEnd.difference(currentTime);

          final hour = currentTime.hour;
          final normalizedDuration =
              segmentDuration.inMilliseconds / oneHourInMillis;

          output[hour] = (output[hour] ?? 0.0) + normalizedDuration;

          // Cap at 1.0
          if (output[hour]! > 1.0) {
            output[hour] = 1.0;
          }

          currentTime = hourEndTime.add(const Duration(milliseconds: 1));

          if (currentTime.isAfter(endTime)) {
            break;
          }
        }
      }
    }

    // Debug output
    if (debug) {
      for (int hour = 0; hour < 24; hour++) {
        final minutes = (output[hour]! * 60).round();
        pout(
            'Hour $hour: ${minutes.toString().padLeft(2, '0')} minutes (${output[hour]})',
            debug,
            level: 3);
      }
    }

    return output;
  }

  static Map<int, double> avgHourlyDurDistribution(List<DayEntry> days) {
    Map<int, double> output = {};
    for (int hour = 0; hour < 24; hour++) {
      output[hour] = 0.0;
    }
    for (final day in days) {
      final dayDist = dayHourlyDurDistribution(day);
      for (int hour = 0; hour < 24; hour++) {
        output[hour] = output[hour]! + dayDist[hour]!;
      }
    }
    for (int hour = 0; hour < 24; hour++) {
      output[hour] = output[hour]! / days.length;
    }
    return output;
  }

  static Map<double, double> normalizedDistribution(Map<int, double> input) {
    Map<double, double> output = {};
    // debugPrint('normalizedDistribution input: $input');
    for (int hour = 0; hour < 24; hour++) {
      // debugPrint(
      //   'hour: $hour, normalizedHourVal[hour]: ${normalizedHourVal[hour]}, input[hour]: ${input[hour]}',
      // );
      output[normalizedHourVal[hour]!] = input[hour]!;
    }
    return output;
  }

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
        final targetX = normalizedHourVal[hourConsidering];
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
