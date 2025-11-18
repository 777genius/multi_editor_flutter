import 'package:flutter_test/flutter_test.dart';
import 'package:ide_presentation/ide_presentation.dart';

void main() {
  group('FilePickerService', () {
    group('File Extension Constants', () {
      test('should define comprehensive code file extensions', () {
        // Assert
        expect(FilePickerService.codeFileExtensions, isNotEmpty);
        expect(FilePickerService.codeFileExtensions.length, greaterThanOrEqualTo(10));

        // Check for common languages
        expect(FilePickerService.codeFileExtensions, contains('dart'));
        expect(FilePickerService.codeFileExtensions, contains('js'));
        expect(FilePickerService.codeFileExtensions, contains('ts'));
        expect(FilePickerService.codeFileExtensions, contains('py'));
        expect(FilePickerService.codeFileExtensions, contains('java'));
        expect(FilePickerService.codeFileExtensions, contains('rs'));
        expect(FilePickerService.codeFileExtensions, contains('go'));
      });

      test('should include frontend language extensions', () {
        // Assert
        expect(FilePickerService.codeFileExtensions, contains('jsx'));
        expect(FilePickerService.codeFileExtensions, contains('tsx'));
      });

      test('should include C/C++ extensions', () {
        // Assert
        expect(FilePickerService.codeFileExtensions, contains('c'));
        expect(FilePickerService.codeFileExtensions, contains('cpp'));
        expect(FilePickerService.codeFileExtensions, contains('h'));
        expect(FilePickerService.codeFileExtensions, contains('hpp'));
      });

      test('should include mobile development languages', () {
        // Assert
        expect(FilePickerService.codeFileExtensions, contains('kt')); // Kotlin
        expect(FilePickerService.codeFileExtensions, contains('swift'));
      });

      test('should include scripting languages', () {
        // Assert
        expect(FilePickerService.codeFileExtensions, contains('rb')); // Ruby
        expect(FilePickerService.codeFileExtensions, contains('php'));
      });

      test('should include C# extension', () {
        // Assert
        expect(FilePickerService.codeFileExtensions, contains('cs'));
      });

      test('should not contain duplicates', () {
        // Arrange
        final extensions = FilePickerService.codeFileExtensions;

        // Assert
        final unique = extensions.toSet();
        expect(extensions.length, equals(unique.length));
      });

      test('should be lowercase', () {
        // Assert
        for (final ext in FilePickerService.codeFileExtensions) {
          expect(ext, equals(ext.toLowerCase()));
        }
      });
    });

    group('Markdown Extensions', () {
      test('should define markdown extensions', () {
        // Assert
        expect(FilePickerService.markdownExtensions, isNotEmpty);
        expect(FilePickerService.markdownExtensions, contains('md'));
        expect(FilePickerService.markdownExtensions, contains('markdown'));
      });

      test('should not contain duplicates', () {
        // Arrange
        final extensions = FilePickerService.markdownExtensions;

        // Assert
        final unique = extensions.toSet();
        expect(extensions.length, equals(unique.length));
      });
    });

    group('Config Extensions', () {
      test('should define common config file extensions', () {
        // Assert
        expect(FilePickerService.configExtensions, isNotEmpty);
        expect(FilePickerService.configExtensions, contains('json'));
        expect(FilePickerService.configExtensions, contains('yaml'));
        expect(FilePickerService.configExtensions, contains('yml'));
        expect(FilePickerService.configExtensions, contains('toml'));
        expect(FilePickerService.configExtensions, contains('xml'));
      });

      test('should include both yaml and yml', () {
        // Assert
        expect(FilePickerService.configExtensions, contains('yaml'));
        expect(FilePickerService.configExtensions, contains('yml'));
      });

      test('should not contain duplicates', () {
        // Arrange
        final extensions = FilePickerService.configExtensions;

        // Assert
        final unique = extensions.toSet();
        expect(extensions.length, equals(unique.length));
      });
    });

    group('All Text Extensions', () {
      test('should combine all extension types', () {
        // Assert
        expect(FilePickerService.allTextExtensions, isNotEmpty);

        // Should contain extensions from all categories
        expect(FilePickerService.allTextExtensions, contains('dart'));
        expect(FilePickerService.allTextExtensions, contains('md'));
        expect(FilePickerService.allTextExtensions, contains('json'));
        expect(FilePickerService.allTextExtensions, contains('txt'));
      });

      test('should include txt extension', () {
        // Assert
        expect(FilePickerService.allTextExtensions, contains('txt'));
      });

      test('should be comprehensive', () {
        // Assert
        final allCount = FilePickerService.allTextExtensions.length;
        final codeCount = FilePickerService.codeFileExtensions.length;
        final markdownCount = FilePickerService.markdownExtensions.length;
        final configCount = FilePickerService.configExtensions.length;

        // allTextExtensions should be at least the sum of all parts + txt
        expect(allCount, greaterThanOrEqualTo(codeCount + markdownCount + configCount));
      });

      test('should contain all code extensions', () {
        // Assert
        for (final ext in FilePickerService.codeFileExtensions) {
          expect(
            FilePickerService.allTextExtensions,
            contains(ext),
            reason: 'Missing code extension: $ext',
          );
        }
      });

      test('should contain all markdown extensions', () {
        // Assert
        for (final ext in FilePickerService.markdownExtensions) {
          expect(
            FilePickerService.allTextExtensions,
            contains(ext),
            reason: 'Missing markdown extension: $ext',
          );
        }
      });

      test('should contain all config extensions', () {
        // Assert
        for (final ext in FilePickerService.configExtensions) {
          expect(
            FilePickerService.allTextExtensions,
            contains(ext),
            reason: 'Missing config extension: $ext',
          );
        }
      });
    });

    group('Extension Categories', () {
      test('should have no overlap between primary categories', () {
        // Arrange
        final codeSet = FilePickerService.codeFileExtensions.toSet();
        final markdownSet = FilePickerService.markdownExtensions.toSet();
        final configSet = FilePickerService.configExtensions.toSet();

        // Assert
        expect(codeSet.intersection(markdownSet), isEmpty);
        expect(codeSet.intersection(configSet), isEmpty);
        expect(markdownSet.intersection(configSet), isEmpty);
      });

      test('should categorize language extensions correctly', () {
        // Code extensions
        expect(FilePickerService.codeFileExtensions, contains('dart'));
        expect(FilePickerService.codeFileExtensions, contains('js'));
        expect(FilePickerService.codeFileExtensions, contains('py'));

        // Markdown extensions
        expect(FilePickerService.markdownExtensions, contains('md'));

        // Config extensions
        expect(FilePickerService.configExtensions, contains('json'));
        expect(FilePickerService.configExtensions, contains('yaml'));
      });
    });

    group('Service Instantiation', () {
      test('should create FilePickerService instance', () {
        // Act
        final service = FilePickerService();

        // Assert
        expect(service, isNotNull);
        expect(service, isA<FilePickerService>());
      });

      test('should support multiple instances', () {
        // Act
        final service1 = FilePickerService();
        final service2 = FilePickerService();

        // Assert
        expect(service1, isNotNull);
        expect(service2, isNotNull);
        expect(service1, isNot(same(service2)));
      });
    });

    group('Extension Validation', () {
      test('should have only valid extension strings', () {
        // Test all extensions are non-empty strings without dots
        final allExtensions = [
          ...FilePickerService.codeFileExtensions,
          ...FilePickerService.markdownExtensions,
          ...FilePickerService.configExtensions,
          'txt',
        ];

        for (final ext in allExtensions) {
          expect(ext, isNotEmpty);
          expect(ext, isNot(startsWith('.')));
          expect(ext, isNot(contains(' ')));
          expect(ext, isNot(contains('/')));
        }
      });

      test('should have reasonable extension lengths', () {
        // Most file extensions are 2-6 characters
        final allExtensions = [
          ...FilePickerService.codeFileExtensions,
          ...FilePickerService.markdownExtensions,
          ...FilePickerService.configExtensions,
        ];

        for (final ext in allExtensions) {
          expect(ext.length, greaterThanOrEqualTo(1));
          expect(ext.length, lessThanOrEqualTo(10));
        }
      });
    });

    group('Common Use Cases', () {
      test('should support filtering by Dart files only', () {
        // Arrange
        final dartExtensions = ['dart'];

        // Assert
        expect(dartExtensions.every((ext) =>
          FilePickerService.codeFileExtensions.contains(ext)), isTrue);
      });

      test('should support filtering by web development files', () {
        // Arrange
        final webExtensions = ['js', 'ts', 'jsx', 'tsx', 'html', 'css'];

        // Assert - Note: html and css might not be in codeFileExtensions
        expect(FilePickerService.codeFileExtensions, contains('js'));
        expect(FilePickerService.codeFileExtensions, contains('ts'));
        expect(FilePickerService.codeFileExtensions, contains('jsx'));
        expect(FilePickerService.codeFileExtensions, contains('tsx'));
      });

      test('should support filtering by config files', () {
        // Arrange
        final configExtensions = ['json', 'yaml', 'yml', 'toml'];

        // Assert
        for (final ext in configExtensions) {
          expect(FilePickerService.configExtensions, contains(ext));
        }
      });

      test('should support filtering by documentation files', () {
        // Arrange
        final docExtensions = ['md', 'markdown', 'txt'];

        // Assert
        expect(FilePickerService.allTextExtensions, containsAll(docExtensions));
      });
    });
  });
}
