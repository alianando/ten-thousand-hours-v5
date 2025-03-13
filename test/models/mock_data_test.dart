import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ten_thousands_hours/models/mock_data.dart';
import 'package:ten_thousands_hours/models/time_data/day_entry/day_model.dart';
import 'package:ten_thousands_hours/models/time_data/time_entry/time_entry.dart';
import 'package:ten_thousands_hours/models/time_data/time_point/time_point.dart';

void main() {
  group('mock data ...', () {
    test('recover record', () {
      final entities = {
        'days': [
          {
            "lastUpdate": "2025-03-01T23:59:59.999999",
            "durPoint": {
              "dt": "2025-03-01T23:59:59.999999",
              "dur": 264999,
              "typ": "pause"
            },
            "events": [
              {"dt": "2025-03-01T00:00:00.000", "dur": 0, "typ": "pause"},
              {"dt": "2025-03-01T19:23:11.369571", "dur": 0, "typ": "pause"},
              {"dt": "2025-03-01T19:24:07.706461", "dur": 0, "typ": "resume"},
              {
                "dt": "2025-03-01T19:27:56.706482",
                "dur": 229000,
                "typ": "pause"
              },
              {
                "dt": "2025-03-01T19:47:54.783153",
                "dur": 229000,
                "typ": "resume"
              },
              {
                "dt": "2025-03-01T19:48:30.782263",
                "dur": 264999,
                "typ": "pause"
              },
              {
                "dt": "2025-03-01T23:59:59.999999",
                "dur": 264999,
                "typ": "pause"
              }
            ],
            "coordinates": [
              {"dx": 0, "dy": 0},
              {"dx": 0.5386491538513654, "dy": 0},
              {"dx": 0.540214070561502, "dy": 0},
              {"dx": 0.5465751818493106, "dy": 0.03636074944426802},
              {"dx": 0.5798550994404195, "dy": 0.03636074944426802},
              {"dx": 0.5808550716904186, "dy": 0.04191806922832645},
              {"dx": 1, "dy": 0.04191806922832645}
            ],
            "coordinateSets": null
          },
          {
            "lastUpdate": "2025-03-02T23:59:59.999999",
            "durPoint": {
              "dt": "2025-03-02T23:59:59.999999",
              "dur": 4498917,
              "typ": "pause"
            },
            "events": [
              {"dt": "2025-03-02T00:00:00.000", "dur": 0, "typ": "pause"},
              {"dt": "2025-03-02T13:37:39.471314", "dur": 0, "typ": "pause"},
              {"dt": "2025-03-02T13:42:26.440352", "dur": 0, "typ": "resume"},
              {
                "dt": "2025-03-02T13:53:55.359218",
                "dur": 688918,
                "typ": "pause"
              },
              {
                "dt": "2025-03-02T14:01:00.358468",
                "dur": 688918,
                "typ": "resume"
              },
              {
                "dt": "2025-03-02T14:30:49.358544",
                "dur": 2477918,
                "typ": "pause"
              },
              {
                "dt": "2025-03-02T14:34:47.362470",
                "dur": 2477918,
                "typ": "resume"
              },
              {
                "dt": "2025-03-02T14:48:30.359264",
                "dur": 3300915,
                "typ": "pause"
              },
              {
                "dt": "2025-03-02T14:54:25.361550",
                "dur": 3300915,
                "typ": "resume"
              },
              {
                "dt": "2025-03-02T14:54:34.363507",
                "dur": 3309917,
                "typ": "pause"
              },
              {
                "dt": "2025-03-02T15:16:16.358813",
                "dur": 3309917,
                "typ": "resume"
              },
              {
                "dt": "2025-03-02T15:35:49.359549",
                "dur": 4482918,
                "typ": "pause"
              },
              {
                "dt": "2025-03-02T15:55:30.652128",
                "dur": 4482918,
                "typ": "resume"
              },
              {
                "dt": "2025-03-02T15:55:46.651807",
                "dur": 4498917,
                "typ": "pause"
              },
              {
                "dt": "2025-03-02T23:59:59.999999",
                "dur": 4498917,
                "typ": "pause"
              }
            ],
            "coordinates": [],
            "coordinateSets": null
          },
        ]
      };

      List<DayEntry> days = [];
      for (int i = 0; i < entities['days']!.length; i++) {
        Map<String, dynamic> durJson =
            entities['days']![i]['durPoint'] as Map<String, dynamic>;
        final durPoint = TimePoint.fromJson(durJson);
        final events = entities['days']![i]['events'] as List<dynamic>;
        final List<TimePoint> timePoints = [];
        for (final event in events) {
          timePoints.add(TimePoint.fromJson(event));
        }
        DayEntry day = DayEntry(
          dt: timePoints.first.dt,
          durPoint: durPoint,
          events: timePoints,
        );
        days.add(day);
        // print(day.events);
      }
      days.sort((a, b) => a.dt.compareTo(b.dt));
      TimeEntry timeEntry = TimeEntry(
        days: days,
        lastUpdate: days.first.events.last.dt,
      );
      print(jsonEncode(timeEntry.toJson()));
      expect(1, 1);
    });

    test('getMockTimeEntry', () {
      final mockData = const MockData().mockTimeEntry;
      expect(mockData.days.length, 2);
    });
  });
}
