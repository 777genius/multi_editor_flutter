import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide_presentation/ide_presentation.dart';
import 'package:path/path.dart' as path;

void main() {
  group('FileService', () {
    late FileService service;
    late Directory tempDir;

    setUp(() {
      service = FileService();
    });

    setUpAll(() async {
      // Create temporary directory for tests
      tempDir = await Directory.systemTemp.createTemp('file_service_test_');
    });

    tearDownAll(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('readFile', () {
      test('should read existing file successfully', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.dart'));
        const content = 'void main() { print("hello"); }';
        await testFile.writeAsString(content);

        // Act
        final result = await service.readFile(testFile.path);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (document) {
            expect(document.content, equals(content));
            expect(document.uri.path, contains('test.dart'));
            expect(document.languageId, equals(LanguageId.dart));
          },
        );
      });

      test('should detect language from file extension', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'script.js'));
        await testFile.writeAsString('console.log("test");');

        // Act
        final result = await service.readFile(testFile.path);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (document) {
            expect(document.languageId, equals(LanguageId.javascript));
          },
        );
      });

      test('should fail when file does not exist', () async {
        // Arrange
        final nonExistentPath = path.join(tempDir.path, 'nonexistent.dart');

        // Act
        final result = await service.readFile(nonExistentPath);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_DocumentNotFound>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should handle different file extensions', () async {
        // Arrange
        final files = {
          'file.ts': LanguageId.typescript,
          'file.py': LanguageId.python,
          'file.java': LanguageId.java,
          'file.json': LanguageId.json,
        };

        for (final entry in files.entries) {
          final testFile = File(path.join(tempDir.path, entry.key));
          await testFile.writeAsString('test content');

          // Act
          final result = await service.readFile(testFile.path);

          // Assert
          expect(result.isRight(), isTrue);
          result.fold(
            (_) => fail('Should not fail for ${entry.key}'),
            (document) {
              expect(document.languageId, equals(entry.value),
                  reason: 'Wrong language for ${entry.key}');
            },
          );
        }
      });

      test('should handle empty file', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'empty.dart'));
        await testFile.writeAsString('');

        // Act
        final result = await service.readFile(testFile.path);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (document) {
            expect(document.content, isEmpty);
          },
        );
      });

      test('should handle large file', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'large.dart'));
        final largeContent = 'test\n' * 10000;
        await testFile.writeAsString(largeContent);

        // Act
        final result = await service.readFile(testFile.path);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (document) {
            expect(document.content.length, equals(largeContent.length));
          },
        );
      });
    });

    group('writeFile', () {
      test('should write file successfully', () async {
        // Arrange
        final filePath = path.join(tempDir.path, 'write_test.dart');
        const content = 'void main() {}';

        // Act
        final result = await service.writeFile(
          filePath: filePath,
          content: content,
        );

        // Assert
        expect(result.isRight(), isTrue);

        // Verify file was written
        final file = File(filePath);
        expect(await file.exists(), isTrue);
        expect(await file.readAsString(), equals(content));
      });

      test('should create parent directories if needed', () async {
        // Arrange
        final filePath = path.join(
          tempDir.path,
          'nested',
          'directories',
          'file.dart',
        );
        const content = 'test content';

        // Act
        final result = await service.writeFile(
          filePath: filePath,
          content: content,
        );

        // Assert
        expect(result.isRight(), isTrue);

        // Verify file was created
        final file = File(filePath);
        expect(await file.exists(), isTrue);
        expect(await file.readAsString(), equals(content));
      });

      test('should overwrite existing file', () async {
        // Arrange
        final filePath = path.join(tempDir.path, 'overwrite.dart');
        await File(filePath).writeAsString('old content');

        const newContent = 'new content';

        // Act
        final result = await service.writeFile(
          filePath: filePath,
          content: newContent,
        );

        // Assert
        expect(result.isRight(), isTrue);
        expect(await File(filePath).readAsString(), equals(newContent));
      });

      test('should handle empty content', () async {
        // Arrange
        final filePath = path.join(tempDir.path, 'empty_write.dart');

        // Act
        final result = await service.writeFile(
          filePath: filePath,
          content: '',
        );

        // Assert
        expect(result.isRight(), isTrue);
        expect(await File(filePath).readAsString(), isEmpty);
      });

      test('should handle large content', () async {
        // Arrange
        final filePath = path.join(tempDir.path, 'large_write.dart');
        final largeContent = 'line\n' * 50000;

        // Act
        final result = await service.writeFile(
          filePath: filePath,
          content: largeContent,
        );

        // Assert
        expect(result.isRight(), isTrue);
        expect(await File(filePath).readAsString(), equals(largeContent));
      });
    });

    group('roundtrip', () {
      test('should read and write file correctly', () async {
        // Arrange
        final filePath = path.join(tempDir.path, 'roundtrip.dart');
        const originalContent = 'class Test {\n  void method() {}\n}';

        // Write
        await service.writeFile(
          filePath: filePath,
          content: originalContent,
        );

        // Read
        final readResult = await service.readFile(filePath);

        // Assert
        expect(readResult.isRight(), isTrue);
        readResult.fold(
          (_) => fail('Should not fail'),
          (document) {
            expect(document.content, equals(originalContent));
          },
        );
      });
    });
  });
}
