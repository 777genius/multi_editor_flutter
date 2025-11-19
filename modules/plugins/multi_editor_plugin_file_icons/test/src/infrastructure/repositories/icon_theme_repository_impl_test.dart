import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/entities/icon_theme.dart';
import 'package:multi_editor_plugin_file_icons/src/infrastructure/repositories/icon_theme_repository_impl.dart';

void main() {
  group('IconThemeRepositoryImpl', () {
    late IconThemeRepositoryImpl repository;

    setUp(() {
      repository = IconThemeRepositoryImpl();
    });

    group('initialization', () {
      test('should register default theme on initialization', () async {
        // Act
        final themes = await repository.getAvailableThemes();

        // Assert
        expect(themes, isNotEmpty);
        expect(themes.length, 1);
        expect(themes.first.id, 'iconify-vscode');
        expect(themes.first.name, 'VSCode Icons (Iconify)');
        expect(themes.first.provider, 'iconify');
        expect(themes.first.isActive, true);
      });

      test('should set default theme as active', () async {
        // Act
        final activeTheme = await repository.getActiveTheme();

        // Assert
        expect(activeTheme, isNotNull);
        expect(activeTheme?.id, 'iconify-vscode');
        expect(activeTheme?.isActive, true);
      });

      test('should have default theme with correct properties', () async {
        // Act
        final theme = await repository.getTheme('iconify-vscode');

        // Assert
        expect(theme, isNotNull);
        expect(theme?.baseUrl, 'https://api.iconify.design');
        expect(theme?.priority, 50);
      });
    });

    group('getAvailableThemes', () {
      test('should return all registered themes', () async {
        // Arrange
        const customTheme = IconTheme(
          id: 'custom-theme',
          name: 'Custom Theme',
          provider: 'custom',
          baseUrl: 'https://custom.com',
        );
        await repository.registerTheme(customTheme);

        // Act
        final themes = await repository.getAvailableThemes();

        // Assert
        expect(themes.length, 2);
        expect(themes.any((t) => t.id == 'iconify-vscode'), true);
        expect(themes.any((t) => t.id == 'custom-theme'), true);
      });

      test('should return only default theme initially', () async {
        // Act
        final themes = await repository.getAvailableThemes();

        // Assert
        expect(themes.length, 1);
        expect(themes.first.id, 'iconify-vscode');
      });

      test('should return updated list after registering new themes', () async {
        // Arrange
        const theme1 = IconTheme(
          id: 'theme1',
          name: 'Theme 1',
          provider: 'provider1',
          baseUrl: 'https://theme1.com',
        );
        const theme2 = IconTheme(
          id: 'theme2',
          name: 'Theme 2',
          provider: 'provider2',
          baseUrl: 'https://theme2.com',
        );

        // Act
        await repository.registerTheme(theme1);
        final themesAfter1 = await repository.getAvailableThemes();

        await repository.registerTheme(theme2);
        final themesAfter2 = await repository.getAvailableThemes();

        // Assert
        expect(themesAfter1.length, 2);
        expect(themesAfter2.length, 3);
      });

      test('should not modify themes when getting available themes', () async {
        // Arrange
        final beforeThemes = await repository.getAvailableThemes();
        final beforeCount = beforeThemes.length;

        // Act
        await repository.getAvailableThemes();
        final afterThemes = await repository.getAvailableThemes();

        // Assert
        expect(afterThemes.length, beforeCount);
      });
    });

    group('getActiveTheme', () {
      test('should return active theme', () async {
        // Act
        final activeTheme = await repository.getActiveTheme();

        // Assert
        expect(activeTheme, isNotNull);
        expect(activeTheme?.isActive, true);
        expect(activeTheme?.id, 'iconify-vscode');
      });

      test('should return new active theme after setActiveTheme', () async {
        // Arrange
        const newTheme = IconTheme(
          id: 'new-theme',
          name: 'New Theme',
          provider: 'new',
          baseUrl: 'https://new.com',
        );
        await repository.registerTheme(newTheme);

        // Act
        await repository.setActiveTheme('new-theme');
        final activeTheme = await repository.getActiveTheme();

        // Assert
        expect(activeTheme, isNotNull);
        expect(activeTheme?.id, 'new-theme');
        expect(activeTheme?.isActive, true);
      });

      test('should maintain active theme after getting available themes', () async {
        // Arrange
        final initialActive = await repository.getActiveTheme();

        // Act
        await repository.getAvailableThemes();
        final activeAfter = await repository.getActiveTheme();

        // Assert
        expect(activeAfter?.id, initialActive?.id);
      });
    });

    group('setActiveTheme', () {
      test('should set theme as active when it exists', () async {
        // Arrange
        const newTheme = IconTheme(
          id: 'custom-theme',
          name: 'Custom Theme',
          provider: 'custom',
          baseUrl: 'https://custom.com',
        );
        await repository.registerTheme(newTheme);

        // Act
        await repository.setActiveTheme('custom-theme');

        // Assert
        final activeTheme = await repository.getActiveTheme();
        expect(activeTheme?.id, 'custom-theme');
        expect(activeTheme?.isActive, true);
      });

      test('should deactivate previous active theme', () async {
        // Arrange
        const newTheme = IconTheme(
          id: 'new-theme',
          name: 'New Theme',
          provider: 'new',
          baseUrl: 'https://new.com',
        );
        await repository.registerTheme(newTheme);

        // Act
        await repository.setActiveTheme('new-theme');

        // Assert
        final oldTheme = await repository.getTheme('iconify-vscode');
        expect(oldTheme?.isActive, false);
      });

      test('should not change active theme when theme does not exist', () async {
        // Arrange
        final beforeActive = await repository.getActiveTheme();

        // Act
        await repository.setActiveTheme('non-existent-theme');

        // Assert
        final afterActive = await repository.getActiveTheme();
        expect(afterActive?.id, beforeActive?.id);
      });

      test('should handle setting same theme as active again', () async {
        // Arrange
        const themeId = 'iconify-vscode';

        // Act
        await repository.setActiveTheme(themeId);

        // Assert
        final activeTheme = await repository.getActiveTheme();
        expect(activeTheme?.id, themeId);
        expect(activeTheme?.isActive, true);
      });

      test('should ensure only one theme is active at a time', () async {
        // Arrange
        const theme1 = IconTheme(
          id: 'theme1',
          name: 'Theme 1',
          provider: 'provider1',
          baseUrl: 'https://theme1.com',
        );
        const theme2 = IconTheme(
          id: 'theme2',
          name: 'Theme 2',
          provider: 'provider2',
          baseUrl: 'https://theme2.com',
        );
        await repository.registerTheme(theme1);
        await repository.registerTheme(theme2);

        // Act
        await repository.setActiveTheme('theme1');
        await repository.setActiveTheme('theme2');

        // Assert
        final themes = await repository.getAvailableThemes();
        final activeThemes = themes.where((t) => t.isActive).toList();
        expect(activeThemes.length, 1);
        expect(activeThemes.first.id, 'theme2');
      });

      test('should handle rapid theme switching', () async {
        // Arrange
        const theme1 = IconTheme(id: 'theme1', name: 'T1', provider: 'p1', baseUrl: 'url1');
        const theme2 = IconTheme(id: 'theme2', name: 'T2', provider: 'p2', baseUrl: 'url2');
        const theme3 = IconTheme(id: 'theme3', name: 'T3', provider: 'p3', baseUrl: 'url3');
        await repository.registerTheme(theme1);
        await repository.registerTheme(theme2);
        await repository.registerTheme(theme3);

        // Act
        await repository.setActiveTheme('theme1');
        await repository.setActiveTheme('theme2');
        await repository.setActiveTheme('theme3');

        // Assert
        final activeTheme = await repository.getActiveTheme();
        expect(activeTheme?.id, 'theme3');
      });
    });

    group('getTheme', () {
      test('should return theme when it exists', () async {
        // Act
        final theme = await repository.getTheme('iconify-vscode');

        // Assert
        expect(theme, isNotNull);
        expect(theme?.id, 'iconify-vscode');
      });

      test('should return null when theme does not exist', () async {
        // Act
        final theme = await repository.getTheme('non-existent');

        // Assert
        expect(theme, isNull);
      });

      test('should return correct theme for custom registered theme', () async {
        // Arrange
        const customTheme = IconTheme(
          id: 'custom',
          name: 'Custom Theme',
          provider: 'custom-provider',
          baseUrl: 'https://custom.com',
          priority: 99,
        );
        await repository.registerTheme(customTheme);

        // Act
        final theme = await repository.getTheme('custom');

        // Assert
        expect(theme, isNotNull);
        expect(theme?.id, 'custom');
        expect(theme?.name, 'Custom Theme');
        expect(theme?.provider, 'custom-provider');
        expect(theme?.baseUrl, 'https://custom.com');
        expect(theme?.priority, 99);
      });

      test('should handle multiple getTheme calls', () async {
        // Act
        final theme1 = await repository.getTheme('iconify-vscode');
        final theme2 = await repository.getTheme('iconify-vscode');

        // Assert
        expect(theme1?.id, theme2?.id);
      });
    });

    group('registerTheme', () {
      test('should register new theme', () async {
        // Arrange
        const newTheme = IconTheme(
          id: 'new-theme',
          name: 'New Theme',
          provider: 'new',
          baseUrl: 'https://new.com',
        );

        // Act
        await repository.registerTheme(newTheme);

        // Assert
        final theme = await repository.getTheme('new-theme');
        expect(theme, isNotNull);
        expect(theme?.id, 'new-theme');
      });

      test('should replace existing theme with same id', () async {
        // Arrange
        const theme1 = IconTheme(
          id: 'theme',
          name: 'Original',
          provider: 'provider1',
          baseUrl: 'https://original.com',
        );
        const theme2 = IconTheme(
          id: 'theme',
          name: 'Updated',
          provider: 'provider2',
          baseUrl: 'https://updated.com',
        );

        // Act
        await repository.registerTheme(theme1);
        await repository.registerTheme(theme2);

        // Assert
        final theme = await repository.getTheme('theme');
        expect(theme?.name, 'Updated');
        expect(theme?.baseUrl, 'https://updated.com');
      });

      test('should register multiple themes', () async {
        // Arrange
        const theme1 = IconTheme(id: 'theme1', name: 'Theme 1', provider: 'p1', baseUrl: 'url1');
        const theme2 = IconTheme(id: 'theme2', name: 'Theme 2', provider: 'p2', baseUrl: 'url2');
        const theme3 = IconTheme(id: 'theme3', name: 'Theme 3', provider: 'p3', baseUrl: 'url3');

        // Act
        await repository.registerTheme(theme1);
        await repository.registerTheme(theme2);
        await repository.registerTheme(theme3);

        // Assert
        final themes = await repository.getAvailableThemes();
        expect(themes.length, 4); // 3 custom + 1 default
        expect(themes.any((t) => t.id == 'theme1'), true);
        expect(themes.any((t) => t.id == 'theme2'), true);
        expect(themes.any((t) => t.id == 'theme3'), true);
      });

      test('should preserve theme properties when registering', () async {
        // Arrange
        const theme = IconTheme(
          id: 'custom',
          name: 'Custom Theme',
          provider: 'custom',
          baseUrl: 'https://custom.com',
          priority: 25,
          isActive: false,
          supportedExtensions: ['dart', 'js', 'ts'],
          metadata: {'version': '1.0', 'author': 'Test'},
        );

        // Act
        await repository.registerTheme(theme);

        // Assert
        final registered = await repository.getTheme('custom');
        expect(registered?.id, theme.id);
        expect(registered?.name, theme.name);
        expect(registered?.provider, theme.provider);
        expect(registered?.baseUrl, theme.baseUrl);
        expect(registered?.priority, theme.priority);
        expect(registered?.isActive, theme.isActive);
        expect(registered?.supportedExtensions, theme.supportedExtensions);
        expect(registered?.metadata, theme.metadata);
      });
    });

    group('hasTheme', () {
      test('should return true for existing theme', () async {
        // Act
        final has = await repository.hasTheme('iconify-vscode');

        // Assert
        expect(has, true);
      });

      test('should return false for non-existent theme', () async {
        // Act
        final has = await repository.hasTheme('non-existent');

        // Assert
        expect(has, false);
      });

      test('should return true after registering theme', () async {
        // Arrange
        const theme = IconTheme(
          id: 'new-theme',
          name: 'New',
          provider: 'new',
          baseUrl: 'https://new.com',
        );

        // Act
        final beforeRegister = await repository.hasTheme('new-theme');
        await repository.registerTheme(theme);
        final afterRegister = await repository.hasTheme('new-theme');

        // Assert
        expect(beforeRegister, false);
        expect(afterRegister, true);
      });

      test('should handle multiple hasTheme calls', () async {
        // Act
        final has1 = await repository.hasTheme('iconify-vscode');
        final has2 = await repository.hasTheme('iconify-vscode');

        // Assert
        expect(has1, true);
        expect(has2, true);
      });

      test('should check for different themes', () async {
        // Arrange
        const theme = IconTheme(
          id: 'custom',
          name: 'Custom',
          provider: 'custom',
          baseUrl: 'url',
        );
        await repository.registerTheme(theme);

        // Act & Assert
        expect(await repository.hasTheme('iconify-vscode'), true);
        expect(await repository.hasTheme('custom'), true);
        expect(await repository.hasTheme('non-existent'), false);
      });
    });

    group('integration tests', () {
      test('should handle complete theme lifecycle', () async {
        // Arrange
        const theme = IconTheme(
          id: 'lifecycle-theme',
          name: 'Lifecycle Theme',
          provider: 'lifecycle',
          baseUrl: 'https://lifecycle.com',
        );

        // Act & Assert - Check theme doesn't exist
        expect(await repository.hasTheme('lifecycle-theme'), false);

        // Register theme
        await repository.registerTheme(theme);
        expect(await repository.hasTheme('lifecycle-theme'), true);

        // Get theme
        final registered = await repository.getTheme('lifecycle-theme');
        expect(registered?.id, 'lifecycle-theme');

        // Verify in available themes
        final themes = await repository.getAvailableThemes();
        expect(themes.any((t) => t.id == 'lifecycle-theme'), true);

        // Set as active
        await repository.setActiveTheme('lifecycle-theme');
        final active = await repository.getActiveTheme();
        expect(active?.id, 'lifecycle-theme');
      });

      test('should handle multiple themes with priority sorting', () async {
        // Arrange
        const highPriority = IconTheme(
          id: 'high',
          name: 'High',
          provider: 'p',
          baseUrl: 'url',
          priority: 1,
        );
        const mediumPriority = IconTheme(
          id: 'medium',
          name: 'Medium',
          provider: 'p',
          baseUrl: 'url',
          priority: 50,
        );
        const lowPriority = IconTheme(
          id: 'low',
          name: 'Low',
          provider: 'p',
          baseUrl: 'url',
          priority: 100,
        );

        // Act
        await repository.registerTheme(lowPriority);
        await repository.registerTheme(highPriority);
        await repository.registerTheme(mediumPriority);

        // Assert
        final high = await repository.getTheme('high');
        final medium = await repository.getTheme('medium');
        final low = await repository.getTheme('low');
        expect(high?.priority, 1);
        expect(medium?.priority, 50);
        expect(low?.priority, 100);
      });

      test('should handle theme switching workflow', () async {
        // Arrange
        const theme1 = IconTheme(id: 't1', name: 'T1', provider: 'p', baseUrl: 'u');
        const theme2 = IconTheme(id: 't2', name: 'T2', provider: 'p', baseUrl: 'u');
        await repository.registerTheme(theme1);
        await repository.registerTheme(theme2);

        // Act & Assert
        await repository.setActiveTheme('t1');
        expect((await repository.getActiveTheme())?.id, 't1');
        expect((await repository.getTheme('t1'))?.isActive, true);
        expect((await repository.getTheme('t2'))?.isActive, false);

        await repository.setActiveTheme('t2');
        expect((await repository.getActiveTheme())?.id, 't2');
        expect((await repository.getTheme('t1'))?.isActive, false);
        expect((await repository.getTheme('t2'))?.isActive, true);
      });

      test('should handle theme update workflow', () async {
        // Arrange
        const originalTheme = IconTheme(
          id: 'updatable',
          name: 'Original',
          provider: 'p1',
          baseUrl: 'url1',
          priority: 50,
        );
        const updatedTheme = IconTheme(
          id: 'updatable',
          name: 'Updated',
          provider: 'p2',
          baseUrl: 'url2',
          priority: 25,
        );

        // Act
        await repository.registerTheme(originalTheme);
        final before = await repository.getTheme('updatable');

        await repository.registerTheme(updatedTheme);
        final after = await repository.getTheme('updatable');

        // Assert
        expect(before?.name, 'Original');
        expect(before?.priority, 50);
        expect(after?.name, 'Updated');
        expect(after?.priority, 25);
      });
    });

    group('edge cases', () {
      test('should handle empty theme id', () async {
        // Act
        final theme = await repository.getTheme('');
        final has = await repository.hasTheme('');

        // Assert
        expect(theme, isNull);
        expect(has, false);
      });

      test('should handle very long theme id', () async {
        // Arrange
        final longId = 'a' * 1000;
        final theme = IconTheme(
          id: longId,
          name: 'Long ID Theme',
          provider: 'p',
          baseUrl: 'url',
        );

        // Act
        await repository.registerTheme(theme);
        final retrieved = await repository.getTheme(longId);

        // Assert
        expect(retrieved?.id, longId);
      });

      test('should handle special characters in theme id', () async {
        // Arrange
        const specialId = 'theme-with_special.chars@123';
        const theme = IconTheme(
          id: specialId,
          name: 'Special',
          provider: 'p',
          baseUrl: 'url',
        );

        // Act
        await repository.registerTheme(theme);
        final retrieved = await repository.getTheme(specialId);

        // Assert
        expect(retrieved?.id, specialId);
      });

      test('should handle theme with empty supported extensions', () async {
        // Arrange
        const theme = IconTheme(
          id: 'empty-ext',
          name: 'Empty Extensions',
          provider: 'p',
          baseUrl: 'url',
          supportedExtensions: [],
        );

        // Act
        await repository.registerTheme(theme);
        final retrieved = await repository.getTheme('empty-ext');

        // Assert
        expect(retrieved?.supportedExtensions, isEmpty);
      });

      test('should handle theme with empty metadata', () async {
        // Arrange
        const theme = IconTheme(
          id: 'empty-meta',
          name: 'Empty Metadata',
          provider: 'p',
          baseUrl: 'url',
          metadata: {},
        );

        // Act
        await repository.registerTheme(theme);
        final retrieved = await repository.getTheme('empty-meta');

        // Assert
        expect(retrieved?.metadata, isEmpty);
      });
    });
  });
}
