import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide_presentation/ide_presentation.dart';

void main() {
  group('IdeTheme', () {
    group('dark theme', () {
      test('should have dark brightness', () {
        // Act
        final theme = IdeTheme.dark;

        // Assert
        expect(theme.brightness, equals(Brightness.dark));
      });

      test('should have VS Code dark colors', () {
        // Act
        final theme = IdeTheme.dark;

        // Assert
        expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF1E1E1E)));
        expect(theme.primaryColor, equals(const Color(0xFF007ACC)));
        expect(theme.cardColor, equals(const Color(0xFF252526)));
      });

      test('should have dark color scheme', () {
        // Act
        final theme = IdeTheme.dark;

        // Assert
        expect(theme.colorScheme.brightness, equals(Brightness.dark));
        expect(theme.colorScheme.primary, equals(const Color(0xFF007ACC)));
        expect(theme.colorScheme.surface, equals(const Color(0xFF252526)));
      });

      test('should have correct text colors', () {
        // Act
        final theme = IdeTheme.dark;

        // Assert
        expect(theme.textTheme.bodyLarge?.color, isNotNull);
        expect(theme.iconTheme.color, equals(Colors.white));
      });

      test('should have app bar configuration', () {
        // Act
        final theme = IdeTheme.dark;

        // Assert
        expect(theme.appBarTheme.backgroundColor, equals(const Color(0xFF2D2D30)));
        expect(theme.appBarTheme.foregroundColor, equals(Colors.white));
        expect(theme.appBarTheme.elevation, equals(0));
      });

      test('should have IDE colors extension', () {
        // Act
        final theme = IdeTheme.dark;

        // Assert
        final ideColors = theme.extension<IdeColors>();
        expect(ideColors, isNotNull);
        expect(ideColors?.editorBackground, isNotNull);
      });

      test('should have syntax colors extension', () {
        // Act
        final theme = IdeTheme.dark;

        // Assert
        final syntaxColors = theme.extension<SyntaxColors>();
        expect(syntaxColors, isNotNull);
        expect(syntaxColors?.keyword, isNotNull);
      });
    });

    group('light theme', () {
      test('should have light brightness', () {
        // Act
        final theme = IdeTheme.light;

        // Assert
        expect(theme.brightness, equals(Brightness.light));
      });

      test('should have VS Code light colors', () {
        // Act
        final theme = IdeTheme.light;

        // Assert
        expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFFFFFFF)));
        expect(theme.primaryColor, equals(const Color(0xFF005FB8)));
        expect(theme.cardColor, equals(const Color(0xFFF3F3F3)));
      });

      test('should have light color scheme', () {
        // Act
        final theme = IdeTheme.light;

        // Assert
        expect(theme.colorScheme.brightness, equals(Brightness.light));
        expect(theme.colorScheme.primary, equals(const Color(0xFF005FB8)));
        expect(theme.colorScheme.surface, equals(const Color(0xFFF3F3F3)));
      });

      test('should have correct text colors', () {
        // Act
        final theme = IdeTheme.light;

        // Assert
        expect(theme.textTheme.bodyLarge?.color, isNotNull);
        expect(theme.iconTheme.color, isNotNull);
      });

      test('should have IDE colors extension', () {
        // Act
        final theme = IdeTheme.light;

        // Assert
        final ideColors = theme.extension<IdeColors>();
        expect(ideColors, isNotNull);
        expect(ideColors?.editorBackground, isNotNull);
      });

      test('should have syntax colors extension', () {
        // Act
        final theme = IdeTheme.light;

        // Assert
        final syntaxColors = theme.extension<SyntaxColors>();
        expect(syntaxColors, isNotNull);
        expect(syntaxColors?.keyword, isNotNull);
      });
    });

    group('IdeColors', () {
      test('should have dark IDE colors', () {
        // Act
        final colors = IdeColors.dark;

        // Assert
        expect(colors.editorBackground, isNotNull);
        expect(colors.lineNumberColor, isNotNull);
        expect(colors.selectionBackground, isNotNull);
        expect(colors.cursorColor, isNotNull);
      });

      test('should have light IDE colors', () {
        // Act
        final colors = IdeColors.light;

        // Assert
        expect(colors.editorBackground, isNotNull);
        expect(colors.lineNumberColor, isNotNull);
        expect(colors.selectionBackground, isNotNull);
        expect(colors.cursorColor, isNotNull);
      });

      test('dark and light colors should be different', () {
        // Act
        final dark = IdeColors.dark;
        final light = IdeColors.light;

        // Assert
        expect(dark.editorBackground, isNot(equals(light.editorBackground)));
      });
    });

    group('SyntaxColors', () {
      test('should have dark syntax colors', () {
        // Act
        final colors = SyntaxColors.dark;

        // Assert
        expect(colors.keyword, isNotNull);
        expect(colors.string, isNotNull);
        expect(colors.comment, isNotNull);
        expect(colors.number, isNotNull);
        expect(colors.className, isNotNull);
        expect(colors.functionName, isNotNull);
      });

      test('should have light syntax colors', () {
        // Act
        final colors = SyntaxColors.light;

        // Assert
        expect(colors.keyword, isNotNull);
        expect(colors.string, isNotNull);
        expect(colors.comment, isNotNull);
        expect(colors.number, isNotNull);
        expect(colors.className, isNotNull);
        expect(colors.functionName, isNotNull);
      });

      test('dark and light syntax colors should be different', () {
        // Act
        final dark = SyntaxColors.dark;
        final light = SyntaxColors.light;

        // Assert
        expect(dark.keyword, isNot(equals(light.keyword)));
        expect(dark.string, isNot(equals(light.string)));
      });

      test('should have distinct colors for different syntax elements', () {
        // Act
        final colors = SyntaxColors.dark;

        // Assert
        expect(colors.keyword, isNot(equals(colors.string)));
        expect(colors.keyword, isNot(equals(colors.comment)));
        expect(colors.string, isNot(equals(colors.number)));
      });
    });

    group('theme consistency', () {
      test('dark theme should have consistent color scheme', () {
        // Act
        final theme = IdeTheme.dark;

        // Assert
        expect(
          theme.colorScheme.brightness,
          equals(theme.brightness),
        );
        expect(
          theme.scaffoldBackgroundColor,
          equals(theme.colorScheme.background),
        );
      });

      test('light theme should have consistent color scheme', () {
        // Act
        final theme = IdeTheme.light;

        // Assert
        expect(
          theme.colorScheme.brightness,
          equals(theme.brightness),
        );
        expect(
          theme.scaffoldBackgroundColor,
          equals(theme.colorScheme.background),
        );
      });
    });
  });
}
