import 'package:ten_thousands_hours/models/time_data/model/time_point.dart';

class SessionData {
  final DateTime dayStartTime;
  final DateTime dayEndTime;
  final DateTime sessionStartDt;
  final DateTime sessionEndDt;

  const SessionData({
    required this.dayStartTime,
    required this.dayEndTime,
    required this.sessionStartDt,
    required this.sessionEndDt,
  });

  Map<String, dynamic> toJson() {
    return {
      'dayStartTime': dayStartTime.toIso8601String(),
      'dayEndTime': dayEndTime.toIso8601String(),
      'sessionStartDt': sessionStartDt.toIso8601String(),
      'sessionEndDt': sessionEndDt.toIso8601String(),
    };
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      dayStartTime: DateTime.parse(json['dayStartTime']),
      dayEndTime: DateTime.parse(json['dayEndTime']),
      sessionStartDt: DateTime.parse(json['sessionStartDt']),
      sessionEndDt: DateTime.parse(json['sessionEndDt']),
    );
  }

  SessionData copyWith({
    DateTime? dayStartTime,
    DateTime? dayEndTime,
    DateTime? sessionStartDt,
    DateTime? sessionEndDt,
  }) {
    return SessionData(
      dayStartTime: dayStartTime ?? this.dayStartTime,
      dayEndTime: dayEndTime ?? this.dayEndTime,
      sessionStartDt: sessionStartDt ?? this.sessionStartDt,
      sessionEndDt: sessionEndDt ?? this.sessionEndDt,
    );
  }
}

class SessionServices {
  const SessionServices._();

  /// Creates default session data for a given date
  static SessionData createDefaultSession(DateTime date) {
    final dayStartDt = DtHelper.dayStartDt(date);
    final dayEndDt = DtHelper.dayEndDt(date);
    return SessionData(
      dayStartTime: dayStartDt,
      dayEndTime: dayEndDt,
      sessionStartDt: dayStartDt,
      sessionEndDt: dayEndDt,
    );
  }
}
