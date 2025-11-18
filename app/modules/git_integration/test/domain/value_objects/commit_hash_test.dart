import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';

void main() {
  group('CommitHash', () {
    group('creation and validation', () {
      test('should create valid commit hash', () {
        // Arrange
        final validHash = 'a' * 40;

        // Act
        final commitHash = CommitHash.create(validHash);

        // Assert
        expect(commitHash.value, equals(validHash));
      });

      test('should normalize to lowercase', () {
        final mixedCaseHash = 'AbCdEf1234567890' + '0' * 24;

        final commitHash = CommitHash.create(mixedCaseHash);

        expect(commitHash.value, equals(mixedCaseHash.toLowerCase()));
      });

      test('should accept valid hex characters', () {
        final validHash = 'abc123def456789' + '0' * 25;

        final commitHash = CommitHash.create(validHash);

        expect(commitHash.value, hasLength(40));
      });
    });

    group('validation errors', () {
      test('should throw error for hash too short', () {
        final shortHash = 'abc123';

        expect(
          () => CommitHash.create(shortHash),
          throwsA(isA<CommitHashValidationException>()),
        );
      });

      test('should throw error for hash too long', () {
        final longHash = 'a' * 50;

        expect(
          () => CommitHash.create(longHash),
          throwsA(isA<CommitHashValidationException>()),
        );
      });

      test('should throw error for invalid characters', () {
        final invalidHash = 'xyz' + '0' * 37; // 'xyz' contains invalid chars

        expect(
          () => CommitHash.create(invalidHash),
          throwsA(isA<CommitHashValidationException>()),
        );
      });

      test('should throw error with descriptive message for wrong length', () {
        try {
          CommitHash.create('abc');
          fail('Should have thrown exception');
        } catch (e) {
          expect(e, isA<CommitHashValidationException>());
          expect(e.toString(), contains('40 characters'));
          expect(e.toString(), contains('got 3'));
        }
      });

      test('should throw error with descriptive message for invalid format', () {
        final invalidHash = 'ghij' + '0' * 36;

        try {
          CommitHash.create(invalidHash);
          fail('Should have thrown exception');
        } catch (e) {
          expect(e, isA<CommitHashValidationException>());
          expect(e.toString(), contains('hexadecimal'));
        }
      });
    });

    group('fromShort factory', () {
      test('should create from 7-character short hash', () {
        final shortHash = 'abcdef1';

        final commitHash = CommitHash.fromShort(shortHash);

        expect(commitHash.short, startsWith('abcdef1'));
      });

      test('should create from longer short hash', () {
        final shortHash = 'abcdef1234';

        final commitHash = CommitHash.fromShort(shortHash);

        expect(commitHash.value, startsWith(shortHash.toLowerCase()));
      });

      test('should throw error for too short hash', () {
        final tooShort = 'abc';

        expect(
          () => CommitHash.fromShort(tooShort),
          throwsA(isA<CommitHashValidationException>()),
        );
      });

      test('should pad short hash to 40 characters', () {
        final shortHash = 'abcdef1';

        final commitHash = CommitHash.fromShort(shortHash);

        expect(commitHash.value, hasLength(40));
      });
    });

    group('short hash', () {
      test('should return 7-character short hash', () {
        final fullHash = 'abcdef1234567890' + '0' * 24;
        final commitHash = CommitHash.create(fullHash);

        final short = commitHash.short;

        expect(short, equals('abcdef1'));
        expect(short, hasLength(7));
      });

      test('should preserve case (lowercase)', () {
        final mixedHash = 'ABCDEF1234567890' + '0' * 24;
        final commitHash = CommitHash.create(mixedHash);

        expect(commitHash.short, equals('abcdef1'));
      });
    });

    group('medium hash', () {
      test('should return 10-character medium hash', () {
        final fullHash = 'abcdef1234567890' + '0' * 24;
        final commitHash = CommitHash.create(fullHash);

        final medium = commitHash.medium;

        expect(medium, equals('abcdef1234'));
        expect(medium, hasLength(10));
      });
    });

    group('matches', () {
      test('should match identical hashes', () {
        final hash1 = CommitHash.create('a' * 40);
        final hash2 = CommitHash.create('a' * 40);

        expect(hash1.matches(hash2), isTrue);
      });

      test('should match case-insensitively', () {
        final lowerHash = CommitHash.create('abcdef' + '0' * 34);
        final upperHash = CommitHash.create('ABCDEF' + '0' * 34);

        expect(lowerHash.matches(upperHash), isTrue);
      });

      test('should not match different hashes', () {
        final hash1 = CommitHash.create('a' * 40);
        final hash2 = CommitHash.create('b' * 40);

        expect(hash1.matches(hash2), isFalse);
      });
    });

    group('equality', () {
      test('should be equal with same value', () {
        final hash1 = CommitHash.create('a' * 40);
        final hash2 = CommitHash.create('a' * 40);

        expect(hash1, equals(hash2));
      });

      test('should not be equal with different values', () {
        final hash1 = CommitHash.create('a' * 40);
        final hash2 = CommitHash.create('b' * 40);

        expect(hash1, isNot(equals(hash2)));
      });

      test('should have same hashCode for equal hashes', () {
        final hash1 = CommitHash.create('a' * 40);
        final hash2 = CommitHash.create('a' * 40);

        expect(hash1.hashCode, equals(hash2.hashCode));
      });
    });

    group('use cases', () {
      test('should represent real git commit hash', () {
        final realHash = 'e83c5163316f89bfbde7d9ab23ca2e25604af290';

        final commitHash = CommitHash.create(realHash);

        expect(commitHash.short, equals('e83c516'));
        expect(commitHash.medium, equals('e83c516331'));
      });

      test('should handle hash from git log --oneline', () {
        final shortHash = 'a1b2c3d';

        final commitHash = CommitHash.fromShort(shortHash);

        expect(commitHash.short, equals(shortHash.toLowerCase()));
      });

      test('should work in collections', () {
        final hash1 = CommitHash.create('a' * 40);
        final hash2 = CommitHash.create('b' * 40);
        final hash3 = CommitHash.create('a' * 40);

        final set = {hash1, hash2, hash3};

        expect(set.length, equals(2)); // hash1 and hash3 are equal
      });

      test('should support comparison operations', () {
        final hash1 = CommitHash.create('a' * 40);
        final hash2 = CommitHash.create('a' * 40);
        final hash3 = CommitHash.create('b' * 40);

        expect(hash1.matches(hash2), isTrue);
        expect(hash1.matches(hash3), isFalse);
      });
    });

    group('CommitHashValidationException', () {
      test('should have descriptive string representation', () {
        final exception = CommitHashValidationException('Test error');

        expect(exception.toString(), contains('CommitHashValidationException'));
        expect(exception.toString(), contains('Test error'));
      });

      test('should preserve error message', () {
        final message = 'Invalid hash format';
        final exception = CommitHashValidationException(message);

        expect(exception.message, equals(message));
      });
    });
  });
}
