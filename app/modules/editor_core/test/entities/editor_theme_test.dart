import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('EditorTheme', () {
    group('creation', () {
      test('should create theme with id, name, and mode', () {
        // Act
        const theme = EditorTheme(
          id: 'custom-theme',
          name: 'Custom Theme',
          mode: ThemeMode.dark,
        );

        // Assert
        expect(theme.id, equals('custom-theme'));
        expect(theme.name, equals('Custom Theme'));
        expect(theme.mode, equals(ThemeMode.dark));
      });
    });

    group('predefined themes', () {
      test('should have light theme', () {
        // Arrange
        const theme = EditorTheme.light;

        // Assert
        expect(theme.id, equals('light'));
        expect(theme.name, equals('Light'));
        expect(theme.mode, equals(ThemeMode.light));
      });

      test('should have dark theme', () {
        // Arrange
        const theme = EditorTheme.dark;

        // Assert
        expect(theme.id, equals('dark'));
        expect(theme.name, equals('Dark'));
        expect(theme.mode, equals(ThemeMode.dark));
      });

      test('should have high contrast theme', () {
        // Arrange
        const theme = EditorTheme.highContrast;

        // Assert
        expect(theme.id, equals('high-contrast'));
        expect(theme.name, equals('High Contrast'));
        expect(theme.mode, equals(ThemeMode.dark));
      });

      test('should have all defaults', () {
        // Arrange
        const themes = EditorTheme.defaults;

        // Assert
        expect(themes.length, equals(3));
        expect(themes, contains(EditorTheme.light));
        expect(themes, contains(EditorTheme.dark));
        expect(themes, contains(EditorTheme.highContrast));
      });
    });

    group('ThemeMode', () {
      test('should have light mode', () {
        expect(ThemeMode.values, contains(ThemeMode.light));
      });

      test('should have dark mode', () {
        expect(ThemeMode.values, contains(ThemeMode.dark));
      });

      test('should have only two modes', () {
        expect(ThemeMode.values.length, equals(2));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        const theme1 = EditorTheme(
          id: 'test',
          name: 'Test',
          mode: ThemeMode.light,
        );

        const theme2 = EditorTheme(
          id: 'test',
          name: 'Test',
          mode: ThemeMode.light,
        );

        expect(theme1, equals(theme2));
        expect(theme1.hashCode, equals(theme2.hashCode));
      });

      test('should not be equal with different id', () {
        const theme1 = EditorTheme(
          id: 'theme1',
          name: 'Theme',
          mode: ThemeMode.light,
        );

        const theme2 = EditorTheme(
          id: 'theme2',
          name: 'Theme',
          mode: ThemeMode.light,
        );

        expect(theme1, isNot(equals(theme2)));
      });

      test('should not be equal with different mode', () {
        const theme1 = EditorTheme(
          id: 'test',
          name: 'Test',
          mode: ThemeMode.light,
        );

        const theme2 = EditorTheme(
          id: 'test',
          name: 'Test',
          mode: ThemeMode.dark,
        );

        expect(theme1, isNot(equals(theme2)));
      });
    });

    group('custom themes', () {
      test('should support custom light theme', () {
        const theme = EditorTheme(
          id: 'solarized-light',
          name: 'Solarized Light',
          mode: ThemeMode.light,
        );

        expect(theme.mode, equals(ThemeMode.light));
      });

      test('should support custom dark theme', () {
        const theme = EditorTheme(
          id: 'dracula',
          name: 'Dracula',
          mode: ThemeMode.dark,
        );

        expect(theme.mode, equals(ThemeMode.dark));
      });
    });

    group('copyWith', () {
      test('should copy with new id', () {
        const theme = EditorTheme.light;

        final copied = theme.copyWith(id: 'custom-light');

        expect(copied.id, equals('custom-light'));
        expect(copied.name, equals(theme.name));
        expect(copied.mode, equals(theme.mode));
      });

      test('should copy with new name', () {
        const theme = EditorTheme.dark;

        final copied = theme.copyWith(name: 'My Dark Theme');

        expect(copied.name, equals('My Dark Theme'));
        expect(copied.id, equals(theme.id));
      });

      test('should copy with new mode', () {
        const theme = EditorTheme.light;

        final copied = theme.copyWith(mode: ThemeMode.dark);

        expect(copied.mode, equals(ThemeMode.dark));
        expect(theme.mode, equals(ThemeMode.light)); // immutability
      });
    });
  });
}
