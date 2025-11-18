import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/src/domain/value_objects/file_name.dart';
import 'package:multi_editor_core/src/domain/failures/domain_failure.dart';

void main() {
  group('FileName', () {
    group('create', () {
      test('should create valid file name', () {
        // Arrange
        const input = 'document.txt';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals(input));
      });

      test('should trim whitespace', () {
        // Arrange
        const input = '  file.dart  ';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals('file.dart'));
      });

      test('should accept dotfile', () {
        // Arrange
        const input = '.gitignore';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isRight, isTrue);
        expect(result.right.value, equals(input));
      });

      test('should reject empty name', () {
        // Arrange
        const input = '';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.field, equals('fileName'));
        expect(result.left.reason, contains('cannot be empty'));
      });

      test('should reject whitespace-only name', () {
        // Arrange
        const input = '   ';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.field, equals('fileName'));
      });

      test('should reject name exceeding max length', () {
        // Arrange
        final input = 'a' * (FileName.maxLength + 1);

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.reason, contains('cannot exceed ${FileName.maxLength}'));
      });

      test('should accept name at max length', () {
        // Arrange
        final input = 'a' * FileName.maxLength;

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isRight, isTrue);
      });

      test('should reject name with invalid characters', () {
        // Arrange
        const input = 'file<name>.txt';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.reason, contains('invalid characters'));
      });

      test('should reject name with slash', () {
        // Arrange
        const input = 'folder/file.txt';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isLeft, isTrue);
      });

      test('should reject name with space', () {
        // Arrange
        const input = 'my file.txt';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.reason, contains('invalid characters'));
      });

      test('should reject just a dot', () {
        // Arrange
        const input = '.';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.reason, contains('cannot be just a dot'));
      });

      test('should reject reserved Windows names', () {
        // Arrange
        const reservedNames = ['CON', 'PRN', 'AUX', 'NUL', 'COM1', 'LPT1'];

        for (final name in reservedNames) {
          // Act
          final result = FileName.create(name);

          // Assert
          expect(result.isLeft, isTrue,
              reason: '$name should be rejected as reserved');
          expect(result.left.reason, contains('reserved by the system'));
        }
      });

      test('should reject reserved names case-insensitively', () {
        // Arrange
        const input = 'con.txt';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isLeft, isTrue);
        expect(result.left.reason, contains('reserved'));
      });

      test('should accept name with multiple extensions', () {
        // Arrange
        const input = 'archive.tar.gz';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isRight, isTrue);
      });

      test('should accept name with hyphen and underscore', () {
        // Arrange
        const input = 'my_file-name.txt';

        // Act
        final result = FileName.create(input);

        // Assert
        expect(result.isRight, isTrue);
      });
    });

    group('extension', () {
      test('should extract single extension', () {
        // Arrange
        final fileName = FileName.create('document.txt').right;

        // Act
        final extension = fileName.extension;

        // Assert
        expect(extension, equals('txt'));
      });

      test('should extract last extension from multiple', () {
        // Arrange
        final fileName = FileName.create('archive.tar.gz').right;

        // Act
        final extension = fileName.extension;

        // Assert
        expect(extension, equals('gz'));
      });

      test('should return empty string for no extension', () {
        // Arrange
        final fileName = FileName.create('README').right;

        // Act
        final extension = fileName.extension;

        // Assert
        expect(extension, equals(''));
      });

      test('should return empty string for dotfile without extension', () {
        // Arrange
        final fileName = FileName.create('.gitignore').right;

        // Act
        final extension = fileName.extension;

        // Assert
        expect(extension, equals(''));
      });

      test('should extract extension from dotfile with extension', () {
        // Arrange
        final fileName = FileName.create('.bashrc.backup').right;

        // Act
        final extension = fileName.extension;

        // Assert
        expect(extension, equals('backup'));
      });
    });

    group('nameWithoutExtension', () {
      test('should get name without extension', () {
        // Arrange
        final fileName = FileName.create('document.txt').right;

        // Act
        final nameWithoutExt = fileName.nameWithoutExtension;

        // Assert
        expect(nameWithoutExt, equals('document'));
      });

      test('should get name without multiple extensions', () {
        // Arrange
        final fileName = FileName.create('archive.tar.gz').right;

        // Act
        final nameWithoutExt = fileName.nameWithoutExtension;

        // Assert
        expect(nameWithoutExt, equals('archive.tar'));
      });

      test('should return full name when no extension', () {
        // Arrange
        final fileName = FileName.create('README').right;

        // Act
        final nameWithoutExt = fileName.nameWithoutExtension;

        // Assert
        expect(nameWithoutExt, equals('README'));
      });

      test('should handle dotfile', () {
        // Arrange
        final fileName = FileName.create('.gitignore').right;

        // Act
        final nameWithoutExt = fileName.nameWithoutExtension;

        // Assert
        expect(nameWithoutExt, equals('.gitignore'));
      });
    });

    group('hasExtension', () {
      test('should detect file with extension', () {
        // Arrange
        final fileName = FileName.create('file.txt').right;

        // Act & Assert
        expect(fileName.hasExtension, isTrue);
      });

      test('should detect file without extension', () {
        // Arrange
        final fileName = FileName.create('README').right;

        // Act & Assert
        expect(fileName.hasExtension, isFalse);
      });

      test('should detect dotfile without extension', () {
        // Arrange
        final fileName = FileName.create('.gitignore').right;

        // Act & Assert
        expect(fileName.hasExtension, isFalse);
      });
    });

    group('equality', () {
      test('should be equal with same value', () {
        // Arrange
        final name1 = FileName.create('file.txt').right;
        final name2 = FileName.create('file.txt').right;

        // Act & Assert
        expect(name1, equals(name2));
        expect(name1.hashCode, equals(name2.hashCode));
      });

      test('should not be equal with different values', () {
        // Arrange
        final name1 = FileName.create('file1.txt').right;
        final name2 = FileName.create('file2.txt').right;

        // Act & Assert
        expect(name1, isNot(equals(name2)));
      });
    });

    group('toString', () {
      test('should return string value', () {
        // Arrange
        const value = 'document.txt';
        final fileName = FileName.create(value).right;

        // Act & Assert
        expect(fileName.toString(), equals(value));
      });
    });

    group('use cases', () {
      test('should validate typical source file names', () {
        // Arrange
        const validNames = [
          'main.dart',
          'app.component.ts',
          'test_file.py',
          'My-File.java',
          '.env',
          '.gitignore',
          'package.json',
          'README.md',
        ];

        for (final name in validNames) {
          // Act
          final result = FileName.create(name);

          // Assert
          expect(result.isRight, isTrue, reason: '$name should be valid');
        }
      });

      test('should reject common invalid patterns', () {
        // Arrange
        const invalidNames = [
          'file with spaces.txt',
          'file/with/slash.txt',
          'file<with>brackets.txt',
          'file:colon.txt',
          'file|pipe.txt',
          'CON',
          'PRN.txt',
          '.',
        ];

        for (final name in invalidNames) {
          // Act
          final result = FileName.create(name);

          // Assert
          expect(result.isLeft, isTrue, reason: '$name should be invalid');
        }
      });
    });
  });
}

extension on Either<DomainFailure, FileName> {
  bool get isLeft => fold((_) => true, (_) => false);
  bool get isRight => fold((_) => false, (_) => true);
  DomainFailure get left => fold((l) => l, (_) => throw StateError('Right'));
  FileName get right => fold((_) => throw StateError('Left'), (r) => r);
}
