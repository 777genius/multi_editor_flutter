import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test all exports from the app_theme library
import 'package:multi_editor_ui/src/theme/app_theme.dart';

void main() {
  group('AppTheme Library', () {
    group('core theme exports', () {
      test('should export AppThemeData', () {
        // Arrange & Act & Assert
        expect(AppThemeData.light, isNotNull);
        expect(AppThemeData.dark, isNotNull);
      });

      test('should export EditorThemeExtension', () {
        // Arrange
        final lightTheme = AppThemeData.light();
        final extension = lightTheme.extensions[EditorThemeExtension];

        // Act & Assert
        expect(extension, isNotNull);
        expect(extension, isA<EditorThemeExtension>());
      });
    });

    group('primitive token exports', () {
      test('should export ColorPrimitives', () {
        // Arrange & Act & Assert
        expect(ColorPrimitives.neutral0, isNotNull);
        expect(ColorPrimitives.neutral0, isA<Color>());
      });

      test('should export SizePrimitives', () {
        // Arrange & Act & Assert
        expect(SizePrimitives.size0, isNotNull);
        expect(SizePrimitives.size0, equals(0.0));
      });

      test('should export FontPrimitives', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontFamilySans, isNotNull);
        expect(FontPrimitives.fontFamilySans, isNotEmpty);
        expect(FontPrimitives.fontSize14, equals(14.0));
      });
    });

    group('semantic token exports', () {
      test('should export ColorSemantic', () {
        // Arrange & Act
        final lightColors = ColorSemantic.light();
        final darkColors = ColorSemantic.dark();

        // Assert
        expect(lightColors, isNotNull);
        expect(lightColors.background, isA<Color>());
        expect(darkColors, isNotNull);
        expect(darkColors.background, isA<Color>());
      });
    });

    group('system exports', () {
      test('should export AppSpacing', () {
        // Arrange & Act & Assert
        expect(AppSpacing.xs, isNotNull);
        expect(AppSpacing.xs, isA<double>());
      });

      test('should export AppRadius', () {
        // Arrange & Act & Assert
        expect(AppRadius.xs, isNotNull);
        expect(AppRadius.xs, isA<Radius>());
      });

      test('should export AppElevation', () {
        // Arrange & Act & Assert
        expect(AppElevation.level0, isNotNull);
        expect(AppElevation.level0, isA<double>());
      });

      test('should export AppTypography', () {
        // Arrange & Act
        final typography = AppTypography.fromColorScheme(
          ColorScheme.fromSeed(seedColor: Colors.blue),
        );

        // Assert
        expect(typography, isNotNull);
        expect(typography.displayLarge, isA<TextStyle>());
      });

      test('should export AppIconSize', () {
        // Arrange & Act & Assert
        expect(AppIconSize.xs, isNotNull);
        expect(AppIconSize.xs, isA<double>());
      });

      test('should export AppDuration', () {
        // Arrange & Act & Assert
        expect(AppDuration.instant, isNotNull);
        expect(AppDuration.instant, isA<Duration>());
      });

      test('should export InteractionStates', () {
        // Arrange
        const baseColor = Color(0xFF2196F3);
        const brightness = Brightness.light;

        // Act
        final hoverColor = InteractionStates.hover(baseColor, brightness);

        // Assert
        expect(hoverColor, isNotNull);
        expect(hoverColor, isA<Color>());
      });
    });

    group('color exports', () {
      test('should export LanguageColors', () {
        // Arrange & Act
        final dartColor = LanguageColors.dart;
        final pythonColor = LanguageColors.python;

        // Assert
        expect(dartColor, isNotNull);
        expect(dartColor, isA<Color>());
        expect(pythonColor, isNotNull);
        expect(pythonColor, isA<Color>());
      });
    });

    group('utility exports', () {
      test('should export Accessibility utilities', () {
        // Arrange
        const color1 = Color(0xFFFFFFFF);
        const color2 = Color(0xFF000000);

        // Act
        final ratio = Accessibility.contrastRatio(color1, color2);

        // Assert
        expect(ratio, isNotNull);
        expect(ratio, isA<double>());
        expect(ratio, greaterThan(1.0));
      });

      test('should export ThemeModeHelpers extension', () {
        // This is tested via widget tests in theme_extensions_test.dart
        // Here we verify it's accessible
        expect(ThemeModeHelpers, isNotNull);
      });

      test('should export ColorHelpers extension', () {
        // Arrange
        const color = Color(0xFF808080);

        // Act
        final darkened = color.darken();
        final lightened = color.lighten();

        // Assert
        expect(darkened, isNotNull);
        expect(darkened, isA<Color>());
        expect(lightened, isNotNull);
        expect(lightened, isA<Color>());
      });
    });

    group('integration', () {
      test('should create complete light theme using exported tokens', () {
        // Arrange & Act
        final theme = AppThemeData.light();

        // Assert
        expect(theme, isNotNull);
        expect(theme.brightness, equals(Brightness.light));
        expect(theme.colorScheme, isNotNull);
        expect(theme.textTheme, isNotNull);
      });

      test('should create complete dark theme using exported tokens', () {
        // Arrange & Act
        final theme = AppThemeData.dark();

        // Assert
        expect(theme, isNotNull);
        expect(theme.brightness, equals(Brightness.dark));
        expect(theme.colorScheme, isNotNull);
        expect(theme.textTheme, isNotNull);
      });

      test('should support custom seed color', () {
        // Arrange
        const customSeed = Color(0xFFFF5722);

        // Act
        final lightTheme = AppThemeData.light(seedColor: customSeed);
        final darkTheme = AppThemeData.dark(seedColor: customSeed);

        // Assert
        expect(lightTheme, isNotNull);
        expect(darkTheme, isNotNull);
        expect(lightTheme.colorScheme, isNotNull);
        expect(darkTheme.colorScheme, isNotNull);
      });

      testWidgets('should work with MaterialApp', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemeData.light(),
            darkTheme: AppThemeData.dark(),
            themeMode: ThemeMode.light,
            home: const Scaffold(
              body: Text('Test'),
            ),
          ),
        );

        // Assert
        expect(find.text('Test'), findsOneWidget);
        final theme = Theme.of(tester.element(find.text('Test')));
        expect(theme, isNotNull);
        expect(theme.brightness, equals(Brightness.light));
      });

      testWidgets('should access EditorThemeExtension from context',
          (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemeData.light(),
            home: Builder(
              builder: (context) {
                final editorTheme = context.editorTheme;
                expect(editorTheme, isNotNull);
                expect(editorTheme.backgroundColor, isA<Color>());
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      });

      test('should combine spacing and radius systems', () {
        // Arrange & Act
        final padding = EdgeInsets.all(AppSpacing.m);
        final borderRadius = BorderRadius.all(AppRadius.m);

        // Assert
        expect(padding, isNotNull);
        expect(borderRadius, isNotNull);
        expect(borderRadius.topLeft, equals(AppRadius.m));
      });

      test('should combine typography and color systems', () {
        // Arrange
        final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
        final typography = AppTypography.fromColorScheme(colorScheme);

        // Act
        final textStyle = typography.bodyMedium.copyWith(
          color: colorScheme.onSurface,
        );

        // Assert
        expect(textStyle, isNotNull);
        expect(textStyle.color, equals(colorScheme.onSurface));
        expect(textStyle.fontSize, isNotNull);
      });

      test('should use interaction states with theme colors', () {
        // Arrange
        final theme = AppThemeData.light();
        final primaryColor = theme.colorScheme.primary;

        // Act
        final hoverColor = InteractionStates.hover(
          primaryColor,
          theme.brightness,
        );
        final pressedColor = InteractionStates.pressed(
          primaryColor,
          theme.brightness,
        );

        // Assert
        expect(hoverColor, isNot(equals(primaryColor)));
        expect(pressedColor, isNot(equals(primaryColor)));
        expect(hoverColor, isNot(equals(pressedColor)));
      });

      test('should support language-specific syntax highlighting', () {
        // Arrange & Act
        final languages = {
          'Dart': LanguageColors.dart,
          'Python': LanguageColors.python,
          'JavaScript': LanguageColors.javascript,
          'TypeScript': LanguageColors.typescript,
          'Rust': LanguageColors.rust,
          'Go': LanguageColors.go,
        };

        // Assert
        for (final entry in languages.entries) {
          expect(
            entry.value,
            isA<Color>(),
            reason: '${entry.key} color should be a Color',
          );
        }

        // All language colors should be unique
        expect(languages.values.toSet().length, equals(languages.length));
      });

      test('should provide accessibility helpers', () {
        // Arrange
        const backgroundColor = Color(0xFFFFFFFF);
        const textColor = Color(0xFF000000);

        // Act
        final contrast = Accessibility.contrastRatio(
          backgroundColor,
          textColor,
        );
        final passesAA = Accessibility.meetsAA(backgroundColor, textColor);
        final passesAAA = Accessibility.meetsAAA(backgroundColor, textColor);

        // Assert
        expect(contrast, greaterThan(1.0));
        expect(passesAA, isA<bool>());
        expect(passesAAA, isA<bool>());
      });
    });

    group('common usage scenarios', () {
      test('should provide consistent spacing scale', () {
        // Arrange & Act
        final spacings = [
          AppSpacing.xs,
          AppSpacing.s,
          AppSpacing.m,
          AppSpacing.l,
          AppSpacing.xl,
          AppSpacing.xxl,
        ];

        // Assert
        for (var i = 0; i < spacings.length - 1; i++) {
          expect(
            spacings[i],
            lessThan(spacings[i + 1]),
            reason: 'Spacing should be in ascending order',
          );
        }
      });

      test('should provide consistent radius scale', () {
        // Arrange & Act
        final radii = [
          AppRadius.xs,
          AppRadius.s,
          AppRadius.m,
          AppRadius.l,
          AppRadius.xl,
        ];

        // Assert
        for (var i = 0; i < radii.length - 1; i++) {
          expect(
            radii[i].x,
            lessThanOrEqualTo(radii[i + 1].x),
            reason: 'Radius should be in ascending order',
          );
        }
      });

      test('should provide consistent elevation scale', () {
        // Arrange & Act
        final elevations = [
          AppElevation.level0,
          AppElevation.level1,
          AppElevation.level2,
          AppElevation.level3,
          AppElevation.level4,
          AppElevation.level5,
        ];

        // Assert
        for (var i = 0; i < elevations.length - 1; i++) {
          expect(
            elevations[i],
            lessThan(elevations[i + 1]),
            reason: 'Elevation should be in ascending order',
          );
        }
      });

      test('should provide consistent icon size scale', () {
        // Arrange & Act
        final iconSizes = [
          AppIconSize.xs,
          AppIconSize.s,
          AppIconSize.m,
          AppIconSize.l,
          AppIconSize.xl,
        ];

        // Assert
        for (var i = 0; i < iconSizes.length - 1; i++) {
          expect(
            iconSizes[i],
            lessThan(iconSizes[i + 1]),
            reason: 'Icon size should be in ascending order',
          );
        }
      });

      test('should provide consistent duration scale', () {
        // Arrange & Act
        final durations = [
          AppDuration.instant,
          AppDuration.fast,
          AppDuration.normal,
          AppDuration.slow,
        ];

        // Assert
        for (var i = 0; i < durations.length - 1; i++) {
          expect(
            durations[i],
            lessThan(durations[i + 1]),
            reason: 'Duration should be in ascending order',
          );
        }
      });
    });

    group('edge cases', () {
      test('should handle null safety correctly', () {
        // Arrange & Act
        final lightTheme = AppThemeData.light();
        final darkTheme = AppThemeData.dark();

        // Assert
        expect(lightTheme, isNotNull);
        expect(darkTheme, isNotNull);
        expect(lightTheme.colorScheme, isNotNull);
        expect(darkTheme.colorScheme, isNotNull);
      });

      test('should handle theme switching', () {
        // Arrange
        final lightTheme = AppThemeData.light();
        final darkTheme = AppThemeData.dark();

        // Act & Assert
        expect(lightTheme.brightness, equals(Brightness.light));
        expect(darkTheme.brightness, equals(Brightness.dark));
        expect(lightTheme.brightness, isNot(equals(darkTheme.brightness)));
      });

      testWidgets('should maintain theme consistency when rebuilt',
          (tester) async {
        // Arrange
        var themeMode = ThemeMode.light;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                theme: AppThemeData.light(),
                darkTheme: AppThemeData.dark(),
                themeMode: themeMode,
                home: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          themeMode = ThemeMode.dark;
                        });
                      },
                      child: const Text('Toggle'),
                    );
                  },
                ),
              );
            },
          ),
        );

        // Act - Switch to dark mode
        await tester.tap(find.text('Toggle'));
        await tester.pumpAndSettle();

        // Assert
        final context = tester.element(find.text('Toggle'));
        final theme = Theme.of(context);
        expect(theme.brightness, equals(Brightness.dark));
      });

      test('should provide all required primitive sizes', () {
        // Arrange & Act
        final sizes = [
          SizePrimitives.size0,
          SizePrimitives.size4,
          SizePrimitives.size8,
          SizePrimitives.size16,
          SizePrimitives.size24,
          SizePrimitives.size32,
          SizePrimitives.size48,
          SizePrimitives.size64,
        ];

        // Assert
        for (final size in sizes) {
          expect(size, isA<double>());
          expect(size, greaterThanOrEqualTo(0.0));
        }
      });

      test('should provide all required font sizes', () {
        // Arrange & Act
        final fontSizes = [
          FontPrimitives.fontSize10,
          FontPrimitives.fontSize12,
          FontPrimitives.fontSize14,
          FontPrimitives.fontSize16,
          FontPrimitives.fontSize20,
          FontPrimitives.fontSize24,
        ];

        // Assert
        for (final fontSize in fontSizes) {
          expect(fontSize, isA<double>());
          expect(fontSize, greaterThan(0.0));
        }
      });
    });
  });
}
