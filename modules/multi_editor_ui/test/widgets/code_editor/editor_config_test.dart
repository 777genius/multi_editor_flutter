import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/widgets/code_editor/editor_config.dart';

void main() {
  group('EditorConfig Tests', () {
    group('Default Values', () {
      test('should create EditorConfig with default values', () {
        // Arrange & Act
        const config = EditorConfig();

        // Assert
        expect(config.fontSize, equals(14.0));
        expect(config.fontFamily, equals('Consolas, Monaco, monospace'));
        expect(config.showMinimap, equals(false));
        expect(config.wordWrap, equals(true));
        expect(config.tabSize, equals(2));
        expect(config.showLineNumbers, equals(true));
        expect(config.bracketPairColorization, equals(true));
        expect(config.showStatusBar, equals(true));
        expect(config.autoSave, equals(true));
        expect(config.autoSaveDelay, equals(2));
      });
    });

    group('Custom Values', () {
      test('should create EditorConfig with custom fontSize', () {
        // Arrange & Act
        const config = EditorConfig(fontSize: 16.0);

        // Assert
        expect(config.fontSize, equals(16.0));
        expect(config.fontFamily, equals('Consolas, Monaco, monospace'));
      });

      test('should create EditorConfig with custom fontFamily', () {
        // Arrange & Act
        const config = EditorConfig(fontFamily: 'Fira Code');

        // Assert
        expect(config.fontFamily, equals('Fira Code'));
        expect(config.fontSize, equals(14.0));
      });

      test('should create EditorConfig with custom boolean flags', () {
        // Arrange & Act
        const config = EditorConfig(
          showMinimap: true,
          wordWrap: false,
          showLineNumbers: false,
          bracketPairColorization: false,
          showStatusBar: false,
          autoSave: false,
        );

        // Assert
        expect(config.showMinimap, equals(true));
        expect(config.wordWrap, equals(false));
        expect(config.showLineNumbers, equals(false));
        expect(config.bracketPairColorization, equals(false));
        expect(config.showStatusBar, equals(false));
        expect(config.autoSave, equals(false));
      });

      test('should create EditorConfig with custom tabSize', () {
        // Arrange & Act
        const config = EditorConfig(tabSize: 4);

        // Assert
        expect(config.tabSize, equals(4));
      });

      test('should create EditorConfig with custom autoSaveDelay', () {
        // Arrange & Act
        const config = EditorConfig(autoSaveDelay: 5);

        // Assert
        expect(config.autoSaveDelay, equals(5));
      });

      test('should create EditorConfig with all custom values', () {
        // Arrange & Act
        const config = EditorConfig(
          fontSize: 18.0,
          fontFamily: 'JetBrains Mono',
          showMinimap: true,
          wordWrap: false,
          tabSize: 8,
          showLineNumbers: false,
          bracketPairColorization: false,
          showStatusBar: false,
          autoSave: false,
          autoSaveDelay: 10,
        );

        // Assert
        expect(config.fontSize, equals(18.0));
        expect(config.fontFamily, equals('JetBrains Mono'));
        expect(config.showMinimap, equals(true));
        expect(config.wordWrap, equals(false));
        expect(config.tabSize, equals(8));
        expect(config.showLineNumbers, equals(false));
        expect(config.bracketPairColorization, equals(false));
        expect(config.showStatusBar, equals(false));
        expect(config.autoSave, equals(false));
        expect(config.autoSaveDelay, equals(10));
      });
    });

    group('CopyWith', () {
      test('should copy EditorConfig with modified fontSize', () {
        // Arrange
        const original = EditorConfig();

        // Act
        final modified = original.copyWith(fontSize: 20.0);

        // Assert
        expect(modified.fontSize, equals(20.0));
        expect(modified.fontFamily, equals(original.fontFamily));
        expect(modified.showMinimap, equals(original.showMinimap));
      });

      test('should copy EditorConfig with modified fontFamily', () {
        // Arrange
        const original = EditorConfig();

        // Act
        final modified = original.copyWith(fontFamily: 'Source Code Pro');

        // Assert
        expect(modified.fontFamily, equals('Source Code Pro'));
        expect(modified.fontSize, equals(original.fontSize));
      });

      test('should copy EditorConfig with modified boolean flags', () {
        // Arrange
        const original = EditorConfig();

        // Act
        final modified = original.copyWith(
          showMinimap: true,
          wordWrap: false,
          showLineNumbers: false,
        );

        // Assert
        expect(modified.showMinimap, equals(true));
        expect(modified.wordWrap, equals(false));
        expect(modified.showLineNumbers, equals(false));
        expect(modified.bracketPairColorization, equals(original.bracketPairColorization));
      });

      test('should copy EditorConfig with modified tabSize', () {
        // Arrange
        const original = EditorConfig();

        // Act
        final modified = original.copyWith(tabSize: 4);

        // Assert
        expect(modified.tabSize, equals(4));
        expect(modified.fontSize, equals(original.fontSize));
      });

      test('should copy EditorConfig with modified autoSave settings', () {
        // Arrange
        const original = EditorConfig();

        // Act
        final modified = original.copyWith(
          autoSave: false,
          autoSaveDelay: 10,
        );

        // Assert
        expect(modified.autoSave, equals(false));
        expect(modified.autoSaveDelay, equals(10));
      });

      test('should copy EditorConfig with multiple modifications', () {
        // Arrange
        const original = EditorConfig(
          fontSize: 14.0,
          fontFamily: 'Consolas',
          tabSize: 2,
        );

        // Act
        final modified = original.copyWith(
          fontSize: 16.0,
          tabSize: 4,
          showMinimap: true,
        );

        // Assert
        expect(modified.fontSize, equals(16.0));
        expect(modified.fontFamily, equals('Consolas'));
        expect(modified.tabSize, equals(4));
        expect(modified.showMinimap, equals(true));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        const config1 = EditorConfig();
        const config2 = EditorConfig();

        // Act & Assert
        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('should be equal when custom values are the same', () {
        // Arrange
        const config1 = EditorConfig(
          fontSize: 16.0,
          fontFamily: 'Fira Code',
          tabSize: 4,
        );
        const config2 = EditorConfig(
          fontSize: 16.0,
          fontFamily: 'Fira Code',
          tabSize: 4,
        );

        // Act & Assert
        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('should not be equal when fontSize differs', () {
        // Arrange
        const config1 = EditorConfig(fontSize: 14.0);
        const config2 = EditorConfig(fontSize: 16.0);

        // Act & Assert
        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when fontFamily differs', () {
        // Arrange
        const config1 = EditorConfig(fontFamily: 'Consolas');
        const config2 = EditorConfig(fontFamily: 'Fira Code');

        // Act & Assert
        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when boolean flags differ', () {
        // Arrange
        const config1 = EditorConfig(showMinimap: false);
        const config2 = EditorConfig(showMinimap: true);

        // Act & Assert
        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when tabSize differs', () {
        // Arrange
        const config1 = EditorConfig(tabSize: 2);
        const config2 = EditorConfig(tabSize: 4);

        // Act & Assert
        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when autoSaveDelay differs', () {
        // Arrange
        const config1 = EditorConfig(autoSaveDelay: 2);
        const config2 = EditorConfig(autoSaveDelay: 5);

        // Act & Assert
        expect(config1, isNot(equals(config2)));
      });
    });

    group('Edge Cases', () {
      test('should handle very small fontSize', () {
        // Arrange & Act
        const config = EditorConfig(fontSize: 8.0);

        // Assert
        expect(config.fontSize, equals(8.0));
      });

      test('should handle very large fontSize', () {
        // Arrange & Act
        const config = EditorConfig(fontSize: 72.0);

        // Assert
        expect(config.fontSize, equals(72.0));
      });

      test('should handle zero tabSize', () {
        // Arrange & Act
        const config = EditorConfig(tabSize: 0);

        // Assert
        expect(config.tabSize, equals(0));
      });

      test('should handle large tabSize', () {
        // Arrange & Act
        const config = EditorConfig(tabSize: 16);

        // Assert
        expect(config.tabSize, equals(16));
      });

      test('should handle zero autoSaveDelay', () {
        // Arrange & Act
        const config = EditorConfig(autoSaveDelay: 0);

        // Assert
        expect(config.autoSaveDelay, equals(0));
      });

      test('should handle empty fontFamily string', () {
        // Arrange & Act
        const config = EditorConfig(fontFamily: '');

        // Assert
        expect(config.fontFamily, equals(''));
      });

      test('should handle special characters in fontFamily', () {
        // Arrange & Act
        const config = EditorConfig(fontFamily: 'Font-Name_123, fallback');

        // Assert
        expect(config.fontFamily, equals('Font-Name_123, fallback'));
      });
    });

    group('Use Cases', () {
      test('UC1: VSCode-like configuration', () {
        // Arrange & Act
        const config = EditorConfig(
          fontSize: 14.0,
          fontFamily: 'Consolas, Monaco, monospace',
          tabSize: 2,
          showLineNumbers: true,
          wordWrap: true,
          autoSave: true,
          autoSaveDelay: 2,
        );

        // Assert
        expect(config.fontSize, equals(14.0));
        expect(config.tabSize, equals(2));
        expect(config.showLineNumbers, isTrue);
        expect(config.wordWrap, isTrue);
        expect(config.autoSave, isTrue);
      });

      test('UC2: Minimal editor configuration', () {
        // Arrange & Act
        const config = EditorConfig(
          showMinimap: false,
          showStatusBar: false,
          showLineNumbers: false,
          bracketPairColorization: false,
        );

        // Assert
        expect(config.showMinimap, isFalse);
        expect(config.showStatusBar, isFalse);
        expect(config.showLineNumbers, isFalse);
        expect(config.bracketPairColorization, isFalse);
      });

      test('UC3: Accessibility - large font configuration', () {
        // Arrange & Act
        const config = EditorConfig(
          fontSize: 24.0,
          showLineNumbers: true,
          wordWrap: true,
        );

        // Assert
        expect(config.fontSize, equals(24.0));
        expect(config.showLineNumbers, isTrue);
        expect(config.wordWrap, isTrue);
      });

      test('UC4: Python developer configuration', () {
        // Arrange & Act
        const config = EditorConfig(
          tabSize: 4,
          fontFamily: 'Fira Code',
          bracketPairColorization: true,
          autoSave: true,
        );

        // Assert
        expect(config.tabSize, equals(4));
        expect(config.fontFamily, equals('Fira Code'));
        expect(config.bracketPairColorization, isTrue);
      });

      test('UC5: Toggling features at runtime', () {
        // Arrange
        const initial = EditorConfig();

        // Act - User toggles minimap
        final withMinimap = initial.copyWith(showMinimap: true);
        // User toggles word wrap
        final withoutWrap = withMinimap.copyWith(wordWrap: false);
        // User increases font size
        final largerFont = withoutWrap.copyWith(fontSize: 18.0);

        // Assert
        expect(initial.showMinimap, isFalse);
        expect(withMinimap.showMinimap, isTrue);
        expect(withoutWrap.wordWrap, isFalse);
        expect(largerFont.fontSize, equals(18.0));
        // Verify other properties remain unchanged
        expect(largerFont.showMinimap, isTrue);
        expect(largerFont.wordWrap, isFalse);
      });

      test('UC6: Creating preset configurations', () {
        // Arrange & Act
        const compactPreset = EditorConfig(
          fontSize: 12.0,
          showMinimap: false,
          showStatusBar: false,
          tabSize: 2,
        );

        const readablePreset = EditorConfig(
          fontSize: 16.0,
          showMinimap: true,
          showLineNumbers: true,
          wordWrap: true,
          tabSize: 4,
        );

        // Assert
        expect(compactPreset.fontSize, lessThan(readablePreset.fontSize));
        expect(compactPreset.showMinimap, isFalse);
        expect(readablePreset.showMinimap, isTrue);
      });
    });

    group('Immutability', () {
      test('should not mutate original when using copyWith', () {
        // Arrange
        const original = EditorConfig(fontSize: 14.0, tabSize: 2);

        // Act
        final modified = original.copyWith(fontSize: 20.0, tabSize: 4);

        // Assert
        expect(original.fontSize, equals(14.0));
        expect(original.tabSize, equals(2));
        expect(modified.fontSize, equals(20.0));
        expect(modified.tabSize, equals(4));
      });

      test('should create independent instances', () {
        // Arrange
        const config1 = EditorConfig(fontSize: 14.0);

        // Act
        final config2 = config1.copyWith(fontSize: 16.0);
        final config3 = config2.copyWith(fontSize: 18.0);

        // Assert
        expect(config1.fontSize, equals(14.0));
        expect(config2.fontSize, equals(16.0));
        expect(config3.fontSize, equals(18.0));
      });
    });
  });
}
