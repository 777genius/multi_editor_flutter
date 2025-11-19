import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_file_icons/src/domain/value_objects/file_extension.dart';

void main() {
  group('FileExtension', () {
    group('constructor', () {
      test('should create instance with value', () {
        // Arrange & Act
        const extension = FileExtension(value: 'dart');

        // Assert
        expect(extension.value, 'dart');
      });

      test('should create instance with empty value', () {
        // Arrange & Act
        const extension = FileExtension(value: '');

        // Assert
        expect(extension.value, '');
      });

      test('should create instance with unknown', () {
        // Arrange & Act
        const extension = FileExtension(value: 'unknown');

        // Assert
        expect(extension.value, 'unknown');
        expect(extension.isUnknown, true);
      });
    });

    group('parse factory', () {
      test('should parse filename with extension', () {
        // Arrange & Act
        final extension = FileExtension.parse('main.dart');

        // Assert
        expect(extension.value, 'dart');
      });

      test('should parse filename with multiple dots', () {
        // Arrange & Act
        final extension = FileExtension.parse('package.json');

        // Assert
        expect(extension.value, 'json');
      });

      test('should parse filename with path', () {
        // Arrange & Act
        final extension = FileExtension.parse('/path/to/file.ts');

        // Assert
        expect(extension.value, 'ts');
      });

      test('should parse filename with long path', () {
        // Arrange & Act
        final extension = FileExtension.parse('/very/long/path/to/some/file.js');

        // Assert
        expect(extension.value, 'js');
      });

      test('should lowercase extension', () {
        // Arrange & Act
        final extension = FileExtension.parse('File.DART');

        // Assert
        expect(extension.value, 'dart');
      });

      test('should handle mixed case extensions', () {
        // Arrange
        final filenames = [
          'File.Dart',
          'File.DaRt',
          'FILE.DART',
          'file.dart',
        ];

        // Act & Assert
        for (final filename in filenames) {
          final extension = FileExtension.parse(filename);
          expect(extension.value, 'dart');
        }
      });

      test('should return unknown for empty filename', () {
        // Arrange & Act
        final extension = FileExtension.parse('');

        // Assert
        expect(extension.value, 'unknown');
        expect(extension.isUnknown, true);
      });

      test('should return unknown for filename without extension', () {
        // Arrange & Act
        final extension = FileExtension.parse('README');

        // Assert
        expect(extension.value, 'unknown');
      });

      test('should return unknown for filename ending with dot', () {
        // Arrange & Act
        final extension = FileExtension.parse('file.');

        // Assert
        expect(extension.value, 'unknown');
      });

      test('should return unknown for hidden file without extension', () {
        // Arrange & Act
        final extension = FileExtension.parse('.gitignore');

        // Assert
        expect(extension.value, 'unknown');
      });

      test('should parse hidden file with extension', () {
        // Arrange & Act
        final extension = FileExtension.parse('.hidden.dart');

        // Assert
        expect(extension.value, 'dart');
      });

      test('should handle common file extensions', () {
        // Arrange
        final files = {
          'file.dart': 'dart',
          'file.js': 'js',
          'file.ts': 'ts',
          'file.json': 'json',
          'file.yaml': 'yaml',
          'file.yml': 'yml',
          'file.md': 'md',
          'file.txt': 'txt',
          'file.html': 'html',
          'file.css': 'css',
          'file.py': 'py',
          'file.java': 'java',
          'file.cpp': 'cpp',
          'file.rs': 'rs',
          'file.go': 'go',
        };

        // Act & Assert
        files.forEach((filename, expectedExt) {
          final extension = FileExtension.parse(filename);
          expect(extension.value, expectedExt);
        });
      });

      test('should handle extensions with numbers', () {
        // Arrange & Act
        final extension = FileExtension.parse('file.mp3');

        // Assert
        expect(extension.value, 'mp3');
      });

      test('should handle extensions with underscores', () {
        // Arrange & Act
        final extension = FileExtension.parse('file.dart_tool');

        // Assert
        expect(extension.value, 'dart_tool');
      });

      test('should return unknown for invalid characters', () {
        // Arrange
        final invalidFiles = [
          'file.ex@t',
          'file.ex#t',
          'file.ex!t',
          'file.ex t',
          'file.ex-t',
        ];

        // Act & Assert
        for (final filename in invalidFiles) {
          final extension = FileExtension.parse(filename);
          expect(extension.value, 'unknown');
        }
      });

      test('should validate alphanumeric with underscore only', () {
        // Arrange
        final validFiles = [
          'file.dart',
          'file.abc123',
          'file.test_file',
          'file.a1b2c3',
        ];

        // Act & Assert
        for (final filename in validFiles) {
          final extension = FileExtension.parse(filename);
          expect(extension.isKnown, true);
        }
      });

      test('should handle complex filenames', () {
        // Arrange
        final files = {
          'package.lock.json': 'json',
          'file.backup.tar.gz': 'gz',
          'component.spec.ts': 'ts',
          'app.module.js': 'js',
        };

        // Act & Assert
        files.forEach((filename, expectedExt) {
          final extension = FileExtension.parse(filename);
          expect(extension.value, expectedExt);
        });
      });
    });

    group('isUnknown getter', () {
      test('should return true for unknown extension', () {
        // Arrange
        const extension = FileExtension(value: 'unknown');

        // Act & Assert
        expect(extension.isUnknown, true);
      });

      test('should return false for known extension', () {
        // Arrange
        const extension = FileExtension(value: 'dart');

        // Act & Assert
        expect(extension.isUnknown, false);
      });

      test('should return false for empty string', () {
        // Arrange
        const extension = FileExtension(value: '');

        // Act & Assert
        expect(extension.isUnknown, false);
      });
    });

    group('isKnown getter', () {
      test('should return false for unknown extension', () {
        // Arrange
        const extension = FileExtension(value: 'unknown');

        // Act & Assert
        expect(extension.isKnown, false);
      });

      test('should return true for known extension', () {
        // Arrange
        const extension = FileExtension(value: 'dart');

        // Act & Assert
        expect(extension.isKnown, true);
      });

      test('should return true for empty string', () {
        // Arrange
        const extension = FileExtension(value: '');

        // Act & Assert
        expect(extension.isKnown, true);
      });
    });

    group('toString', () {
      test('should return value', () {
        // Arrange
        const extension = FileExtension(value: 'dart');

        // Act
        final string = extension.toString();

        // Assert
        expect(string, 'dart');
      });

      test('should return unknown for unknown extension', () {
        // Arrange
        const extension = FileExtension(value: 'unknown');

        // Act
        final string = extension.toString();

        // Assert
        expect(string, 'unknown');
      });

      test('should return empty for empty extension', () {
        // Arrange
        const extension = FileExtension(value: '');

        // Act
        final string = extension.toString();

        // Assert
        expect(string, '');
      });
    });

    group('equality', () {
      test('should be equal when values are the same', () {
        // Arrange
        const extension1 = FileExtension(value: 'dart');
        const extension2 = FileExtension(value: 'dart');

        // Act & Assert
        expect(extension1, equals(extension2));
        expect(extension1.hashCode, equals(extension2.hashCode));
      });

      test('should not be equal when values differ', () {
        // Arrange
        const extension1 = FileExtension(value: 'dart');
        const extension2 = FileExtension(value: 'js');

        // Act & Assert
        expect(extension1, isNot(equals(extension2)));
      });

      test('should be equal for unknown extensions', () {
        // Arrange
        const extension1 = FileExtension(value: 'unknown');
        const extension2 = FileExtension(value: 'unknown');

        // Act & Assert
        expect(extension1, equals(extension2));
      });

      test('should be equal for empty extensions', () {
        // Arrange
        const extension1 = FileExtension(value: '');
        const extension2 = FileExtension(value: '');

        // Act & Assert
        expect(extension1, equals(extension2));
      });
    });

    group('copyWith', () {
      test('should copy with new value', () {
        // Arrange
        const original = FileExtension(value: 'dart');

        // Act
        final copied = original.copyWith(value: 'js');

        // Assert
        expect(copied.value, 'js');
        expect(original.value, 'dart');
      });

      test('should copy to unknown', () {
        // Arrange
        const original = FileExtension(value: 'dart');

        // Act
        final copied = original.copyWith(value: 'unknown');

        // Assert
        expect(copied.value, 'unknown');
        expect(copied.isUnknown, true);
      });

      test('should copy from unknown', () {
        // Arrange
        const original = FileExtension(value: 'unknown');

        // Act
        final copied = original.copyWith(value: 'dart');

        // Assert
        expect(copied.value, 'dart');
        expect(copied.isKnown, true);
      });
    });

    group('edge cases', () {
      test('should handle very long extensions', () {
        // Arrange
        final longExt = 'a' * 100;

        // Act
        final extension = FileExtension.parse('file.$longExt');

        // Assert
        expect(extension.value, longExt);
      });

      test('should handle single character extension', () {
        // Arrange & Act
        final extension = FileExtension.parse('file.c');

        // Assert
        expect(extension.value, 'c');
      });

      test('should handle numbers only extension', () {
        // Arrange & Act
        final extension = FileExtension.parse('file.123');

        // Assert
        expect(extension.value, '123');
      });

      test('should handle filenames with many dots', () {
        // Arrange & Act
        final extension = FileExtension.parse('my.super.long.file.name.dart');

        // Assert
        expect(extension.value, 'dart');
      });

      test('should handle Windows paths', () {
        // Arrange & Act
        final extension = FileExtension.parse('C:\\Users\\user\\file.dart');

        // Assert
        expect(extension.value, 'dart');
      });

      test('should handle Unix paths', () {
        // Arrange & Act
        final extension = FileExtension.parse('/home/user/file.dart');

        // Assert
        expect(extension.value, 'dart');
      });

      test('should handle relative paths', () {
        // Arrange
        final paths = [
          './file.dart',
          '../file.dart',
          '../../file.dart',
        ];

        // Act & Assert
        for (final path in paths) {
          final extension = FileExtension.parse(path);
          expect(extension.value, 'dart');
        }
      });

      test('should handle dot files in subdirectories', () {
        // Arrange & Act
        final extension = FileExtension.parse('/path/to/.hidden/file.dart');

        // Assert
        expect(extension.value, 'dart');
      });

      test('should parse case sensitivity correctly', () {
        // Arrange
        final extension1 = FileExtension.parse('file.DART');
        final extension2 = FileExtension.parse('file.dart');

        // Act & Assert
        expect(extension1, equals(extension2));
        expect(extension1.value, extension2.value);
      });
    });

    group('practical examples', () {
      test('should parse Dart file', () {
        // Arrange & Act
        final extension = FileExtension.parse('main.dart');

        // Assert
        expect(extension.value, 'dart');
        expect(extension.isKnown, true);
      });

      test('should parse JavaScript file', () {
        // Arrange & Act
        final extension = FileExtension.parse('index.js');

        // Assert
        expect(extension.value, 'js');
        expect(extension.isKnown, true);
      });

      test('should parse TypeScript file', () {
        // Arrange & Act
        final extension = FileExtension.parse('app.ts');

        // Assert
        expect(extension.value, 'ts');
        expect(extension.isKnown, true);
      });

      test('should parse JSON config file', () {
        // Arrange & Act
        final extension = FileExtension.parse('package.json');

        // Assert
        expect(extension.value, 'json');
        expect(extension.isKnown, true);
      });

      test('should parse YAML file', () {
        // Arrange & Act
        final extension = FileExtension.parse('pubspec.yaml');

        // Assert
        expect(extension.value, 'yaml');
        expect(extension.isKnown, true);
      });

      test('should handle README file', () {
        // Arrange & Act
        final extension = FileExtension.parse('README');

        // Assert
        expect(extension.value, 'unknown');
        expect(extension.isUnknown, true);
      });

      test('should handle README.md file', () {
        // Arrange & Act
        final extension = FileExtension.parse('README.md');

        // Assert
        expect(extension.value, 'md');
        expect(extension.isKnown, true);
      });

      test('should handle gitignore file', () {
        // Arrange & Act
        final extension = FileExtension.parse('.gitignore');

        // Assert
        expect(extension.value, 'unknown');
        expect(extension.isUnknown, true);
      });

      test('should parse full file path', () {
        // Arrange & Act
        final extension = FileExtension.parse(
          '/home/user/projects/my_app/lib/src/main.dart',
        );

        // Assert
        expect(extension.value, 'dart');
        expect(extension.isKnown, true);
      });

      test('should parse file with version in name', () {
        // Arrange & Act
        final extension = FileExtension.parse('package.v1.2.3.json');

        // Assert
        expect(extension.value, 'json');
        expect(extension.isKnown, true);
      });
    });

    group('common file types', () {
      test('should parse programming language files', () {
        // Arrange
        final files = {
          'file.dart': 'dart',
          'file.java': 'java',
          'file.py': 'py',
          'file.rb': 'rb',
          'file.go': 'go',
          'file.rs': 'rs',
          'file.cpp': 'cpp',
          'file.c': 'c',
          'file.h': 'h',
          'file.swift': 'swift',
          'file.kt': 'kt',
        };

        // Act & Assert
        files.forEach((filename, expectedExt) {
          final extension = FileExtension.parse(filename);
          expect(extension.value, expectedExt);
          expect(extension.isKnown, true);
        });
      });

      test('should parse web files', () {
        // Arrange
        final files = {
          'file.html': 'html',
          'file.css': 'css',
          'file.js': 'js',
          'file.ts': 'ts',
          'file.jsx': 'jsx',
          'file.tsx': 'tsx',
          'file.vue': 'vue',
          'file.scss': 'scss',
          'file.sass': 'sass',
          'file.less': 'less',
        };

        // Act & Assert
        files.forEach((filename, expectedExt) {
          final extension = FileExtension.parse(filename);
          expect(extension.value, expectedExt);
          expect(extension.isKnown, true);
        });
      });

      test('should parse data files', () {
        // Arrange
        final files = {
          'file.json': 'json',
          'file.yaml': 'yaml',
          'file.yml': 'yml',
          'file.xml': 'xml',
          'file.csv': 'csv',
          'file.sql': 'sql',
          'file.toml': 'toml',
        };

        // Act & Assert
        files.forEach((filename, expectedExt) {
          final extension = FileExtension.parse(filename);
          expect(extension.value, expectedExt);
          expect(extension.isKnown, true);
        });
      });

      test('should parse document files', () {
        // Arrange
        final files = {
          'file.md': 'md',
          'file.txt': 'txt',
          'file.pdf': 'pdf',
          'file.doc': 'doc',
          'file.docx': 'docx',
        };

        // Act & Assert
        files.forEach((filename, expectedExt) {
          final extension = FileExtension.parse(filename);
          expect(extension.value, expectedExt);
          expect(extension.isKnown, true);
        });
      });

      test('should parse image files', () {
        // Arrange
        final files = {
          'file.png': 'png',
          'file.jpg': 'jpg',
          'file.jpeg': 'jpeg',
          'file.gif': 'gif',
          'file.svg': 'svg',
          'file.webp': 'webp',
          'file.ico': 'ico',
        };

        // Act & Assert
        files.forEach((filename, expectedExt) {
          final extension = FileExtension.parse(filename);
          expect(extension.value, expectedExt);
          expect(extension.isKnown, true);
        });
      });
    });
  });
}
