// ignore_for_file: file_names

import '../../utils/dt_utils.dart';

enum TPType {
  pause,
  resume,
}

class TimeStamp {
  final DateTime dt;
  final Duration dur;
  final TPType typ;

  const TimeStamp(this.dt, this.dur, this.typ);

  factory TimeStamp.fromJson(Map<String, dynamic> json) {
    return TimeStamp(
      DateTime.parse(json['dt']),
      Duration(seconds: json['dur']),
      json['type'] == 'pause' ? TPType.pause : TPType.resume,
    );
  }

  DateTime get date => dt;
  Duration get duration => dur;
  TPType get type => typ;

  Map<String, dynamic> toJson() {
    return {
      'dt': dt.toIso8601String(),
      'dur': dur.inSeconds,
      'type': typ == TPType.pause ? 'pause' : 'resume',
    };
  }

  @override
  String toString() {
    final hour =
        (dt.hour > 12 ? dt.hour - 12 : dt.hour).toString().padLeft(2, '0');
    final String timeFormat =
        '$hour:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    final String durationFormat =
        dur.inMinutes > 0 ? '${dur.inMinutes} min' : '${dur.inSeconds} sec';
    final String typeString = typ == TPType.pause ? 'pause' : 'resume';

    return '[$timeFormat, $durationFormat, $typeString ]';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeStamp &&
          runtimeType == other.runtimeType &&
          dt == other.dt &&
          dur == other.dur &&
          typ == other.typ;

  @override
  int get hashCode => dt.hashCode ^ dur.hashCode ^ typ.hashCode;
}

class TimeStampService {
  static TimeStamp pauseTS(DateTime dt, Duration dur) {
    return TimeStamp(dt, dur, TPType.pause);
  }

  static TimeStamp resumeTS(DateTime dt, Duration dur) {
    return TimeStamp(dt, dur, TPType.resume);
  }

  /// Returns a new sorted list with the target TimePoint inserted.
  /// The date part of timeAt is corrected to match the reference date from points.
  ///
  /// @param points The existing list of time points
  /// @param timeAt The time at which to insert a new point
  /// @param isActivePoint Whether to toggle the activity type from the previous point
  /// @return A new list with the time point inserted in the correct position
  static List<TimeStamp> insertTimePoint(
    List<TimeStamp> points,
    DateTime timeAt,
    bool isActivePoint,
  ) {
    // Handle empty list case
    if (points.isEmpty) {
      return [pauseTS(timeAt, Duration.zero)];
    }

    // Correct the date part of timeAt to match the reference date
    final correctedDt = DtHelper.correctDt(timeAt, points.first.dt);

    // Early return if this time already exists in the list
    final existingPoint = points.firstWhere(
      (p) => p.dt.isAtSameMomentAs(correctedDt),
      orElse: () => TimeStamp(DateTime(1970), Duration.zero, TPType.pause),
    );

    if (existingPoint.dt.year != 1970) {
      return points;
    }

    // Find the insertion point (the latest point before correctedDt)
    final insertAfterIndex = points.lastIndexWhere(
      (p) => correctedDt.isAfter(p.dt),
    );

    // If no suitable insertion point found, return original list
    if (insertAfterIndex < 0) {
      return points;
    }

    final previousPoint = points[insertAfterIndex];

    // Calculate new duration based on previous point
    final newDuration = previousPoint.typ == TPType.resume
        ? previousPoint.dur + correctedDt.difference(previousPoint.dt)
        : previousPoint.dur;

    // Determine type based on previous point and isActivePoint flag
    final newType = isActivePoint
        ? (previousPoint.typ == TPType.resume ? TPType.pause : TPType.resume)
        : previousPoint.typ;

    // Create new point with calculated values
    final newPoint = TimeStamp(correctedDt, newDuration, newType);

    // Create new list and insert at the correct position
    final result = List<TimeStamp>.from(points);
    result.insert(insertAfterIndex + 1, newPoint);

    // Return the sorted list
    return result;
  }

  /// Computes the effective time point at a specific moment in time.
  /// If an exact match exists in the events list, that point is returned.
  /// Otherwise, a new hypothetical time point is created based on the latest event.
  ///
  /// @param events The list of time points to use for calculation
  /// @param timeAt The time at which to determine the effective time point
  /// @return The effective time point at the specified time
  static TimeStamp getEffectivePointAt(
    List<TimeStamp> events,
    DateTime timeAt,
  ) {
    // Handle empty list case
    if (events.isEmpty) {
      return TimeStamp(timeAt, Duration.zero, TPType.pause);
    }

    // Correct date part to match reference date
    final correctedDt = DtHelper.correctDt(timeAt, events.first.dt);

    // Use binary search to find the relevant point - similar to calculateDuration
    // This is more efficient than the linear search (especially for larger lists)
    int low = 0;
    int high = events.length - 1;
    int result = -1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final point = events[mid];

      if (point.dt.isAtSameMomentAs(correctedDt)) {
        // Exact match found - return the existing point
        return point;
      } else if (point.dt.isBefore(correctedDt)) {
        // This point is before our target time, might be the one we want
        result = mid;
        low = mid + 1;
      } else {
        // This point is after our target time, look earlier
        high = mid - 1;
      }
    }

    // If we didn't find any point before the target time,
    // return a default point at the corrected time
    if (result == -1) {
      return TimeStamp(correctedDt, Duration.zero, TPType.pause);
    }

    // Get the last point before the target time
    final latestPoint = events[result];

    // Create a new hypothetical point at the requested time with calculated duration
    return TimeStamp(
      correctedDt,
      latestPoint.typ == TPType.resume
          ? latestPoint.dur + correctedDt.difference(latestPoint.dt)
          : latestPoint.dur,
      latestPoint.typ,
    );
  }

  /// Calculates the duration at a specific time
  /// The date part of timeAt is corrected to match the reference date from events.
  ///
  /// @param timeAt The time to calculate duration for
  /// @param events The list of time points to use for calculation
  /// @return The accumulated duration at the specified time
  static Duration calculateDuration(DateTime timeAt, List<TimeStamp> events) {
    // Handle empty list case
    if (events.isEmpty) {
      return Duration.zero;
    }

    // Correct date part to match reference date
    final correctedDt = DtHelper.correctDt(timeAt, events.first.dt);

    // Use binary search to find the closest point before or at the given time
    // This is more efficient than linear search for large lists
    int low = 0;
    int high = events.length - 1;
    int result = -1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final point = events[mid];

      if (point.dt.isAtSameMomentAs(correctedDt)) {
        // Exact match found
        return point.dur;
      } else if (point.dt.isBefore(correctedDt)) {
        // This point is before our target time, might be the one we want
        result = mid;
        low = mid + 1;
      } else {
        // This point is after our target time, look earlier
        high = mid - 1;
      }
    }

    // If we didn't find any point before the target time
    if (result == -1) {
      return Duration.zero;
    }

    // Get the last point before the target time
    final latestPoint = events[result];

    // If this was a resume point, add elapsed time since the point
    return latestPoint.typ == TPType.resume
        ? latestPoint.dur + correctedDt.difference(latestPoint.dt)
        : latestPoint.dur;
  }

  /// Calculates total active duration from a list of time points
  static Duration calculateTotalDuration(List<TimeStamp> events) {
    if (events.isEmpty) {
      return Duration.zero;
    }

    Duration total = Duration.zero;
    TPType prevType = TPType.pause;
    DateTime prevTime = events.first.dt;

    for (final point in events) {
      if (prevType == TPType.resume) {
        total += point.dt.difference(prevTime);
      }
      prevType = point.typ;
      prevTime = point.dt;
    }

    // Account for ongoing tracking if the last point is resume
    if (events.last.typ == TPType.resume) {
      total += DateTime.now().difference(events.last.dt);
    }

    return total;
  }
}
