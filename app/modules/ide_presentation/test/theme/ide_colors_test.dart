import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide_presentation/ide_presentation.dart';

void main() {
  group('IdeColors - Dark Theme', () {
    testWidgets('should provide dark theme colors', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.dark,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<IdeColors>();

              // Assert
              expect(colors, isNotNull);
              expect(colors!.editorBackground, isA<Color>());
              expect(colors.sidebarBackground, isA<Color>());
              expect(colors.lineNumberForeground, isA<Color>());

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should have dark background color', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.dark,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<IdeColors>();

              // Assert
              expect(colors!.editorBackground.computeLuminance(), lessThan(0.5));

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should provide all required color properties', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.dark,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<IdeColors>();

              // Assert - check all properties are not null
              expect(colors!.editorBackground, isNotNull);
              expect(colors.sidebarBackground, isNotNull);
              expect(colors.lineNumberForeground, isNotNull);
              expect(colors.currentLineBorder, isNotNull);

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('IdeColors - Light Theme', () {
    testWidgets('should provide light theme colors', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.light,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<IdeColors>();

              // Assert
              expect(colors, isNotNull);
              expect(colors!.editorBackground, isA<Color>());
              expect(colors.sidebarBackground, isA<Color>());

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should have light background color', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.light,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<IdeColors>();

              // Assert
              expect(colors!.editorBackground.computeLuminance(), greaterThan(0.5));

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should provide all required color properties', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.light,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<IdeColors>();

              // Assert
              expect(colors!.editorBackground, isNotNull);
              expect(colors.sidebarBackground, isNotNull);
              expect(colors.lineNumberForeground, isNotNull);
              expect(colors.currentLineBorder, isNotNull);

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('IdeColors - Theme Contrast', () {
    testWidgets('dark and light themes should have different backgrounds', (tester) async {
      late Color darkBg;
      late Color lightBg;

      // Get dark theme background
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.dark,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<IdeColors>();
              darkBg = colors!.editorBackground;
              return const SizedBox();
            },
          ),
        ),
      );

      // Get light theme background
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.light,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<IdeColors>();
              lightBg = colors!.editorBackground;
              return const SizedBox();
            },
          ),
        ),
      );

      // Assert
      expect(darkBg, isNot(equals(lightBg)));
      expect(darkBg.computeLuminance(), lessThan(lightBg.computeLuminance()));
    });

    testWidgets('dark theme should have darker sidebar', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.dark,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<IdeColors>();

              // Assert - sidebar should be darker than editor in dark theme
              expect(
                colors!.sidebarBackground.computeLuminance(),
                lessThanOrEqualTo(colors.editorBackground.computeLuminance()),
              );

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('SyntaxColors - Dark Theme', () {
    testWidgets('should provide syntax highlighting colors', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.dark,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<SyntaxColors>();

              // Assert
              expect(colors, isNotNull);
              expect(colors!.keyword, isA<Color>());
              expect(colors.string, isA<Color>());
              expect(colors.comment, isA<Color>());
              expect(colors.number, isA<Color>());
              expect(colors.function, isA<Color>());

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should have distinct colors for different token types', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.dark,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<SyntaxColors>();

              // Assert - different token types should have different colors
              expect(colors!.keyword, isNot(equals(colors.string)));
              expect(colors.keyword, isNot(equals(colors.comment)));
              expect(colors.string, isNot(equals(colors.number)));

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('SyntaxColors - Light Theme', () {
    testWidgets('should provide syntax highlighting colors', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.light,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<SyntaxColors>();

              // Assert
              expect(colors, isNotNull);
              expect(colors!.keyword, isA<Color>());
              expect(colors.string, isA<Color>());
              expect(colors.comment, isA<Color>());

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should have distinct colors for different token types', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.light,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<SyntaxColors>();

              // Assert
              expect(colors!.keyword, isNot(equals(colors.string)));
              expect(colors.keyword, isNot(equals(colors.comment)));

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('Theme Consistency', () {
    testWidgets('should maintain VS Code color scheme consistency', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.dark,
          home: Builder(
            builder: (context) {
              final ideColors = Theme.of(context).extension<IdeColors>();
              final syntaxColors = Theme.of(context).extension<SyntaxColors>();

              // Assert - both extensions should be available
              expect(ideColors, isNotNull);
              expect(syntaxColors, isNotNull);

              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('should provide readable text colors on backgrounds', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.dark,
          home: Builder(
            builder: (context) {
              final colors = Theme.of(context).extension<IdeColors>();
              final bgLuminance = colors!.editorBackground.computeLuminance();
              final fgLuminance = colors.lineNumberForeground.computeLuminance();

              // Assert - sufficient contrast between background and foreground
              expect((bgLuminance - fgLuminance).abs(), greaterThan(0.1));

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('Theme Extensions', () {
    test('IdeColors should be a ThemeExtension', () {
      // Assert
      expect(IdeColors.dark(), isA<ThemeExtension<IdeColors>>());
      expect(IdeColors.light(), isA<ThemeExtension<IdeColors>>());
    });

    test('SyntaxColors should be a ThemeExtension', () {
      // Assert
      expect(SyntaxColors.dark(), isA<ThemeExtension<SyntaxColors>>());
      expect(SyntaxColors.light(), isA<ThemeExtension<SyntaxColors>>());
    });
  });

  group('Color Accessibility', () {
    testWidgets('should provide sufficient contrast for readability', (tester) async {
      // Test dark theme contrast
      await tester.pumpWidget(
        MaterialApp(
          theme: IdeTheme.dark,
          home: Builder(
            builder: (context) {
              final syntaxColors = Theme.of(context).extension<SyntaxColors>();
              final ideColors = Theme.of(context).extension<IdeColors>();

              // Calculate relative luminance difference
              final bgLuminance = ideColors!.editorBackground.computeLuminance();
              final keywordLuminance = syntaxColors!.keyword.computeLuminance();

              // WCAG AA requires at least 4.5:1 contrast ratio for normal text
              // Luminance difference should be noticeable
              expect((bgLuminance - keywordLuminance).abs(), greaterThan(0.2));

              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
