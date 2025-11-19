import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/multi_editor_core.dart';
import 'package:multi_editor_mock/multi_editor_mock.dart';

void main() {
  group('MockValidationService', () {
    late MockValidationService service;

    setUp(() {
      service = MockValidationService();
    });

    group('validateFileName', () {
      group('valid file names', () {
        test('should accept simple alphanumeric name', () {
          // Arrange
          const name = 'test123';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept name with dots', () {
          // Arrange
          const name = 'test.file.dart';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept name with hyphens', () {
          // Arrange
          const name = 'test-file-name.txt';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept name with underscores', () {
          // Arrange
          const name = 'test_file_name.dart';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept mixed case', () {
          // Arrange
          const name = 'TestFile.dart';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept numbers only', () {
          // Arrange
          const name = '12345.txt';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept long valid name', () {
          // Arrange
          const name = 'a' * 255;

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });
      });

      group('invalid file names', () {
        test('should reject empty name', () {
          // Arrange
          const name = '';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.type, equals(FailureType.validationError));
              expect(failure.field, equals('name'));
              expect(failure.reason, contains('cannot be empty'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name longer than 255 characters', () {
          // Arrange
          final name = 'a' * 256;

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.type, equals(FailureType.validationError));
              expect(failure.reason, contains('too long'));
              expect(failure.reason, contains('255'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name starting with dot', () {
          // Arrange
          const name = '.hidden';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.type, equals(FailureType.validationError));
              expect(failure.reason, contains('cannot start with a dot'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name starting with hyphen', () {
          // Arrange
          const name = '-test.txt';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.type, equals(FailureType.validationError));
              expect(failure.reason, contains('cannot start with'));
              expect(failure.reason, contains('hyphen'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name with spaces', () {
          // Arrange
          const name = 'test file.txt';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.type, equals(FailureType.validationError));
              expect(failure.reason, contains('invalid characters'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name with special characters', () {
          // Arrange
          final invalidChars = ['@', '#', '\$', '%', '^', '&', '*', '(', ')'];

          for (final char in invalidChars) {
            final name = 'test${char}file.txt';

            // Act
            final result = service.validateFileName(name);

            // Assert
            expect(result.isLeft(), isTrue,
                reason: 'Should reject "$char"');
          }
        });

        test('should reject name with forward slash', () {
          // Arrange
          const name = 'test/file.txt';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isLeft(), isTrue);
        });

        test('should reject name with backslash', () {
          // Arrange
          const name = 'test\\file.txt';

          // Act
          final result = service.validateFileName(name);

          // Assert
          expect(result.isLeft(), isTrue);
        });
      });
    });

    group('validateFilePath', () {
      group('valid file paths', () {
        test('should accept simple path', () {
          // Arrange
          const path = '/home/user/file.txt';

          // Act
          final result = service.validateFilePath(path);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept relative path', () {
          // Arrange
          const path = './src/main.dart';

          // Act
          final result = service.validateFilePath(path);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept nested path', () {
          // Arrange
          const path = '/very/long/nested/path/to/file.txt';

          // Act
          final result = service.validateFilePath(path);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept path with spaces', () {
          // Arrange
          const path = '/path/to/my file.txt';

          // Act
          final result = service.validateFilePath(path);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept Windows-style path', () {
          // Arrange
          const path = 'C:/Users/test/file.txt';

          // Act
          final result = service.validateFilePath(path);

          // Assert
          expect(result.isRight(), isTrue);
        });
      });

      group('invalid file paths', () {
        test('should reject empty path', () {
          // Arrange
          const path = '';

          // Act
          final result = service.validateFilePath(path);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.type, equals(FailureType.validationError));
              expect(failure.field, equals('path'));
              expect(failure.reason, contains('cannot be empty'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject path longer than 4096 characters', () {
          // Arrange
          final path = 'a' * 4097;

          // Act
          final result = service.validateFilePath(path);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.type, equals(FailureType.validationError));
              expect(failure.reason, contains('too long'));
              expect(failure.reason, contains('4096'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject path with invalid characters', () {
          // Arrange
          final invalidChars = ['<', '>', '"', '|', '?', '*'];

          for (final char in invalidChars) {
            final path = '/path${char}file.txt';

            // Act
            final result = service.validateFilePath(path);

            // Assert
            expect(result.isLeft(), isTrue,
                reason: 'Should reject "$char"');
            result.fold(
              (failure) {
                expect(failure.reason, contains('invalid characters'));
              },
              (_) => fail('Expected Left but got Right'),
            );
          }
        });
      });

      group('edge cases', () {
        test('should accept path at max length', () {
          // Arrange
          final path = 'a' * 4096;

          // Act
          final result = service.validateFilePath(path);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept single character path', () {
          // Arrange
          const path = '/';

          // Act
          final result = service.validateFilePath(path);

          // Assert
          expect(result.isRight(), isTrue);
        });
      });
    });

    group('validateFolderName', () {
      group('valid folder names', () {
        test('should accept simple alphanumeric name', () {
          // Arrange
          const name = 'src';

          // Act
          final result = service.validateFolderName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept name with dots', () {
          // Arrange
          const name = 'my.folder';

          // Act
          final result = service.validateFolderName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept name with hyphens', () {
          // Arrange
          const name = 'my-folder';

          // Act
          final result = service.validateFolderName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept name with underscores', () {
          // Arrange
          const name = 'my_folder';

          // Act
          final result = service.validateFolderName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });
      });

      group('invalid folder names', () {
        test('should reject empty name', () {
          // Arrange
          const name = '';

          // Act
          final result = service.validateFolderName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.type, equals(FailureType.validationError));
              expect(failure.field, equals('name'));
              expect(failure.reason, contains('cannot be empty'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name longer than 255 characters', () {
          // Arrange
          final name = 'a' * 256;

          // Act
          final result = service.validateFolderName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.reason, contains('too long'));
              expect(failure.reason, contains('255'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name starting with dot', () {
          // Arrange
          const name = '.hidden';

          // Act
          final result = service.validateFolderName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.reason, contains('cannot start with a dot'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name starting with hyphen', () {
          // Arrange
          const name = '-folder';

          // Act
          final result = service.validateFolderName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.reason, contains('cannot start with'));
              expect(failure.reason, contains('hyphen'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name with spaces', () {
          // Arrange
          const name = 'my folder';

          // Act
          final result = service.validateFolderName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.reason, contains('invalid characters'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name with special characters', () {
          // Arrange
          final invalidChars = ['@', '#', '\$', '%', '^', '&', '*'];

          for (final char in invalidChars) {
            final name = 'folder$char';

            // Act
            final result = service.validateFolderName(name);

            // Assert
            expect(result.isLeft(), isTrue,
                reason: 'Should reject "$char"');
          }
        });
      });
    });

    group('validateProjectName', () {
      group('valid project names', () {
        test('should accept simple name', () {
          // Arrange
          const name = 'MyProject';

          // Act
          final result = service.validateProjectName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept name with spaces', () {
          // Arrange
          const name = 'My Cool Project';

          // Act
          final result = service.validateProjectName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept name with hyphens', () {
          // Arrange
          const name = 'my-project';

          // Act
          final result = service.validateProjectName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept name with underscores', () {
          // Arrange
          const name = 'my_project';

          // Act
          final result = service.validateProjectName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept name at minimum length', () {
          // Arrange
          const name = 'abc';

          // Act
          final result = service.validateProjectName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });

        test('should accept name at maximum length', () {
          // Arrange
          final name = 'a' * 100;

          // Act
          final result = service.validateProjectName(name);

          // Assert
          expect(result.isRight(), isTrue);
        });
      });

      group('invalid project names', () {
        test('should reject empty name', () {
          // Arrange
          const name = '';

          // Act
          final result = service.validateProjectName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.type, equals(FailureType.validationError));
              expect(failure.field, equals('name'));
              expect(failure.reason, contains('cannot be empty'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name shorter than 3 characters', () {
          // Arrange
          const name = 'ab';

          // Act
          final result = service.validateProjectName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.reason, contains('at least 3 characters'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name longer than 100 characters', () {
          // Arrange
          final name = 'a' * 101;

          // Act
          final result = service.validateProjectName(name);

          // Assert
          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure.reason, contains('too long'));
              expect(failure.reason, contains('100'));
            },
            (_) => fail('Expected Left but got Right'),
          );
        });

        test('should reject name with special characters', () {
          // Arrange
          final invalidChars = ['@', '#', '\$', '%', '^', '&', '*'];

          for (final char in invalidChars) {
            final name = 'project$char';

            // Act
            final result = service.validateProjectName(name);

            // Assert
            expect(result.isLeft(), isTrue,
                reason: 'Should reject "$char"');
            result.fold(
              (failure) {
                expect(failure.reason, contains('invalid characters'));
              },
              (_) => fail('Expected Left but got Right'),
            );
          }
        });

        test('should reject name with dots', () {
          // Arrange
          const name = 'my.project';

          // Act
          final result = service.validateProjectName(name);

          // Assert
          expect(result.isLeft(), isTrue);
        });
      });
    });

    group('validateFileContent', () {
      test('should accept empty content', () {
        // Arrange
        const content = '';

        // Act
        final result = service.validateFileContent(content);

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should accept small content', () {
        // Arrange
        const content = 'Hello, World!';

        // Act
        final result = service.validateFileContent(content);

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should accept large content under limit', () {
        // Arrange
        final content = 'a' * (5 * 1024 * 1024); // 5MB

        // Act
        final result = service.validateFileContent(content);

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should accept content at max size', () {
        // Arrange
        final content = 'a' * (10 * 1024 * 1024); // 10MB

        // Act
        final result = service.validateFileContent(content);

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should reject content over 10MB', () {
        // Arrange
        final content = 'a' * (10 * 1024 * 1024 + 1); // 10MB + 1

        // Act
        final result = service.validateFileContent(content);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure.type, equals(FailureType.validationError));
            expect(failure.field, equals('content'));
            expect(failure.reason, contains('too large'));
            expect(failure.reason, contains('10MB'));
          },
          (_) => fail('Expected Left but got Right'),
        );
      });

      test('should accept content with special characters', () {
        // Arrange
        const content = 'Special chars: @#\$%^&*(){}[]|\\:;"\'<>,.?/~`';

        // Act
        final result = service.validateFileContent(content);

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should accept content with newlines', () {
        // Arrange
        const content = 'Line 1\nLine 2\nLine 3';

        // Act
        final result = service.validateFileContent(content);

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should accept content with unicode', () {
        // Arrange
        const content = 'Hello 世界 🌍';

        // Act
        final result = service.validateFileContent(content);

        // Assert
        expect(result.isRight(), isTrue);
      });
    });

    group('isValidLanguage', () {
      test('should recognize common programming languages', () {
        // Arrange
        final validLanguages = [
          'dart',
          'javascript',
          'typescript',
          'python',
          'java',
          'cpp',
          'c',
          'go',
          'rust',
        ];

        // Act & Assert
        for (final language in validLanguages) {
          expect(service.isValidLanguage(language), isTrue,
              reason: 'Should recognize $language');
        }
      });

      test('should recognize markup languages', () {
        // Arrange
        final validLanguages = ['html', 'css', 'json', 'yaml', 'markdown', 'xml'];

        // Act & Assert
        for (final language in validLanguages) {
          expect(service.isValidLanguage(language), isTrue,
              reason: 'Should recognize $language');
        }
      });

      test('should recognize scripting languages', () {
        // Arrange
        final validLanguages = ['ruby', 'php', 'shell'];

        // Act & Assert
        for (final language in validLanguages) {
          expect(service.isValidLanguage(language), isTrue,
              reason: 'Should recognize $language');
        }
      });

      test('should recognize mobile languages', () {
        // Arrange
        final validLanguages = ['swift', 'kotlin'];

        // Act & Assert
        for (final language in validLanguages) {
          expect(service.isValidLanguage(language), isTrue,
              reason: 'Should recognize $language');
        }
      });

      test('should recognize plaintext', () {
        // Act & Assert
        expect(service.isValidLanguage('plaintext'), isTrue);
      });

      test('should be case insensitive', () {
        // Act & Assert
        expect(service.isValidLanguage('DART'), isTrue);
        expect(service.isValidLanguage('JavaScript'), isTrue);
        expect(service.isValidLanguage('Python'), isTrue);
        expect(service.isValidLanguage('PYTHON'), isTrue);
      });

      test('should reject unknown languages', () {
        // Arrange
        final invalidLanguages = ['unknown', 'fake', 'invalid', 'xyz'];

        // Act & Assert
        for (final language in invalidLanguages) {
          expect(service.isValidLanguage(language), isFalse,
              reason: 'Should reject $language');
        }
      });

      test('should reject empty string', () {
        // Act & Assert
        expect(service.isValidLanguage(''), isFalse);
      });
    });

    group('hasValidExtension', () {
      test('should recognize common file extensions', () {
        // Arrange
        final validFiles = [
          'test.dart',
          'script.js',
          'app.ts',
          'main.py',
          'App.java',
        ];

        // Act & Assert
        for (final file in validFiles) {
          expect(service.hasValidExtension(file), isTrue,
              reason: 'Should recognize $file');
        }
      });

      test('should recognize C/C++ extensions', () {
        // Arrange
        final validFiles = ['main.c', 'main.cpp', 'header.h'];

        // Act & Assert
        for (final file in validFiles) {
          expect(service.hasValidExtension(file), isTrue,
              reason: 'Should recognize $file');
        }
      });

      test('should recognize web development extensions', () {
        // Arrange
        final validFiles = [
          'index.html',
          'style.css',
          'style.scss',
          'style.sass',
        ];

        // Act & Assert
        for (final file in validFiles) {
          expect(service.hasValidExtension(file), isTrue,
              reason: 'Should recognize $file');
        }
      });

      test('should recognize data format extensions', () {
        // Arrange
        final validFiles = [
          'data.json',
          'config.yaml',
          'config.yml',
          'doc.xml',
        ];

        // Act & Assert
        for (final file in validFiles) {
          expect(service.hasValidExtension(file), isTrue,
              reason: 'Should recognize $file');
        }
      });

      test('should recognize React extensions', () {
        // Arrange
        final validFiles = ['Component.tsx', 'Component.jsx'];

        // Act & Assert
        for (final file in validFiles) {
          expect(service.hasValidExtension(file), isTrue,
              reason: 'Should recognize $file');
        }
      });

      test('should be case insensitive', () {
        // Act & Assert
        expect(service.hasValidExtension('test.DART'), isTrue);
        expect(service.hasValidExtension('test.JS'), isTrue);
        expect(service.hasValidExtension('test.PY'), isTrue);
      });

      test('should handle multiple dots in filename', () {
        // Act & Assert
        expect(service.hasValidExtension('my.test.file.dart'), isTrue);
        expect(service.hasValidExtension('data.backup.json'), isTrue);
      });

      test('should reject files without extensions', () {
        // Act & Assert
        expect(service.hasValidExtension('README'), isFalse);
        expect(service.hasValidExtension('Makefile'), isFalse);
      });

      test('should reject invalid extensions', () {
        // Arrange
        final invalidFiles = [
          'file.xyz',
          'file.unknown',
          'file.fake',
        ];

        // Act & Assert
        for (final file in invalidFiles) {
          expect(service.hasValidExtension(file), isFalse,
              reason: 'Should reject $file');
        }
      });

      test('should handle edge cases', () {
        // Act & Assert
        expect(service.hasValidExtension('.dart'), isTrue);
        expect(service.hasValidExtension(''), isFalse);
        expect(service.hasValidExtension('.'), isFalse);
      });
    });

    group('integration tests', () {
      test('should validate complete file creation workflow', () {
        // Arrange
        const fileName = 'test_file.dart';
        const filePath = '/project/src/test_file.dart';
        const fileContent = 'void main() {}';

        // Act & Assert
        expect(service.validateFileName(fileName).isRight(), isTrue);
        expect(service.validateFilePath(filePath).isRight(), isTrue);
        expect(service.validateFileContent(fileContent).isRight(), isTrue);
        expect(service.hasValidExtension(fileName), isTrue);
        expect(service.isValidLanguage('dart'), isTrue);
      });

      test('should validate complete folder creation workflow', () {
        // Arrange
        const folderName = 'src';

        // Act & Assert
        expect(service.validateFolderName(folderName).isRight(), isTrue);
      });

      test('should validate complete project creation workflow', () {
        // Arrange
        const projectName = 'My Project';

        // Act & Assert
        expect(service.validateProjectName(projectName).isRight(), isTrue);
      });

      test('should handle validation of entire project structure', () {
        // Arrange
        const projectName = 'Flutter App';
        const folderNames = ['lib', 'test', 'assets'];
        const fileNames = ['main.dart', 'pubspec.yaml', 'README.md'];

        // Act & Assert
        expect(service.validateProjectName(projectName).isRight(), isTrue);

        for (final folder in folderNames) {
          expect(service.validateFolderName(folder).isRight(), isTrue,
              reason: 'Folder $folder should be valid');
        }

        for (final file in fileNames) {
          expect(service.validateFileName(file).isRight(), isTrue,
              reason: 'File $file should be valid');
        }
      });
    });

    group('boundary tests', () {
      test('should handle maximum valid file name length', () {
        // Arrange
        final name = 'a' * 255;

        // Act
        final result = service.validateFileName(name);

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should handle one character over max file name length', () {
        // Arrange
        final name = 'a' * 256;

        // Act
        final result = service.validateFileName(name);

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should handle maximum valid path length', () {
        // Arrange
        final path = 'a' * 4096;

        // Act
        final result = service.validateFilePath(path);

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should handle one character over max path length', () {
        // Arrange
        final path = 'a' * 4097;

        // Act
        final result = service.validateFilePath(path);

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should handle minimum valid project name length', () {
        // Arrange
        const name = 'abc';

        // Act
        final result = service.validateProjectName(name);

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should handle one character under min project name length', () {
        // Arrange
        const name = 'ab';

        // Act
        final result = service.validateProjectName(name);

        // Assert
        expect(result.isLeft(), isTrue);
      });

      test('should handle maximum valid content size', () {
        // Arrange
        final content = 'a' * (10 * 1024 * 1024);

        // Act
        final result = service.validateFileContent(content);

        // Assert
        expect(result.isRight(), isTrue);
      });

      test('should handle one byte over max content size', () {
        // Arrange
        final content = 'a' * (10 * 1024 * 1024 + 1);

        // Act
        final result = service.validateFileContent(content);

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });
  });
}
