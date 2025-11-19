import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_ide/core/security/secure_file_service.dart';
import 'package:multi_editor_ide/core/security/security_config.dart';

class MockSecurityConfig extends Mock implements SecurityConfig {}

void main() {
  group('SecureFileService', () {
    late SecureFileService service;
    late MockSecurityConfig mockConfig;
    late Directory tempDir;

    setUp(() async {
      mockConfig = MockSecurityConfig();
      service = SecureFileService(mockConfig);

      // Create temp directory for testing
      tempDir = await Directory.systemTemp.createTemp('secure_file_test_');

      // Default mock behavior
      when(() => mockConfig.isPathAllowed(any())).thenReturn(true);
      when(() => mockConfig.debugLog(any())).thenReturn(null);
      when(() => mockConfig.warnLog(any())).thenReturn(null);
      when(() => mockConfig.errorLog(any(), any(), any())).thenReturn(null);
    });

    tearDown(() async {
      // Clean up temp directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('readFile', () {
      test('should successfully read file when path is valid', () async {
        // Arrange
        final testFile = File('${tempDir.path}/test.txt');
        const testContent = 'Hello, World!';
        await testFile.writeAsString(testContent);
        when(() => mockConfig.isPathAllowed(testFile.path)).thenReturn(true);

        // Act
        final result = await service.readFile(testFile.path);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (error) => fail('Expected Right but got Left: $error'),
          (content) => expect(content, testContent),
        );
        verify(() => mockConfig.debugLog(any())).called(1);
      });

      test('should fail when file does not exist', () async {
        // Arrange
        final nonExistentPath = '${tempDir.path}/nonexistent.txt';
        when(() => mockConfig.isPathAllowed(nonExistentPath)).thenReturn(true);

        // Act
        final result = await service.readFile(nonExistentPath);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, contains('File not found')),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should fail when path is not allowed by security config', () async {
        // Arrange
        final testFile = File('${tempDir.path}/test.txt');
        await testFile.writeAsString('test');
        when(() => mockConfig.isPathAllowed(testFile.path)).thenReturn(false);

        // Act
        final result = await service.readFile(testFile.path);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, contains('Access denied')),
          (_) => fail('Expected Left but got Right'),
        );
        verify(() => mockConfig.warnLog(any())).called(1);
      });

      test('should fail when path contains path traversal attempts', () async {
        // Arrange
        final maliciousPath = '${tempDir.path}/../../../etc/passwd';
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act
        final result = await service.readFile(maliciousPath);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, contains('contains ".."')),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should fail when path is a directory not a file', () async {
        // Arrange
        final testDir = Directory('${tempDir.path}/testdir');
        await testDir.create();
        when(() => mockConfig.isPathAllowed(testDir.path)).thenReturn(true);

        // Act
        final result = await service.readFile(testDir.path);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, contains('not a regular file')),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should fail when file is too large (>100MB)', () async {
        // Arrange - Can't easily create 100MB file, so we'll skip this test
        // This would require mocking File.stat() which is complex
      }, skip: 'Requires file system mocking');

      test('should fail when path looks suspicious', () async {
        // Arrange
        final suspiciousPath = '${tempDir.path}/.ssh/id_rsa';
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act
        final result = await service.readFile(suspiciousPath);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, contains('suspicious path')),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should handle FileSystemException gracefully', () async {
        // Arrange
        final invalidPath = '/dev/null/invalid';
        when(() => mockConfig.isPathAllowed(invalidPath)).thenReturn(true);

        // Act
        final result = await service.readFile(invalidPath);

        // Assert
        expect(result.isLeft(), true);
        verify(() => mockConfig.errorLog(any(), any(), any())).called(1);
      });
    });

    group('writeFile', () {
      test('should successfully write file when path is valid', () async {
        // Arrange
        final testFile = '${tempDir.path}/write_test.txt';
        const content = 'Test content';
        when(() => mockConfig.isPathAllowed(testFile)).thenReturn(true);

        // Act
        final result = await service.writeFile(testFile, content);

        // Assert
        expect(result.isRight(), true);
        final file = File(testFile);
        expect(await file.exists(), true);
        expect(await file.readAsString(), content);
        verify(() => mockConfig.debugLog(any())).called(1);
      });

      test('should create parent directories if they do not exist', () async {
        // Arrange
        final testFile = '${tempDir.path}/nested/dir/test.txt';
        const content = 'Test content';
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act
        final result = await service.writeFile(testFile, content);

        // Assert
        expect(result.isRight(), true);
        final file = File(testFile);
        expect(await file.exists(), true);
        expect(await file.readAsString(), content);
      });

      test('should fail when path is not allowed', () async {
        // Arrange
        final testFile = '${tempDir.path}/test.txt';
        when(() => mockConfig.isPathAllowed(testFile)).thenReturn(false);

        // Act
        final result = await service.writeFile(testFile, 'content');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, contains('Access denied')),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should fail when parent path is not allowed', () async {
        // Arrange
        final testFile = '${tempDir.path}/nested/test.txt';
        when(() => mockConfig.isPathAllowed(testFile)).thenReturn(true);
        when(() => mockConfig.isPathAllowed('${tempDir.path}/nested'))
            .thenReturn(false);

        // Act
        final result = await service.writeFile(testFile, 'content');

        // Assert
        expect(result.isLeft(), true);
      });

      test('should fail with path traversal attempt', () async {
        // Arrange
        final maliciousPath = '${tempDir.path}/../test.txt';
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act
        final result = await service.writeFile(maliciousPath, 'content');

        // Assert
        expect(result.isLeft(), true);
      });

      test('should overwrite existing file', () async {
        // Arrange
        final testFile = '${tempDir.path}/test.txt';
        await File(testFile).writeAsString('old content');
        when(() => mockConfig.isPathAllowed(testFile)).thenReturn(true);

        // Act
        final result = await service.writeFile(testFile, 'new content');

        // Assert
        expect(result.isRight(), true);
        expect(await File(testFile).readAsString(), 'new content');
      });
    });

    group('deleteFile', () {
      test('should successfully delete file when path is valid', () async {
        // Arrange
        final testFile = File('${tempDir.path}/delete_test.txt');
        await testFile.writeAsString('test');
        when(() => mockConfig.isPathAllowed(testFile.path)).thenReturn(true);

        // Act
        final result = await service.deleteFile(testFile.path);

        // Assert
        expect(result.isRight(), true);
        expect(await testFile.exists(), false);
        verify(() => mockConfig.debugLog(any())).called(1);
      });

      test('should fail when file does not exist', () async {
        // Arrange
        final nonExistentPath = '${tempDir.path}/nonexistent.txt';
        when(() => mockConfig.isPathAllowed(nonExistentPath)).thenReturn(true);

        // Act
        final result = await service.deleteFile(nonExistentPath);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, contains('File not found')),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should fail when path is not allowed', () async {
        // Arrange
        final testFile = File('${tempDir.path}/test.txt');
        await testFile.writeAsString('test');
        when(() => mockConfig.isPathAllowed(testFile.path)).thenReturn(false);

        // Act
        final result = await service.deleteFile(testFile.path);

        // Assert
        expect(result.isLeft(), true);
        expect(await testFile.exists(), true); // File should still exist
      });
    });

    group('listDirectory', () {
      test('should successfully list directory contents', () async {
        // Arrange
        await File('${tempDir.path}/file1.txt').writeAsString('test1');
        await File('${tempDir.path}/file2.txt').writeAsString('test2');
        await Directory('${tempDir.path}/subdir').create();
        when(() => mockConfig.isPathAllowed(tempDir.path)).thenReturn(true);

        // Act
        final result = await service.listDirectory(tempDir.path);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (error) => fail('Expected Right but got Left: $error'),
          (entities) {
            expect(entities.length, 3);
            verify(() => mockConfig.debugLog(any())).called(1);
          },
        );
      });

      test('should list directory recursively when recursive is true', () async {
        // Arrange
        await File('${tempDir.path}/file1.txt').writeAsString('test1');
        final subdir = await Directory('${tempDir.path}/subdir').create();
        await File('${subdir.path}/file2.txt').writeAsString('test2');
        when(() => mockConfig.isPathAllowed(tempDir.path)).thenReturn(true);

        // Act
        final result =
            await service.listDirectory(tempDir.path, recursive: true);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (error) => fail('Expected Right but got Left: $error'),
          (entities) => expect(entities.length, greaterThan(2)),
        );
      });

      test('should fail when directory does not exist', () async {
        // Arrange
        final nonExistentPath = '${tempDir.path}/nonexistent';
        when(() => mockConfig.isPathAllowed(nonExistentPath)).thenReturn(true);

        // Act
        final result = await service.listDirectory(nonExistentPath);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, contains('Directory not found')),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should fail when path is not allowed', () async {
        // Arrange
        when(() => mockConfig.isPathAllowed(tempDir.path)).thenReturn(false);

        // Act
        final result = await service.listDirectory(tempDir.path);

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('exists', () {
      test('should return true when file exists', () async {
        // Arrange
        final testFile = File('${tempDir.path}/exists_test.txt');
        await testFile.writeAsString('test');
        when(() => mockConfig.isPathAllowed(testFile.path)).thenReturn(true);

        // Act
        final result = await service.exists(testFile.path);

        // Assert
        expect(result, true);
      });

      test('should return true when directory exists', () async {
        // Arrange
        when(() => mockConfig.isPathAllowed(tempDir.path)).thenReturn(true);

        // Act
        final result = await service.exists(tempDir.path);

        // Assert
        expect(result, true);
      });

      test('should return false when path does not exist', () async {
        // Arrange
        final nonExistentPath = '${tempDir.path}/nonexistent.txt';
        when(() => mockConfig.isPathAllowed(nonExistentPath)).thenReturn(true);

        // Act
        final result = await service.exists(nonExistentPath);

        // Assert
        expect(result, false);
      });

      test('should return false when path is not allowed', () async {
        // Arrange
        final testFile = File('${tempDir.path}/test.txt');
        await testFile.writeAsString('test');
        when(() => mockConfig.isPathAllowed(testFile.path)).thenReturn(false);

        // Act
        final result = await service.exists(testFile.path);

        // Assert
        expect(result, false);
      });

      test('should return false on exception', () async {
        // Arrange
        final invalidPath = '/\0/invalid';
        when(() => mockConfig.isPathAllowed(invalidPath)).thenReturn(true);

        // Act
        final result = await service.exists(invalidPath);

        // Assert
        expect(result, false);
      });
    });

    group('getCanonicalPath', () {
      test('should resolve canonical path for valid file', () async {
        // Arrange
        final testFile = File('${tempDir.path}/test.txt');
        await testFile.writeAsString('test');
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act
        final result = await service.getCanonicalPath(testFile.path);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (error) => fail('Expected Right but got Left: $error'),
          (canonical) => expect(canonical, isNotEmpty),
        );
      });

      test('should fail when canonical path violates security policy',
          () async {
        // Arrange
        final testFile = File('${tempDir.path}/test.txt');
        await testFile.writeAsString('test');
        when(() => mockConfig.isPathAllowed(testFile.path)).thenReturn(true);
        when(() => mockConfig.isPathAllowed(any()))
            .thenReturn(false); // Deny canonical path

        // Act
        final result = await service.getCanonicalPath(testFile.path);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, contains('violates security policy')),
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should fail when path cannot be resolved', () async {
        // Arrange
        final nonExistentPath = '${tempDir.path}/nonexistent.txt';
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act
        final result = await service.getCanonicalPath(nonExistentPath);

        // Assert
        expect(result.isLeft(), true);
      });
    });

    group('_validatePath', () {
      test('should block paths with .. segments', () async {
        // Arrange
        final maliciousPath = '${tempDir.path}/../../../etc/passwd';
        await File('${tempDir.path}/test.txt').writeAsString('test');
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act
        final result = await service.readFile(maliciousPath);

        // Assert
        expect(result.isLeft(), true);
        verify(() => mockConfig.warnLog(any())).called(1);
      });

      test('should block suspicious paths like /etc/passwd', () async {
        // Arrange
        final suspiciousPath = '/etc/passwd';
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act
        final result = await service.readFile(suspiciousPath);

        // Assert
        expect(result.isLeft(), true);
      });

      test('should block suspicious paths like .ssh/id_rsa', () async {
        // Arrange
        final suspiciousPath = '${tempDir.path}/.ssh/id_rsa';
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act
        final result = await service.readFile(suspiciousPath);

        // Assert
        expect(result.isLeft(), true);
      });

      test('should block suspicious paths like .env', () async {
        // Arrange
        final suspiciousPath = '${tempDir.path}/.env';
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act
        final result = await service.readFile(suspiciousPath);

        // Assert
        expect(result.isLeft(), true);
      });

      test('should allow normal paths', () async {
        // Arrange
        final normalFile = File('${tempDir.path}/normal.txt');
        await normalFile.writeAsString('test');
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act
        final result = await service.readFile(normalFile.path);

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('integration tests', () {
      test('should perform complete read-write-delete cycle', () async {
        // Arrange
        final testFile = '${tempDir.path}/integration_test.txt';
        const content = 'Integration test content';
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);

        // Act & Assert - Write
        var result = await service.writeFile(testFile, content);
        expect(result.isRight(), true);

        // Act & Assert - Read
        final readResult = await service.readFile(testFile);
        expect(readResult.isRight(), true);
        readResult.fold(
          (error) => fail('Failed to read: $error'),
          (readContent) => expect(readContent, content),
        );

        // Act & Assert - Delete
        final deleteResult = await service.deleteFile(testFile);
        expect(deleteResult.isRight(), true);

        // Verify file is gone
        expect(await service.exists(testFile), false);
      });

      test('should handle multiple security violations gracefully', () async {
        // Arrange
        when(() => mockConfig.isPathAllowed(any())).thenReturn(true);
        final violations = [
          '${tempDir.path}/../../../etc/passwd',
          '${tempDir.path}/.ssh/id_rsa',
          '${tempDir.path}/.env',
        ];

        // Act & Assert
        for (final path in violations) {
          final result = await service.readFile(path);
          expect(result.isLeft(), true,
              reason: 'Should block suspicious path: $path');
        }

        // Verify warnings were logged
        verify(() => mockConfig.warnLog(any())).called(greaterThan(0));
      });
    });
  });
}
