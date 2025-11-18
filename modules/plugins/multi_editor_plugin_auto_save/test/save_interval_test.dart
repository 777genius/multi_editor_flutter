import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_auto_save/src/domain/value_objects/save_interval.dart';

void main() {
  group('SaveInterval - Creation', () {
    test('should create default interval of 5 seconds', () {
      // Arrange & Act
      final interval = SaveInterval.defaultInterval();

      // Assert
      expect(interval.seconds, 5);
    });

    test('should create from valid seconds', () {
      // Arrange & Act
      final interval = SaveInterval.fromSeconds(10);

      // Assert
      expect(interval.seconds, 10);
    });

    test('should create interval at minimum boundary (1 second)', () {
      // Arrange & Act
      final interval = SaveInterval.fromSeconds(1);

      // Assert
      expect(interval.seconds, 1);
      expect(interval.isValid, true);
    });

    test('should create interval at maximum boundary (60 seconds)', () {
      // Arrange & Act
      final interval = SaveInterval.fromSeconds(60);

      // Assert
      expect(interval.seconds, 60);
      expect(interval.isValid, true);
    });

    test('should throw ArgumentError for seconds below minimum', () {
      // Arrange, Act & Assert
      expect(
        () => SaveInterval.fromSeconds(0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for negative seconds', () {
      // Arrange, Act & Assert
      expect(
        () => SaveInterval.fromSeconds(-5),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for seconds above maximum', () {
      // Arrange, Act & Assert
      expect(
        () => SaveInterval.fromSeconds(61),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError with descriptive message', () {
      // Arrange, Act & Assert
      try {
        SaveInterval.fromSeconds(100);
        fail('Should throw ArgumentError');
      } catch (e) {
        expect(e, isA<ArgumentError>());
        expect(
          e.toString(),
          contains('Save interval must be between 1 and 60 seconds'),
        );
      }
    });
  });

  group('SaveInterval - Properties', () {
    test('should convert to Duration correctly', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(15);

      // Act
      final duration = interval.duration;

      // Assert
      expect(duration, const Duration(seconds: 15));
      expect(duration.inSeconds, 15);
      expect(duration.inMilliseconds, 15000);
    });

    test('should validate correct intervals', () {
      // Arrange
      final validInterval = SaveInterval.fromSeconds(30);

      // Act & Assert
      expect(validInterval.isValid, true);
    });

    test('should provide display text for singular second', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(1);

      // Act
      final displayText = interval.displayText;

      // Assert
      expect(displayText, '1 second');
    });

    test('should provide display text for plural seconds', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(5);

      // Act
      final displayText = interval.displayText;

      // Assert
      expect(displayText, '5 seconds');
    });

    test('should provide display text for various values', () {
      // Arrange & Act & Assert
      expect(SaveInterval.fromSeconds(1).displayText, '1 second');
      expect(SaveInterval.fromSeconds(2).displayText, '2 seconds');
      expect(SaveInterval.fromSeconds(10).displayText, '10 seconds');
      expect(SaveInterval.fromSeconds(30).displayText, '30 seconds');
      expect(SaveInterval.fromSeconds(60).displayText, '60 seconds');
    });
  });

  group('SaveInterval - JSON Serialization', () {
    test('should serialize to JSON', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(20);

      // Act
      final json = interval.toJson();

      // Assert
      expect(json, isA<Map<String, dynamic>>());
      expect(json['seconds'], 20);
    });

    test('should deserialize from JSON', () {
      // Arrange
      final json = {'seconds': 25};

      // Act
      final interval = SaveInterval.fromJson(json);

      // Assert
      expect(interval.seconds, 25);
    });

    test('should roundtrip through JSON', () {
      // Arrange
      final original = SaveInterval.fromSeconds(45);

      // Act
      final json = original.toJson();
      final restored = SaveInterval.fromJson(json);

      // Assert
      expect(restored.seconds, original.seconds);
      expect(restored.duration, original.duration);
      expect(restored.displayText, original.displayText);
    });

    test('should deserialize minimum value from JSON', () {
      // Arrange
      final json = {'seconds': 1};

      // Act
      final interval = SaveInterval.fromJson(json);

      // Assert
      expect(interval.seconds, 1);
      expect(interval.isValid, true);
    });

    test('should deserialize maximum value from JSON', () {
      // Arrange
      final json = {'seconds': 60};

      // Act
      final interval = SaveInterval.fromJson(json);

      // Assert
      expect(interval.seconds, 60);
      expect(interval.isValid, true);
    });
  });

  group('SaveInterval - Equality', () {
    test('should be equal for same values', () {
      // Arrange
      final interval1 = SaveInterval.fromSeconds(10);
      final interval2 = SaveInterval.fromSeconds(10);

      // Act & Assert
      expect(interval1, equals(interval2));
      expect(interval1.hashCode, equals(interval2.hashCode));
    });

    test('should not be equal for different values', () {
      // Arrange
      final interval1 = SaveInterval.fromSeconds(10);
      final interval2 = SaveInterval.fromSeconds(20);

      // Act & Assert
      expect(interval1, isNot(equals(interval2)));
    });

    test('should have same equality as direct construction', () {
      // Arrange
      final fromFactory = SaveInterval.fromSeconds(5);
      final fromConstructor = const SaveInterval(seconds: 5);

      // Act & Assert
      expect(fromFactory, equals(fromConstructor));
    });
  });

  group('SaveInterval - Immutability', () {
    test('should be immutable', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(15);
      final originalSeconds = interval.seconds;

      // Act - Try to modify (if possible)
      // SaveInterval is freezed, so this is just documentation

      // Assert - Value should remain unchanged
      expect(interval.seconds, originalSeconds);
    });

    test('should create new instance with copyWith', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(10);

      // Act
      final newInterval = interval.copyWith(seconds: 20);

      // Assert
      expect(interval.seconds, 10); // Original unchanged
      expect(newInterval.seconds, 20); // New instance created
    });
  });

  group('SaveInterval - Use Cases', () {
    test('Use Case: Quick save every 3 seconds', () {
      // Arrange & Act
      final interval = SaveInterval.fromSeconds(3);

      // Assert
      expect(interval.seconds, 3);
      expect(interval.duration, const Duration(seconds: 3));
      expect(interval.displayText, '3 seconds');
    });

    test('Use Case: Standard save every 5 seconds', () {
      // Arrange & Act
      final interval = SaveInterval.defaultInterval();

      // Assert
      expect(interval.seconds, 5);
      expect(interval.duration, const Duration(seconds: 5));
    });

    test('Use Case: Conservative save every 30 seconds', () {
      // Arrange & Act
      final interval = SaveInterval.fromSeconds(30);

      // Assert
      expect(interval.seconds, 30);
      expect(interval.duration, const Duration(seconds: 30));
    });

    test('Use Case: Maximum interval for minimal disk writes', () {
      // Arrange & Act
      final interval = SaveInterval.fromSeconds(60);

      // Assert
      expect(interval.seconds, 60);
      expect(interval.duration, const Duration(seconds: 60));
      expect(interval.isValid, true);
    });

    test('Use Case: Immediate save (minimum interval)', () {
      // Arrange & Act
      final interval = SaveInterval.fromSeconds(1);

      // Assert
      expect(interval.seconds, 1);
      expect(interval.duration, const Duration(seconds: 1));
    });

    test('Use Case: Validate user-provided interval', () {
      // Arrange
      const userInput = 45;

      // Act
      final interval = SaveInterval.fromSeconds(userInput);

      // Assert
      expect(interval.isValid, true);
      expect(interval.seconds, 45);
    });

    test('Use Case: Reject invalid user input', () {
      // Arrange
      const invalidInput = 120;

      // Act & Assert
      expect(
        () => SaveInterval.fromSeconds(invalidInput),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Use Case: Display interval to user in readable format', () {
      // Arrange
      final intervals = [
        SaveInterval.fromSeconds(1),
        SaveInterval.fromSeconds(5),
        SaveInterval.fromSeconds(10),
        SaveInterval.fromSeconds(30),
        SaveInterval.fromSeconds(60),
      ];

      // Act
      final displayTexts = intervals.map((i) => i.displayText).toList();

      // Assert
      expect(displayTexts, [
        '1 second',
        '5 seconds',
        '10 seconds',
        '30 seconds',
        '60 seconds',
      ]);
    });
  });

  group('SaveInterval - Edge Cases', () {
    test('should handle exactly 1 second correctly', () {
      // Arrange & Act
      final interval = SaveInterval.fromSeconds(1);

      // Assert
      expect(interval.seconds, 1);
      expect(interval.isValid, true);
      expect(interval.displayText, '1 second');
    });

    test('should handle exactly 60 seconds correctly', () {
      // Arrange & Act
      final interval = SaveInterval.fromSeconds(60);

      // Assert
      expect(interval.seconds, 60);
      expect(interval.isValid, true);
      expect(interval.displayText, '60 seconds');
    });

    test('should maintain precision in Duration conversion', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(37);

      // Act
      final duration = interval.duration;

      // Assert
      expect(duration.inSeconds, 37);
      expect(duration.inMilliseconds, 37000);
      expect(duration.inMicroseconds, 37000000);
    });

    test('should handle all valid values in range', () {
      // Arrange & Act & Assert
      for (int i = 1; i <= 60; i++) {
        final interval = SaveInterval.fromSeconds(i);
        expect(interval.seconds, i);
        expect(interval.isValid, true);
      }
    });

    test('should reject all values below minimum', () {
      // Arrange & Act & Assert
      for (int i = -10; i <= 0; i++) {
        expect(
          () => SaveInterval.fromSeconds(i),
          throwsA(isA<ArgumentError>()),
        );
      }
    });

    test('should reject all values above maximum', () {
      // Arrange & Act & Assert
      for (int i = 61; i <= 100; i++) {
        expect(
          () => SaveInterval.fromSeconds(i),
          throwsA(isA<ArgumentError>()),
        );
      }
    });
  });

  group('SaveInterval - toString', () {
    test('should have readable toString representation', () {
      // Arrange
      final interval = SaveInterval.fromSeconds(15);

      // Act
      final str = interval.toString();

      // Assert
      expect(str, contains('SaveInterval'));
      expect(str, contains('seconds'));
    });
  });
}
