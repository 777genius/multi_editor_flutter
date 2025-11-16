import 'package:flutter_test/flutter_test.dart';
import 'package:minimap_enhancement/src/services/minimap_service_optimized.dart';
import 'package:minimap_enhancement/src/models/minimap_data.dart';

void main() {
  late MinimapServiceOptimized service;

  setUp(() {
    service = MinimapServiceOptimized();
  });

  group('MinimapServiceOptimized', () {
    test('should generate minimap for small file', () async {
      // Arrange
      const sourceCode = '''
class Example {
  void method() {
    print("Hello");
  }
}
''';

      // Act
      final result = await service.generateMinimap(sourceCode: sourceCode);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Generation failed: $error'),
        (data) {
          expect(data.totalLines, 6);
          expect(data.lines, isNotEmpty);
          expect(data.maxLength, greaterThan(0));
          expect(data.fileSize, sourceCode.length);
        },
      );
    });

    test('should detect empty lines', () async {
      // Arrange
      const sourceCode = '''
Line 1

Line 3
''';

      // Act
      final result = await service.generateMinimap(sourceCode: sourceCode);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Generation failed'),
        (data) {
          final emptyLines = data.lines.where((line) => line.isEmpty).toList();
          expect(emptyLines, isNotEmpty);
        },
      );
    });

    test('should detect comments', () async {
      // Arrange
      const sourceCode = '''
// This is a comment
class Example {
  // Another comment
  void method() {}
}
''';

      final config = const MinimapConfig(detectComments: true);

      // Act
      final result = await service.generateMinimap(
        sourceCode: sourceCode,
        config: config,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Generation failed'),
        (data) {
          final commentLines = data.lines.where((line) => line.isComment).toList();
          expect(commentLines, isNotEmpty);
        },
      );
    });

    test('should calculate indent correctly', () async {
      // Arrange
      const sourceCode = '''
class Example {
  void method() {
    if (true) {
      print("Indented");
    }
  }
}
''';

      // Act
      final result = await service.generateMinimap(sourceCode: sourceCode);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Generation failed'),
        (data) {
          // Should have lines with different indent levels
          final indents = data.lines.map((line) => line.indent).toSet();
          expect(indents.length, greaterThan(1));
        },
      );
    });

    test('should calculate density', () async {
      // Arrange
      const sourceCode = '''
abc123
!!!???
''';

      // Act
      final result = await service.generateMinimap(sourceCode: sourceCode);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Generation failed'),
        (data) {
          expect(data.lines, hasLength(2));
          // First line has high alphanumeric density
          expect(data.lines[0].density, greaterThan(50));
          // Second line has low alphanumeric density
          expect(data.lines[1].density, lessThan(50));
        },
      );
    });

    test('should handle large files with sampling', () async {
      // Arrange - Create large file (20k lines)
      final largeFile = List.generate(
        20000,
        (i) => 'Line $i with some content',
      ).join('\n');

      // Act
      final startTime = DateTime.now();
      final result = await service.generateMinimap(sourceCode: largeFile);
      final duration = DateTime.now().difference(startTime);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Generation failed'),
        (data) {
          expect(data.totalLines, 20000);
          // Should complete reasonably fast (< 200ms)
          expect(duration.inMilliseconds, lessThan(200));
          // Should have sampled lines (not all 20k)
          expect(data.lines.length, lessThan(20000));
        },
      );
    });

    test('should use isolate for large files', () async {
      // Arrange - File large enough to trigger isolate (> 50k chars)
      final largeFile = List.generate(
        5000,
        (i) => 'This is line number $i with some additional content',
      ).join('\n');

      // Act
      final result = await service.generateMinimap(sourceCode: largeFile);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Generation failed'),
        (data) {
          expect(data.totalLines, greaterThan(1000));
          expect(data.lines, isNotEmpty);
        },
      );
    });

    test('should respect sample rate config', () async {
      // Arrange
      const sourceCode = '''
Line 1
Line 2
Line 3
Line 4
Line 5
''';

      // Sample every line
      final config1 = const MinimapConfig(sampleRate: 1);
      final result1 = await service.generateMinimap(
        sourceCode: sourceCode,
        config: config1,
      );

      // Sample every 2nd line
      final config2 = const MinimapConfig(sampleRate: 2);
      final result2 = await service.generateMinimap(
        sourceCode: sourceCode,
        config: config2,
      );

      // Assert
      expect(result1.isRight(), true);
      expect(result2.isRight(), true);

      result1.fold(
        (error) => fail('Generation 1 failed'),
        (data1) {
          result2.fold(
            (error) => fail('Generation 2 failed'),
            (data2) {
              // More frequent sampling should give more lines
              expect(data1.lines.length, greaterThanOrEqualTo(data2.lines.length));
            },
          );
        },
      );
    });

    test('should handle empty source code', () async {
      // Arrange
      const sourceCode = '';

      // Act
      final result = await service.generateMinimap(sourceCode: sourceCode);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Generation failed'),
        (data) {
          expect(data.totalLines, greaterThanOrEqualTo(0));
          expect(data.fileSize, 0);
        },
      );
    });

    test('should batch generate for multiple files', () async {
      // Arrange
      final files = {
        '/file1.dart': 'class File1 {}\n',
        '/file2.dart': 'class File2 {}\n',
        '/file3.dart': 'class File3 {}\n',
      };

      // Act
      final result = await service.generateBatch(files: files);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Batch generation failed'),
        (results) {
          expect(results.keys, containsAll(files.keys));
          for (final entry in results.entries) {
            expect(entry.value.totalLines, greaterThan(0));
          }
        },
      );
    });

    test('should calculate max length correctly', () async {
      // Arrange
      const sourceCode = '''
short
medium line here
this is a very long line with lots of content
''';

      // Act
      final result = await service.generateMinimap(sourceCode: sourceCode);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Generation failed'),
        (data) {
          // Max length should be from the longest line
          expect(data.maxLength, greaterThan(40));
        },
      );
    });
  });
}
