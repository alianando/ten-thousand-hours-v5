import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ten_thousands_hours/modules/1_time_record/time_record_provider.dart';
import 'package:ten_thousands_hours/modules/1_time_record/time_stamp.dart';
import 'package:ten_thousands_hours/modules/6_graphs/3_hour_distribution_graph/dh_day_index_provider.dart';
import 'package:ten_thousands_hours/root/root.dart';

/// Provider that calculates how much time was spent during each hour of the day
final dayHourDurationProvider = Provider((ref) {
  const bool debug = false;
  pout('dayHourDurationProvider.build()', debug);
  // Get the most recent day from the time record
  final days = ref.watch(timeRecordProvider).days;

  // Ensure we have at least one day
  if (days.isEmpty) {
    pout('dayHourDurationProvider = <int, Duration>{}', debug);
    return <int, Duration>{};
  }
  final index = ref.watch(hourly_distribution_day_index_provider);
  final targetDayIndex = index;
  var day = days.first;
  if (targetDayIndex < days.length) {
    day = days[targetDayIndex]; // Get the most recent day
  }

  // Initialize hourly durations map (hours 0-23)
  var hourlyDurations = <int, Duration>{};
  for (int hour = 0; hour < 24; hour++) {
    hourlyDurations[hour] = Duration.zero;
  }

  // If there are fewer than 2 events, we can't calculate any durations
  if (day.events.length < 2) {
    return hourlyDurations;
  }

  // Sort events chronologically to ensure correct processing
  final sortedEvents = List<TimeStamp>.from(day.events)
    ..sort((a, b) => a.dt.compareTo(b.dt));

  // Track the start time of the current tracking session
  DateTime? startTime;

  // Process each event
  for (int i = 0; i < sortedEvents.length; i++) {
    final event = sortedEvents[i];

    if (event.typ == TPType.resume) {
      // Start tracking session
      startTime = event.dt;
    } else if (event.typ == TPType.pause && startTime != null) {
      // End tracking session - calculate duration for each hour
      final endTime = event.dt;

      // Process time in one-hour chunks
      var currentTime = startTime;
      while (currentTime.isBefore(endTime)) {
        // Calculate the end of this hour or the end time, whichever comes first
        final hourEndTime = DateTime(
          currentTime.year,
          currentTime.month,
          currentTime.day,
          currentTime.hour,
          59,
          59,
          999,
        );

        final chunkEndTime =
            endTime.isBefore(hourEndTime) ? endTime : hourEndTime;

        // Calculate duration for this chunk
        final chunkDuration = chunkEndTime.difference(currentTime);

        // Add to the appropriate hour bucket
        final hour = currentTime.hour;
        hourlyDurations[hour] = Duration(
          milliseconds: hourlyDurations[hour]!.inMilliseconds +
              chunkDuration.inMilliseconds,
        );

        // Move to the next hour
        currentTime = hourEndTime.add(const Duration(milliseconds: 1));
      }

      // Reset start time for next session
      startTime = null;
    }
  }

  // Handle case where the last event is a resume (still tracking)
  if (startTime != null) {
    final endTime = DateTime.now();

    // Process time in one-hour chunks (same logic as above)
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

      final chunkEndTime =
          endTime.isBefore(hourEndTime) ? endTime : hourEndTime;

      final chunkDuration = chunkEndTime.difference(currentTime);

      final hour = currentTime.hour;
      hourlyDurations[hour] = Duration(
        milliseconds: hourlyDurations[hour]!.inMilliseconds +
            chunkDuration.inMilliseconds,
      );

      currentTime = hourEndTime.add(const Duration(milliseconds: 1));
    }
  }
  pout(sortedEvents.toString(), debug);
  pout('$hourlyDurations', debug);
  return hourlyDurations;
});
