import 'package:flutter_test/flutter_test.dart';
import 'package:editor_ffi/editor_ffi.dart';

void main() {
  group('NativeResultCode', () {
    group('enum values', () {
      test('should have correct code values', () {
        // Assert
        expect(NativeResultCode.success.code, equals(0));
        expect(NativeResultCode.errorNull.code, equals(-1));
        expect(NativeResultCode.errorInvalidUtf8.code, equals(-2));
        expect(NativeResultCode.errorOutOfBounds.code, equals(-3));
        expect(NativeResultCode.errorUnknown.code, equals(-4));
      });

      test('should have all expected result codes', () {
        // Assert
        expect(NativeResultCode.values.length, equals(5));
        expect(NativeResultCode.values, contains(NativeResultCode.success));
        expect(NativeResultCode.values, contains(NativeResultCode.errorNull));
        expect(NativeResultCode.values, contains(NativeResultCode.errorInvalidUtf8));
        expect(NativeResultCode.values, contains(NativeResultCode.errorOutOfBounds));
        expect(NativeResultCode.values, contains(NativeResultCode.errorUnknown));
      });
    });

    group('fromCode', () {
      test('should return success for code 0', () {
        // Act
        final result = NativeResultCode.fromCode(0);

        // Assert
        expect(result, equals(NativeResultCode.success));
        expect(result.isSuccess, isTrue);
      });

      test('should return errorNull for code -1', () {
        // Act
        final result = NativeResultCode.fromCode(-1);

        // Assert
        expect(result, equals(NativeResultCode.errorNull));
        expect(result.isSuccess, isFalse);
      });

      test('should return errorInvalidUtf8 for code -2', () {
        // Act
        final result = NativeResultCode.fromCode(-2);

        // Assert
        expect(result, equals(NativeResultCode.errorInvalidUtf8));
        expect(result.isSuccess, isFalse);
      });

      test('should return errorOutOfBounds for code -3', () {
        // Act
        final result = NativeResultCode.fromCode(-3);

        // Assert
        expect(result, equals(NativeResultCode.errorOutOfBounds));
        expect(result.isSuccess, isFalse);
      });

      test('should return errorUnknown for code -4', () {
        // Act
        final result = NativeResultCode.fromCode(-4);

        // Assert
        expect(result, equals(NativeResultCode.errorUnknown));
        expect(result.isSuccess, isFalse);
      });

      test('should return errorUnknown for unrecognized positive code', () {
        // Act
        final result = NativeResultCode.fromCode(999);

        // Assert
        expect(result, equals(NativeResultCode.errorUnknown));
        expect(result.isSuccess, isFalse);
      });

      test('should return errorUnknown for unrecognized negative code', () {
        // Act
        final result = NativeResultCode.fromCode(-999);

        // Assert
        expect(result, equals(NativeResultCode.errorUnknown));
        expect(result.isSuccess, isFalse);
      });

      test('should handle zero correctly', () {
        // Act
        final result = NativeResultCode.fromCode(0);

        // Assert
        expect(result.code, equals(0));
        expect(result, equals(NativeResultCode.success));
      });

      test('should handle multiple calls with same code', () {
        // Act
        final result1 = NativeResultCode.fromCode(-1);
        final result2 = NativeResultCode.fromCode(-1);
        final result3 = NativeResultCode.fromCode(-1);

        // Assert
        expect(result1, equals(result2));
        expect(result2, equals(result3));
        expect(result1, equals(NativeResultCode.errorNull));
      });
    });

    group('isSuccess', () {
      test('should return true only for success code', () {
        // Assert
        expect(NativeResultCode.success.isSuccess, isTrue);
        expect(NativeResultCode.errorNull.isSuccess, isFalse);
        expect(NativeResultCode.errorInvalidUtf8.isSuccess, isFalse);
        expect(NativeResultCode.errorOutOfBounds.isSuccess, isFalse);
        expect(NativeResultCode.errorUnknown.isSuccess, isFalse);
      });

      test('should work with fromCode results', () {
        // Arrange
        final successResult = NativeResultCode.fromCode(0);
        final errorResult = NativeResultCode.fromCode(-1);

        // Assert
        expect(successResult.isSuccess, isTrue);
        expect(errorResult.isSuccess, isFalse);
      });

      test('should identify all error codes as not success', () {
        // Arrange
        final errorCodes = [-1, -2, -3, -4, -99];

        // Act & Assert
        for (final code in errorCodes) {
          final result = NativeResultCode.fromCode(code);
          expect(result.isSuccess, isFalse, reason: 'Code $code should not be success');
        }
      });
    });

    group('code property', () {
      test('should preserve original code value', () {
        // Assert
        expect(NativeResultCode.success.code, equals(0));
        expect(NativeResultCode.errorNull.code, equals(-1));
        expect(NativeResultCode.errorInvalidUtf8.code, equals(-2));
        expect(NativeResultCode.errorOutOfBounds.code, equals(-3));
        expect(NativeResultCode.errorUnknown.code, equals(-4));
      });

      test('should maintain code consistency', () {
        // Act
        final result = NativeResultCode.fromCode(-2);

        // Assert
        expect(result.code, equals(-2));
        expect(result, equals(NativeResultCode.errorInvalidUtf8));
      });
    });

    group('error type identification', () {
      test('should distinguish between different error types', () {
        // Act
        final nullError = NativeResultCode.fromCode(-1);
        final utf8Error = NativeResultCode.fromCode(-2);
        final boundsError = NativeResultCode.fromCode(-3);
        final unknownError = NativeResultCode.fromCode(-4);

        // Assert
        expect(nullError, equals(NativeResultCode.errorNull));
        expect(utf8Error, equals(NativeResultCode.errorInvalidUtf8));
        expect(boundsError, equals(NativeResultCode.errorOutOfBounds));
        expect(unknownError, equals(NativeResultCode.errorUnknown));

        expect(nullError, isNot(equals(utf8Error)));
        expect(utf8Error, isNot(equals(boundsError)));
        expect(boundsError, isNot(equals(unknownError)));
      });

      test('should identify null pointer errors', () {
        // Act
        final result = NativeResultCode.fromCode(-1);

        // Assert
        expect(result, equals(NativeResultCode.errorNull));
        expect(result.code, equals(-1));
      });

      test('should identify UTF-8 encoding errors', () {
        // Act
        final result = NativeResultCode.fromCode(-2);

        // Assert
        expect(result, equals(NativeResultCode.errorInvalidUtf8));
        expect(result.code, equals(-2));
      });

      test('should identify out of bounds errors', () {
        // Act
        final result = NativeResultCode.fromCode(-3);

        // Assert
        expect(result, equals(NativeResultCode.errorOutOfBounds));
        expect(result.code, equals(-3));
      });
    });

    group('edge cases', () {
      test('should handle extreme positive values', () {
        // Act
        final result = NativeResultCode.fromCode(2147483647);

        // Assert
        expect(result, equals(NativeResultCode.errorUnknown));
        expect(result.isSuccess, isFalse);
      });

      test('should handle extreme negative values', () {
        // Act
        final result = NativeResultCode.fromCode(-2147483648);

        // Assert
        expect(result, equals(NativeResultCode.errorUnknown));
        expect(result.isSuccess, isFalse);
      });

      test('should handle code 1 as unknown', () {
        // Act
        final result = NativeResultCode.fromCode(1);

        // Assert
        expect(result, equals(NativeResultCode.errorUnknown));
      });

      test('should handle code -5 as unknown', () {
        // Act
        final result = NativeResultCode.fromCode(-5);

        // Assert
        expect(result, equals(NativeResultCode.errorUnknown));
      });
    });

    group('usage patterns', () {
      test('should support pattern matching with switch', () {
        // Arrange
        final testCases = [
          (0, true),
          (-1, false),
          (-2, false),
          (-3, false),
          (-4, false),
        ];

        for (final (code, expectedSuccess) in testCases) {
          // Act
          final result = NativeResultCode.fromCode(code);
          late bool isSuccess;

          switch (result) {
            case NativeResultCode.success:
              isSuccess = true;
              break;
            case NativeResultCode.errorNull:
            case NativeResultCode.errorInvalidUtf8:
            case NativeResultCode.errorOutOfBounds:
            case NativeResultCode.errorUnknown:
              isSuccess = false;
              break;
          }

          // Assert
          expect(isSuccess, equals(expectedSuccess), reason: 'Failed for code $code');
        }
      });

      test('should support equality comparison', () {
        // Arrange
        final result1 = NativeResultCode.fromCode(0);
        final result2 = NativeResultCode.fromCode(0);
        final result3 = NativeResultCode.fromCode(-1);

        // Assert
        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
        expect(result1 == NativeResultCode.success, isTrue);
        expect(result3 == NativeResultCode.errorNull, isTrue);
      });
    });
  });
}
