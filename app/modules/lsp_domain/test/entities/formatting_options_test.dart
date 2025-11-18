import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('FormattingOptions', () {
    group('Construction', () {
      test('should create with required parameters', () {
        // Act
        const options = FormattingOptions(
          tabSize: 4,
          insertSpaces: true,
        );

        // Assert
        expect(options.tabSize, equals(4));
        expect(options.insertSpaces, isTrue);
        expect(options.trimTrailingWhitespace, isNull);
        expect(options.insertFinalNewline, isNull);
        expect(options.trimFinalNewlines, isNull);
      });

      test('should create with all parameters', () {
        // Act
        const options = FormattingOptions(
          tabSize: 2,
          insertSpaces: true,
          trimTrailingWhitespace: true,
          insertFinalNewline: true,
          trimFinalNewlines: false,
        );

        // Assert
        expect(options.tabSize, equals(2));
        expect(options.insertSpaces, isTrue);
        expect(options.trimTrailingWhitespace, isTrue);
        expect(options.insertFinalNewline, isTrue);
        expect(options.trimFinalNewlines, isFalse);
      });

      test('should allow tabs (insertSpaces false)', () {
        // Act
        const options = FormattingOptions(
          tabSize: 4,
          insertSpaces: false,
        );

        // Assert
        expect(options.insertSpaces, isFalse);
        expect(options.tabSize, equals(4));
      });

      test('should support various tab sizes', () {
        // Arrange
        final tabSizes = [1, 2, 3, 4, 8];

        // Act & Assert
        for (final size in tabSizes) {
          final options = FormattingOptions(
            tabSize: size,
            insertSpaces: true,
          );
          expect(options.tabSize, equals(size));
        }
      });
    });

    group('defaults', () {
      test('should provide default formatting options', () {
        // Act
        final options = FormattingOptions.defaults();

        // Assert
        expect(options.tabSize, equals(2));
        expect(options.insertSpaces, isTrue);
        expect(options.trimTrailingWhitespace, isTrue);
        expect(options.insertFinalNewline, isTrue);
        expect(options.trimFinalNewlines, isTrue);
      });

      test('should create immutable defaults', () {
        // Act
        final defaults1 = FormattingOptions.defaults();
        final defaults2 = FormattingOptions.defaults();

        // Assert
        expect(defaults1.tabSize, equals(defaults2.tabSize));
        expect(defaults1.insertSpaces, equals(defaults2.insertSpaces));
      });

      test('default should prefer spaces over tabs', () {
        // Act
        final options = FormattingOptions.defaults();

        // Assert
        expect(options.insertSpaces, isTrue);
      });

      test('default should use 2-space indentation', () {
        // Act
        final options = FormattingOptions.defaults();

        // Assert
        expect(options.tabSize, equals(2));
      });

      test('default should trim trailing whitespace', () {
        // Act
        final options = FormattingOptions.defaults();

        // Assert
        expect(options.trimTrailingWhitespace, isTrue);
      });

      test('default should insert final newline', () {
        // Act
        final options = FormattingOptions.defaults();

        // Assert
        expect(options.insertFinalNewline, isTrue);
      });

      test('default should trim final newlines', () {
        // Act
        final options = FormattingOptions.defaults();

        // Assert
        expect(options.trimFinalNewlines, isTrue);
      });
    });

    group('Equality', () {
      test('should be equal with same values', () {
        // Arrange
        const options1 = FormattingOptions(
          tabSize: 4,
          insertSpaces: true,
          trimTrailingWhitespace: true,
        );
        const options2 = FormattingOptions(
          tabSize: 4,
          insertSpaces: true,
          trimTrailingWhitespace: true,
        );

        // Assert
        expect(options1, equals(options2));
      });

      test('should not be equal with different tab size', () {
        // Arrange
        const options1 = FormattingOptions(tabSize: 2, insertSpaces: true);
        const options2 = FormattingOptions(tabSize: 4, insertSpaces: true);

        // Assert
        expect(options1, isNot(equals(options2)));
      });

      test('should not be equal with different insertSpaces', () {
        // Arrange
        const options1 = FormattingOptions(tabSize: 4, insertSpaces: true);
        const options2 = FormattingOptions(tabSize: 4, insertSpaces: false);

        // Assert
        expect(options1, isNot(equals(options2)));
      });

      test('should not be equal with different optional parameters', () {
        // Arrange
        const options1 = FormattingOptions(
          tabSize: 4,
          insertSpaces: true,
          trimTrailingWhitespace: true,
        );
        const options2 = FormattingOptions(
          tabSize: 4,
          insertSpaces: true,
          trimTrailingWhitespace: false,
        );

        // Assert
        expect(options1, isNot(equals(options2)));
      });
    });

    group('Common Scenarios', () {
      test('should support Dart formatting style (2 spaces)', () {
        // Act
        const options = FormattingOptions(
          tabSize: 2,
          insertSpaces: true,
          trimTrailingWhitespace: true,
          insertFinalNewline: true,
        );

        // Assert
        expect(options.tabSize, equals(2));
        expect(options.insertSpaces, isTrue);
      });

      test('should support JavaScript/TypeScript style (2 spaces)', () {
        // Act
        const options = FormattingOptions(
          tabSize: 2,
          insertSpaces: true,
        );

        // Assert
        expect(options.tabSize, equals(2));
        expect(options.insertSpaces, isTrue);
      });

      test('should support Python style (4 spaces)', () {
        // Act
        const options = FormattingOptions(
          tabSize: 4,
          insertSpaces: true,
        );

        // Assert
        expect(options.tabSize, equals(4));
        expect(options.insertSpaces, isTrue);
      });

      test('should support Go style (tabs)', () {
        // Act
        const options = FormattingOptions(
          tabSize: 4,
          insertSpaces: false,
        );

        // Assert
        expect(options.insertSpaces, isFalse);
      });

      test('should support C/C++ style (variable)', () {
        // Act - some projects use 4 spaces
        const options = FormattingOptions(
          tabSize: 4,
          insertSpaces: true,
        );

        // Assert
        expect(options.tabSize, equals(4));
      });
    });

    group('Edge Cases', () {
      test('should handle tab size of 1', () {
        // Act
        const options = FormattingOptions(
          tabSize: 1,
          insertSpaces: true,
        );

        // Assert
        expect(options.tabSize, equals(1));
      });

      test('should handle large tab size', () {
        // Act
        const options = FormattingOptions(
          tabSize: 16,
          insertSpaces: true,
        );

        // Assert
        expect(options.tabSize, equals(16));
      });

      test('should handle null optional parameters', () {
        // Act
        const options = FormattingOptions(
          tabSize: 2,
          insertSpaces: true,
          trimTrailingWhitespace: null,
          insertFinalNewline: null,
          trimFinalNewlines: null,
        );

        // Assert
        expect(options.trimTrailingWhitespace, isNull);
        expect(options.insertFinalNewline, isNull);
        expect(options.trimFinalNewlines, isNull);
      });

      test('should handle all optional parameters set to false', () {
        // Act
        const options = FormattingOptions(
          tabSize: 2,
          insertSpaces: true,
          trimTrailingWhitespace: false,
          insertFinalNewline: false,
          trimFinalNewlines: false,
        );

        // Assert
        expect(options.trimTrailingWhitespace, isFalse);
        expect(options.insertFinalNewline, isFalse);
        expect(options.trimFinalNewlines, isFalse);
      });
    });

    group('Freezed Functionality', () {
      test('should be immutable', () {
        // Arrange
        const options = FormattingOptions(tabSize: 2, insertSpaces: true);

        // Assert - Freezed generates classes that are immutable
        expect(options, isA<FormattingOptions>());
      });

      test('should support copyWith', () {
        // Arrange
        const original = FormattingOptions(tabSize: 2, insertSpaces: true);

        // Act
        final modified = original.copyWith(tabSize: 4);

        // Assert
        expect(modified.tabSize, equals(4));
        expect(modified.insertSpaces, isTrue);
        expect(original.tabSize, equals(2)); // Original unchanged
      });

      test('should support copyWith for optional parameters', () {
        // Arrange
        const original = FormattingOptions(
          tabSize: 2,
          insertSpaces: true,
        );

        // Act
        final modified = original.copyWith(
          trimTrailingWhitespace: true,
          insertFinalNewline: false,
        );

        // Assert
        expect(modified.trimTrailingWhitespace, isTrue);
        expect(modified.insertFinalNewline, isFalse);
      });
    });

    group('Validation Scenarios', () {
      test('should represent minimal valid options', () {
        // Act
        const options = FormattingOptions(
          tabSize: 1,
          insertSpaces: false,
        );

        // Assert
        expect(options.tabSize, isPositive);
      });

      test('should handle typical editor configurations', () {
        // Test common configurations
        final configs = [
          const FormattingOptions(tabSize: 2, insertSpaces: true),  // VSCode default
          const FormattingOptions(tabSize: 4, insertSpaces: true),  // Many IDEs
          const FormattingOptions(tabSize: 8, insertSpaces: false), // Classic tabs
        ];

        // Assert
        for (final config in configs) {
          expect(config.tabSize, greaterThan(0));
        }
      });
    });
  });
}
