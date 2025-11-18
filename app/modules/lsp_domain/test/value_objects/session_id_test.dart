import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('SessionId', () {
    group('creation', () {
      test('should create session ID with value', () {
        // Act
        const sessionId = SessionId('test_session_123');

        // Assert
        expect(sessionId.value, equals('test_session_123'));
      });

      test('should generate unique session IDs', () {
        // Act
        final id1 = SessionId.generate();
        final id2 = SessionId.generate();

        // Assert
        expect(id1, isNot(equals(id2)));
        expect(id1.value, isNot(equals(id2.value)));
      });

      test('should generate session ID with expected format', () {
        // Act
        final sessionId = SessionId.generate();

        // Assert
        expect(sessionId.value, startsWith('session_'));
        expect(sessionId.value.split('_').length, equals(4));
      });

      test('should include timestamp in generated ID', () {
        // Arrange
        final beforeTimestamp = DateTime.now().millisecondsSinceEpoch;

        // Act
        final sessionId = SessionId.generate();

        // Assert
        final parts = sessionId.value.split('_');
        final timestamp = int.parse(parts[1]);
        expect(timestamp, greaterThanOrEqualTo(beforeTimestamp));
      });

      test('should create from string', () {
        // Act
        final sessionId = SessionId.fromString('custom_session_id');

        // Assert
        expect(sessionId.value, equals('custom_session_id'));
      });

      test('should throw error for empty string', () {
        // Act & Assert
        expect(
          () => SessionId.fromString(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error with descriptive message for empty string', () {
        // Act & Assert
        expect(
          () => SessionId.fromString(''),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Session ID cannot be empty'),
            ),
          ),
        );
      });
    });

    group('equality', () {
      test('should be equal with same value', () {
        const id1 = SessionId('session_123');
        const id2 = SessionId('session_123');

        expect(id1, equals(id2));
        expect(id1.hashCode, equals(id2.hashCode));
      });

      test('should not be equal with different values', () {
        const id1 = SessionId('session_123');
        const id2 = SessionId('session_456');

        expect(id1, isNot(equals(id2)));
      });

      test('should be equal when created from same string', () {
        final id1 = SessionId.fromString('test_id');
        final id2 = SessionId.fromString('test_id');

        expect(id1, equals(id2));
      });
    });

    group('uniqueness', () {
      test('should generate different IDs in quick succession', () {
        // Arrange
        const iterations = 100;
        final ids = <SessionId>{};

        // Act
        for (var i = 0; i < iterations; i++) {
          ids.add(SessionId.generate());
        }

        // Assert
        expect(ids.length, equals(iterations));
      });

      test('should generate different IDs with same timestamp', () {
        // Note: This tests the random component
        final id1 = SessionId.generate();
        final id2 = SessionId.generate();
        final id3 = SessionId.generate();

        final ids = {id1, id2, id3};

        expect(ids.length, equals(3));
      });
    });

    group('immutability', () {
      test('should be immutable', () {
        const id = SessionId('test_id');

        // Assert - Freezed generates const constructors for immutability
        expect(id.value, equals('test_id'));
        // Attempting to change would cause compile error
      });
    });

    group('string representation', () {
      test('should have meaningful toString', () {
        const id = SessionId('my_session');

        final str = id.toString();

        expect(str, contains('my_session'));
      });
    });

    group('usage in collections', () {
      test('should work as map key', () {
        // Arrange
        const id1 = SessionId('session_1');
        const id2 = SessionId('session_2');
        final map = <SessionId, String>{
          id1: 'value1',
          id2: 'value2',
        };

        // Assert
        expect(map[id1], equals('value1'));
        expect(map[id2], equals('value2'));
      });

      test('should work in set', () {
        // Arrange
        const id1 = SessionId('session_1');
        const id2 = SessionId('session_2');
        const id1Duplicate = SessionId('session_1');

        // Act
        final set = {id1, id2, id1Duplicate};

        // Assert
        expect(set.length, equals(2));
        expect(set, contains(id1));
        expect(set, contains(id2));
      });
    });

    group('performance', () {
      test('should generate IDs quickly', () {
        // Arrange
        const iterations = 1000;
        final stopwatch = Stopwatch()..start();

        // Act
        for (var i = 0; i < iterations; i++) {
          SessionId.generate();
        }

        // Assert
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
