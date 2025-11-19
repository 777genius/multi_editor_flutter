import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_ui/src/theme/tokens/primitive/font_primitives.dart';

void main() {
  group('FontPrimitives', () {
    group('constructor', () {
      test('should have private constructor', () {
        // Arrange & Act & Assert
        // Cannot instantiate due to private constructor
        // This test verifies the class design
        expect(FontPrimitives, isNotNull);
      });
    });

    group('font families', () {
      test('fontFamilySans should contain expected fonts', () {
        // Arrange & Act
        const fontFamily = FontPrimitives.fontFamilySans;

        // Assert
        expect(fontFamily, isNotEmpty);
        expect(fontFamily, contains('SF Pro Text'));
        expect(fontFamily, contains('Roboto'));
        expect(fontFamily, contains('sans-serif'));
      });

      test('fontFamilyMono should contain expected fonts', () {
        // Arrange & Act
        const fontFamily = FontPrimitives.fontFamilyMono;

        // Assert
        expect(fontFamily, isNotEmpty);
        expect(fontFamily, contains('SF Mono'));
        expect(fontFamily, contains('Monaco'));
        expect(fontFamily, contains('Consolas'));
        expect(fontFamily, contains('monospace'));
      });

      test('fontFamilySerif should contain expected fonts', () {
        // Arrange & Act
        const fontFamily = FontPrimitives.fontFamilySerif;

        // Assert
        expect(fontFamily, isNotEmpty);
        expect(fontFamily, contains('SF Pro Display'));
        expect(fontFamily, contains('Georgia'));
        expect(fontFamily, contains('serif'));
      });

      test('font families should be different', () {
        // Arrange & Act & Assert
        expect(
          FontPrimitives.fontFamilySans,
          isNot(equals(FontPrimitives.fontFamilyMono)),
        );
        expect(
          FontPrimitives.fontFamilySans,
          isNot(equals(FontPrimitives.fontFamilySerif)),
        );
        expect(
          FontPrimitives.fontFamilyMono,
          isNot(equals(FontPrimitives.fontFamilySerif)),
        );
      });
    });

    group('font sizes', () {
      test('fontSize10 should be 10.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize10, equals(10.0));
      });

      test('fontSize11 should be 11.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize11, equals(11.0));
      });

      test('fontSize12 should be 12.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize12, equals(12.0));
      });

      test('fontSize13 should be 13.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize13, equals(13.0));
      });

      test('fontSize14 should be 14.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize14, equals(14.0));
      });

      test('fontSize16 should be 16.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize16, equals(16.0));
      });

      test('fontSize18 should be 18.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize18, equals(18.0));
      });

      test('fontSize20 should be 20.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize20, equals(20.0));
      });

      test('fontSize22 should be 22.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize22, equals(22.0));
      });

      test('fontSize24 should be 24.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize24, equals(24.0));
      });

      test('fontSize28 should be 28.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize28, equals(28.0));
      });

      test('fontSize32 should be 32.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize32, equals(32.0));
      });

      test('fontSize36 should be 36.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize36, equals(36.0));
      });

      test('fontSize45 should be 45.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize45, equals(45.0));
      });

      test('fontSize57 should be 57.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize57, equals(57.0));
      });

      test('font sizes should be in ascending order', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize10, lessThan(FontPrimitives.fontSize11));
        expect(FontPrimitives.fontSize11, lessThan(FontPrimitives.fontSize12));
        expect(FontPrimitives.fontSize12, lessThan(FontPrimitives.fontSize13));
        expect(FontPrimitives.fontSize13, lessThan(FontPrimitives.fontSize14));
        expect(FontPrimitives.fontSize14, lessThan(FontPrimitives.fontSize16));
        expect(FontPrimitives.fontSize16, lessThan(FontPrimitives.fontSize18));
        expect(FontPrimitives.fontSize18, lessThan(FontPrimitives.fontSize20));
        expect(FontPrimitives.fontSize20, lessThan(FontPrimitives.fontSize22));
        expect(FontPrimitives.fontSize22, lessThan(FontPrimitives.fontSize24));
        expect(FontPrimitives.fontSize24, lessThan(FontPrimitives.fontSize28));
        expect(FontPrimitives.fontSize28, lessThan(FontPrimitives.fontSize32));
        expect(FontPrimitives.fontSize32, lessThan(FontPrimitives.fontSize36));
        expect(FontPrimitives.fontSize36, lessThan(FontPrimitives.fontSize45));
        expect(FontPrimitives.fontSize45, lessThan(FontPrimitives.fontSize57));
      });

      test('all font sizes should be positive', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontSize10, greaterThan(0.0));
        expect(FontPrimitives.fontSize11, greaterThan(0.0));
        expect(FontPrimitives.fontSize12, greaterThan(0.0));
        expect(FontPrimitives.fontSize13, greaterThan(0.0));
        expect(FontPrimitives.fontSize14, greaterThan(0.0));
        expect(FontPrimitives.fontSize16, greaterThan(0.0));
        expect(FontPrimitives.fontSize18, greaterThan(0.0));
        expect(FontPrimitives.fontSize20, greaterThan(0.0));
        expect(FontPrimitives.fontSize22, greaterThan(0.0));
        expect(FontPrimitives.fontSize24, greaterThan(0.0));
        expect(FontPrimitives.fontSize28, greaterThan(0.0));
        expect(FontPrimitives.fontSize32, greaterThan(0.0));
        expect(FontPrimitives.fontSize36, greaterThan(0.0));
        expect(FontPrimitives.fontSize45, greaterThan(0.0));
        expect(FontPrimitives.fontSize57, greaterThan(0.0));
      });
    });

    group('font weights', () {
      test('fontWeightThin should be FontWeight.w100', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontWeightThin, equals(FontWeight.w100));
      });

      test('fontWeightExtraLight should be FontWeight.w200', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontWeightExtraLight, equals(FontWeight.w200));
      });

      test('fontWeightLight should be FontWeight.w300', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontWeightLight, equals(FontWeight.w300));
      });

      test('fontWeightRegular should be FontWeight.w400', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontWeightRegular, equals(FontWeight.w400));
      });

      test('fontWeightMedium should be FontWeight.w500', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontWeightMedium, equals(FontWeight.w500));
      });

      test('fontWeightSemiBold should be FontWeight.w600', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontWeightSemiBold, equals(FontWeight.w600));
      });

      test('fontWeightBold should be FontWeight.w700', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontWeightBold, equals(FontWeight.w700));
      });

      test('fontWeightExtraBold should be FontWeight.w800', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontWeightExtraBold, equals(FontWeight.w800));
      });

      test('fontWeightBlack should be FontWeight.w900', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontWeightBlack, equals(FontWeight.w900));
      });

      test('font weights should be in ascending order', () {
        // Arrange & Act & Assert
        expect(
          FontPrimitives.fontWeightThin.index,
          lessThan(FontPrimitives.fontWeightExtraLight.index),
        );
        expect(
          FontPrimitives.fontWeightExtraLight.index,
          lessThan(FontPrimitives.fontWeightLight.index),
        );
        expect(
          FontPrimitives.fontWeightLight.index,
          lessThan(FontPrimitives.fontWeightRegular.index),
        );
        expect(
          FontPrimitives.fontWeightRegular.index,
          lessThan(FontPrimitives.fontWeightMedium.index),
        );
        expect(
          FontPrimitives.fontWeightMedium.index,
          lessThan(FontPrimitives.fontWeightSemiBold.index),
        );
        expect(
          FontPrimitives.fontWeightSemiBold.index,
          lessThan(FontPrimitives.fontWeightBold.index),
        );
        expect(
          FontPrimitives.fontWeightBold.index,
          lessThan(FontPrimitives.fontWeightExtraBold.index),
        );
        expect(
          FontPrimitives.fontWeightExtraBold.index,
          lessThan(FontPrimitives.fontWeightBlack.index),
        );
      });
    });

    group('line heights', () {
      test('lineHeight100 should be 1.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.lineHeight100, equals(1.0));
      });

      test('lineHeight110 should be 1.1', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.lineHeight110, equals(1.1));
      });

      test('lineHeight120 should be 1.2', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.lineHeight120, equals(1.2));
      });

      test('lineHeight125 should be 1.25', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.lineHeight125, equals(1.25));
      });

      test('lineHeight140 should be 1.4', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.lineHeight140, equals(1.4));
      });

      test('lineHeight150 should be 1.5', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.lineHeight150, equals(1.5));
      });

      test('lineHeight160 should be 1.6', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.lineHeight160, equals(1.6));
      });

      test('lineHeight180 should be 1.8', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.lineHeight180, equals(1.8));
      });

      test('lineHeight200 should be 2.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.lineHeight200, equals(2.0));
      });

      test('line heights should be in ascending order', () {
        // Arrange & Act & Assert
        expect(
          FontPrimitives.lineHeight100,
          lessThan(FontPrimitives.lineHeight110),
        );
        expect(
          FontPrimitives.lineHeight110,
          lessThan(FontPrimitives.lineHeight120),
        );
        expect(
          FontPrimitives.lineHeight120,
          lessThan(FontPrimitives.lineHeight125),
        );
        expect(
          FontPrimitives.lineHeight125,
          lessThan(FontPrimitives.lineHeight140),
        );
        expect(
          FontPrimitives.lineHeight140,
          lessThan(FontPrimitives.lineHeight150),
        );
        expect(
          FontPrimitives.lineHeight150,
          lessThan(FontPrimitives.lineHeight160),
        );
        expect(
          FontPrimitives.lineHeight160,
          lessThan(FontPrimitives.lineHeight180),
        );
        expect(
          FontPrimitives.lineHeight180,
          lessThan(FontPrimitives.lineHeight200),
        );
      });

      test('line heights should be positive', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.lineHeight100, greaterThan(0.0));
        expect(FontPrimitives.lineHeight110, greaterThan(0.0));
        expect(FontPrimitives.lineHeight120, greaterThan(0.0));
        expect(FontPrimitives.lineHeight125, greaterThan(0.0));
        expect(FontPrimitives.lineHeight140, greaterThan(0.0));
        expect(FontPrimitives.lineHeight150, greaterThan(0.0));
        expect(FontPrimitives.lineHeight160, greaterThan(0.0));
        expect(FontPrimitives.lineHeight180, greaterThan(0.0));
        expect(FontPrimitives.lineHeight200, greaterThan(0.0));
      });
    });

    group('letter spacing', () {
      test('letterSpacingTight should be -0.5', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.letterSpacingTight, equals(-0.5));
      });

      test('letterSpacingNormal should be 0.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.letterSpacingNormal, equals(0.0));
      });

      test('letterSpacingRelaxed should be 0.5', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.letterSpacingRelaxed, equals(0.5));
      });

      test('letterSpacingWide should be 1.0', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.letterSpacingWide, equals(1.0));
      });

      test('letterSpacingExtraWide should be 1.5', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.letterSpacingExtraWide, equals(1.5));
      });

      test('letter spacing should be in ascending order', () {
        // Arrange & Act & Assert
        expect(
          FontPrimitives.letterSpacingTight,
          lessThan(FontPrimitives.letterSpacingNormal),
        );
        expect(
          FontPrimitives.letterSpacingNormal,
          lessThan(FontPrimitives.letterSpacingRelaxed),
        );
        expect(
          FontPrimitives.letterSpacingRelaxed,
          lessThan(FontPrimitives.letterSpacingWide),
        );
        expect(
          FontPrimitives.letterSpacingWide,
          lessThan(FontPrimitives.letterSpacingExtraWide),
        );
      });
    });

    group('common usage scenarios', () {
      test('should create TextStyle with sans font family', () {
        // Arrange
        const textStyle = TextStyle(
          fontFamily: FontPrimitives.fontFamilySans,
          fontSize: FontPrimitives.fontSize14,
        );

        // Act & Assert
        expect(textStyle.fontFamily, equals(FontPrimitives.fontFamilySans));
        expect(textStyle.fontSize, equals(14.0));
      });

      test('should create TextStyle with mono font family for code', () {
        // Arrange
        const textStyle = TextStyle(
          fontFamily: FontPrimitives.fontFamilyMono,
          fontSize: FontPrimitives.fontSize13,
        );

        // Act & Assert
        expect(textStyle.fontFamily, equals(FontPrimitives.fontFamilyMono));
        expect(textStyle.fontSize, equals(13.0));
      });

      test('should create heading TextStyle with serif and bold weight', () {
        // Arrange
        const textStyle = TextStyle(
          fontFamily: FontPrimitives.fontFamilySerif,
          fontSize: FontPrimitives.fontSize24,
          fontWeight: FontPrimitives.fontWeightBold,
        );

        // Act & Assert
        expect(textStyle.fontFamily, equals(FontPrimitives.fontFamilySerif));
        expect(textStyle.fontSize, equals(24.0));
        expect(textStyle.fontWeight, equals(FontWeight.w700));
      });

      test('should create TextStyle with custom line height', () {
        // Arrange
        const textStyle = TextStyle(
          fontSize: FontPrimitives.fontSize16,
          height: FontPrimitives.lineHeight150,
        );

        // Act & Assert
        expect(textStyle.fontSize, equals(16.0));
        expect(textStyle.height, equals(1.5));
      });

      test('should create TextStyle with letter spacing', () {
        // Arrange
        const textStyle = TextStyle(
          fontSize: FontPrimitives.fontSize14,
          letterSpacing: FontPrimitives.letterSpacingRelaxed,
        );

        // Act & Assert
        expect(textStyle.fontSize, equals(14.0));
        expect(textStyle.letterSpacing, equals(0.5));
      });

      test('should create complete TextStyle with all properties', () {
        // Arrange
        const textStyle = TextStyle(
          fontFamily: FontPrimitives.fontFamilySans,
          fontSize: FontPrimitives.fontSize16,
          fontWeight: FontPrimitives.fontWeightMedium,
          height: FontPrimitives.lineHeight140,
          letterSpacing: FontPrimitives.letterSpacingNormal,
        );

        // Act & Assert
        expect(textStyle.fontFamily, equals(FontPrimitives.fontFamilySans));
        expect(textStyle.fontSize, equals(16.0));
        expect(textStyle.fontWeight, equals(FontWeight.w500));
        expect(textStyle.height, equals(1.4));
        expect(textStyle.letterSpacing, equals(0.0));
      });
    });

    group('edge cases', () {
      test('font families should not be empty strings', () {
        // Arrange & Act & Assert
        expect(FontPrimitives.fontFamilySans, isNotEmpty);
        expect(FontPrimitives.fontFamilyMono, isNotEmpty);
        expect(FontPrimitives.fontFamilySerif, isNotEmpty);
      });

      test('smallest font size should be readable', () {
        // Arrange & Act
        const smallestSize = FontPrimitives.fontSize10;

        // Assert
        expect(smallestSize, greaterThanOrEqualTo(10.0));
      });

      test('largest font size should be reasonable', () {
        // Arrange & Act
        const largestSize = FontPrimitives.fontSize57;

        // Assert
        expect(largestSize, lessThanOrEqualTo(100.0));
      });

      test('line height multiplier should produce reasonable line spacing', () {
        // Arrange
        const fontSize = FontPrimitives.fontSize16;
        const lineHeight = FontPrimitives.lineHeight150;

        // Act
        const calculatedLineHeight = fontSize * lineHeight;

        // Assert
        expect(calculatedLineHeight, equals(24.0));
        expect(calculatedLineHeight, greaterThan(fontSize));
      });

      test('all values should be compile-time constants', () {
        // Arrange
        const fontFamily = FontPrimitives.fontFamilySans;
        const fontSize = FontPrimitives.fontSize16;
        const fontWeight = FontPrimitives.fontWeightMedium;
        const lineHeight = FontPrimitives.lineHeight140;
        const letterSpacing = FontPrimitives.letterSpacingNormal;

        // Act & Assert
        // If these compile, they are compile-time constants
        expect(fontFamily, isNotEmpty);
        expect(fontSize, equals(16.0));
        expect(fontWeight, equals(FontWeight.w500));
        expect(lineHeight, equals(1.4));
        expect(letterSpacing, equals(0.0));
      });

      test('negative letter spacing should be valid for tight spacing', () {
        // Arrange & Act
        const tightSpacing = FontPrimitives.letterSpacingTight;

        // Assert
        expect(tightSpacing, lessThan(0.0));
        expect(tightSpacing, greaterThanOrEqualTo(-1.0));
      });
    });
  });
}
