import 'package:flutter_test/flutter_test.dart';
import 'package:minimap_enhancement/minimap_enhancement.dart';

void main() {
  group('MinimapService', () {
    late MinimapService service;

    setUp(() {
      service = MinimapService();
    });

    test('should generate minimap from simple code', () async {
      // Arrange
      const code = '''
class Test {
  void method() {
    print("hello");
  }
}
''';

      // Act
      final result = await service.generateMinimap(code: code);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (data) {
          expect(data.lines, isNotEmpty);
          expect(data.totalLines, greaterThan(0));
        },
      );
    });

    test('should handle empty code', () async {
      // Arrange
      const code = '';

      // Act
      final result = await service.generateMinimap(code: code);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (data) {
          expect(data.lines, isEmpty);
          expect(data.totalLines, equals(0));
        },
      );
    });

    test('should detect comments', () async {
      // Arrange
      const code = '''
// This is a comment
class Test {
  /* Multi-line
     comment */
  void method() {}
}
''';

      // Act
      final result = await service.generateMinimap(code: code);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (data) {
          final commentLines = data.lines.where((line) => line.isComment);
          expect(commentLines, isNotEmpty);
        },
      );
    });

    test('should detect empty lines', () async {
      // Arrange
      const code = '''
class Test {

  void method() {

  }

}
''';

      // Act
      final result = await service.generateMinimap(code: code);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (data) {
          final emptyLines = data.lines.where((line) => line.isEmpty);
          expect(emptyLines, isNotEmpty);
        },
      );
    });

    test('should detect indentation levels', () async {
      // Arrange
      const code = '''
class Test {
  void method() {
    if (true) {
      print("nested");
    }
  }
}
''';

      // Act
      final result = await service.generateMinimap(code: code);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (data) {
          final indentedLines = data.lines.where((line) => line.indent > 0);
          expect(indentedLines, isNotEmpty);

          // Check for deeply nested line
          final deeplyIndented = data.lines.where((line) => line.indent >= 4);
          expect(deeplyIndented, isNotEmpty);
        },
      );
    });

    test('should calculate line lengths', () async {
      // Arrange
      const code = '''
short
medium length line
very long line with lots of content to make it exceed normal width
''';

      // Act
      final result = await service.generateMinimap(code: code);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (data) {
          expect(data.lines[0].length, lessThan(data.lines[2].length));
          expect(data.maxLength, greaterThan(0));
        },
      );
    });

    test('should calculate character density', () async {
      // Arrange
      const code = '''
a
abc def
abcdefghijklmnopqrstuvwxyz
''';

      // Act
      final result = await service.generateMinimap(code: code);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (data) {
          expect(data.lines, hasLength(3));
          expect(data.lines.every((line) => line.density >= 0 && line.density <= 100), isTrue);
        },
      );
    });

    test('should track total lines count', () async {
      // Arrange
      const code = '''
line 1
line 2
line 3
line 4
line 5
''';

      // Act
      final result = await service.generateMinimap(code: code);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (data) {
          expect(data.totalLines, equals(data.lines.length));
          expect(data.totalLines, greaterThanOrEqualTo(5));
        },
      );
    });

    test('should calculate file size', () async {
      // Arrange
      const code = 'test content for size calculation';

      // Act
      final result = await service.generateMinimap(code: code);

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (data) {
          expect(data.fileSize, greaterThan(0));
          expect(data.fileSize, equals(code.length));
        },
      );
    });
  });
}
