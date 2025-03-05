import 'package:flutter_test/flutter_test.dart';
import 'package:ten_thousands_hours/models/time_data/model/indecies_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/day_model/day_model.dart';
import 'package:ten_thousands_hours/models/time_data/model/time_point/time_point.dart';

void main() {
  group('Indices Model', () {
    test('should create with specified values', () {
      // Arrange & Act
      const indices = Indices(
        today: 5,
        weekIndices: [3, 4, 5, 6, 7],
        monthIndices: [0, 1, 2, 3, 4, 5, 6, 7],
      );

      // Assert
      expect(indices.today, 5);
      expect(indices.weekIndices, [3, 4, 5, 6, 7]);
      expect(indices.monthIndices, [0, 1, 2, 3, 4, 5, 6, 7]);
    });

    test('should correctly convert to JSON', () {
      // Arrange
      const indices = Indices(
        today: 3,
        weekIndices: [1, 2, 3],
        monthIndices: [0, 1, 2, 3],
      );

      // Act
      final json = indices.toJson();

      // Assert
      expect(json['today'], 3);
      expect(json['weekIndices'], [1, 2, 3]);
      expect(json['monthIndices'], [0, 1, 2, 3]);
    });

    test('should correctly create from JSON', () {
      // Arrange
      final json = {
        'today': 2,
        'weekIndices': [0, 1, 2],
        'monthIndices': [0, 1, 2, 3, 4],
      };

      // Act
      final indices = Indices.fromJson(json);

      // Assert
      expect(indices.today, 2);
      expect(indices.weekIndices, [0, 1, 2]);
      expect(indices.monthIndices, [0, 1, 2, 3, 4]);
    });

    test('should handle empty arrays in JSON', () {
      // Arrange
      final json = {
        'today': 0,
        'weekIndices': [],
        'monthIndices': [],
      };

      // Act
      final indices = Indices.fromJson(json);

      // Assert
      expect(indices.today, 0);
      expect(indices.weekIndices, isEmpty);
      expect(indices.monthIndices, isEmpty);
    });

    test('should handle missing arrays in JSON', () {
      // Arrange
      final json = {'today': 0};

      // Act
      final indices = Indices.fromJson(json);

      // Assert
      expect(indices.today, 0);
      expect(indices.weekIndices, isEmpty);
      expect(indices.monthIndices, isEmpty);
    });

    test('copyWith should create a copy with specified fields changed', () {
      // Arrange
      const original = Indices(
        today: 1,
        weekIndices: [0, 1],
        monthIndices: [0, 1, 2],
      );

      // Act
      final copied = original.copyWith(
        today: 2,
        weekIndices: [1, 2, 3],
      );

      // Assert
      expect(copied.today, 2);
      expect(copied.weekIndices, [1, 2, 3]);
      expect(copied.monthIndices, [0, 1, 2]);
      expect(identical(original.monthIndices, copied.monthIndices),
          isFalse); // Should be a copy, not reference
    });

    test('copyWith should create a new instance when no parameters provided',
        () {
      // Arrange
      const original = Indices(
        today: 1,
        weekIndices: [0, 1],
        monthIndices: [0, 1, 2],
      );

      // Act
      final copied = original.copyWith();

      // Assert
      expect(copied.today, 1);
      expect(copied.weekIndices, [0, 1]);
      expect(copied.monthIndices, [0, 1, 2]);

      // Ensure they're separate objects
      expect(identical(original, copied), isFalse);
      // expect(identical(original.weekIndices, copied.weekIndices), isFalse);
      // expect(identical(original.monthIndices, copied.monthIndices), isFalse);
    });
  });

  group('IndicesService', () {
    List<DayModel> createMockDays() {
      // Create a list of mock days with various distances from today
      // Day 0 = today (distanceFromToday = 0)
      // Day 1 = yesterday (distanceFromToday = 1)
      // And so on
      return List.generate(
        80,
        (i) => DayModel(
          dt: DateTime.now().subtract(Duration(days: i - 40)),
          events: [],
          coordinates: [],
          durPoint: TimePoint(
            dt: DateTime.now(),
            dur: Duration.zero,
            typ: TimePointTyp.pause,
          ),
        ),
      );
    }

    test('should create stat data with correct indices', () {
      // Arrange
      final days = createMockDays();

      // Act
      final indices = IndicesServices.updateIndices(
        dayDates: days.map((d) => d.dt).toList(),
      );

      // Assert
      expect(indices.today, greaterThanOrEqualTo(0));

      // Week indices should contain days 0-6
      expect(indices.weekIndices.length, 7);

      // // Month indices should contain days 0-30
      expect(indices.monthIndices.isNotEmpty, isTrue);
      // for (var i = 0; i < 30; i++) {
      //   expect(indices.monthIndices.contains(i), isTrue);
      // }
    });
  });
}
