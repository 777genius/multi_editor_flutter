import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('DocumentLink', () {
    group('Construction', () {
      test('should create with range only', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 5, column: 10),
          end: const CursorPosition(line: 5, column: 30),
        );

        // Act
        final link = DocumentLink(range: range);

        // Assert
        expect(link.range, equals(range));
        expect(link.target, isNull);
        expect(link.tooltip, isNull);
        expect(link.data, isNull);
      });

      test('should create with target URL', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 20),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: 'https://example.com',
        );

        // Assert
        expect(link.target, equals('https://example.com'));
      });

      test('should create with tooltip', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 10),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: 'https://docs.example.com',
          tooltip: 'Open documentation',
        );

        // Assert
        expect(link.tooltip, equals('Open documentation'));
      });

      test('should create with all parameters', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 5, column: 0),
          end: const CursorPosition(line: 5, column: 15),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: './config.json',
          tooltip: 'Open config file',
          data: {'type': 'file'},
        );

        // Assert
        expect(link.range, equals(range));
        expect(link.target, equals('./config.json'));
        expect(link.tooltip, equals('Open config file'));
        expect(link.data, isNotNull);
      });
    });

    group('Use Cases - URLs', () {
      test('should represent HTTP URL', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 10, column: 20),
          end: const CursorPosition(line: 10, column: 40),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: 'http://example.com',
        );

        // Assert
        expect(link.target, startsWith('http://'));
      });

      test('should represent HTTPS URL', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 25),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: 'https://github.com/repo',
        );

        // Assert
        expect(link.target, startsWith('https://'));
        expect(link.target, contains('github.com'));
      });

      test('should represent URL with path and query', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 5, column: 0),
          end: const CursorPosition(line: 5, column: 50),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: 'https://api.example.com/v1/users?page=1&limit=10',
        );

        // Assert
        expect(link.target, contains('/v1/users'));
        expect(link.target, contains('page=1'));
      });

      test('should represent documentation link with tooltip', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 3, column: 5),
          end: const CursorPosition(line: 3, column: 30),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: 'https://dart.dev/guides',
          tooltip: 'Dart programming language guides',
        );

        // Assert
        expect(link.tooltip, contains('Dart'));
        expect(link.tooltip, contains('guides'));
      });
    });

    group('Use Cases - File Paths', () {
      test('should represent relative file path', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 15),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: './config.json',
        );

        // Assert
        expect(link.target, startsWith('./'));
        expect(link.target, endsWith('.json'));
      });

      test('should represent parent directory path', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 1, column: 0),
          end: const CursorPosition(line: 1, column: 20),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: '../package.json',
        );

        // Assert
        expect(link.target, startsWith('../'));
      });

      test('should represent absolute file path', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 2, column: 0),
          end: const CursorPosition(line: 2, column: 25),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: '/etc/config/settings.yaml',
        );

        // Assert
        expect(link.target, startsWith('/'));
      });

      test('should represent Windows file path', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 20),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: 'C:\\Users\\config.ini',
        );

        // Assert
        expect(link.target, contains(':\\'));
      });
    });

    group('Use Cases - Package/Import Paths', () {
      test('should represent Dart package import', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 7),
          end: const CursorPosition(line: 0, column: 30),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: 'package:flutter/material.dart',
        );

        // Assert
        expect(link.target, startsWith('package:'));
        expect(link.target, contains('flutter'));
      });

      test('should represent npm package', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 10),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: 'react',
          tooltip: 'npm package: react',
        );

        // Assert
        expect(link.target, equals('react'));
      });

      test('should represent scoped npm package', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 1, column: 0),
          end: const CursorPosition(line: 1, column: 20),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: '@angular/core',
        );

        // Assert
        expect(link.target, startsWith('@'));
        expect(link.target, contains('/'));
      });
    });

    group('Unresolved Links', () {
      test('should support unresolved link with data for resolution', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 10),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: null, // Will be resolved later
          data: {
            'type': 'import',
            'module': 'lodash',
          },
        );

        // Assert
        expect(link.target, isNull);
        expect(link.data, isNotNull);
      });

      test('should resolve link by updating target', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 10),
        );
        final unresolved = DocumentLink(range: range, target: null);

        // Act
        final resolved = unresolved.copyWith(
          target: 'https://resolved-url.com',
        );

        // Assert
        expect(unresolved.target, isNull);
        expect(resolved.target, equals('https://resolved-url.com'));
      });
    });

    group('Link Ranges', () {
      test('should support single-line link', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 5, column: 10),
          end: const CursorPosition(line: 5, column: 30),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: 'https://example.com',
        );

        // Assert
        expect(link.range.start.line, equals(link.range.end.line));
      });

      test('should support multi-line link', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 10, column: 0),
          end: const CursorPosition(line: 12, column: 10),
        );

        // Act
        final link = DocumentLink(range: range, target: 'https://long-url.com');

        // Assert
        expect(link.range.start.line, lessThan(link.range.end.line));
      });

      test('should support zero-width range', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 5, column: 10),
          end: const CursorPosition(line: 5, column: 10),
        );

        // Act
        final link = DocumentLink(range: range);

        // Assert
        expect(link.range.isEmpty, isTrue);
      });
    });

    group('Tooltips', () {
      test('should provide helpful tooltip', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 20),
        );

        // Act
        final link = DocumentLink(
          range: range,
          target: 'https://flutter.dev',
          tooltip: 'Flutter official website',
        );

        // Assert
        expect(link.tooltip, contains('Flutter'));
      });

      test('should support tooltip without target', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 10),
        );

        // Act
        final link = DocumentLink(
          range: range,
          tooltip: 'Link will be resolved',
        );

        // Assert
        expect(link.target, isNull);
        expect(link.tooltip, isNotNull);
      });
    });

    group('Equality', () {
      test('should be equal with same values', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 10),
        );
        final link1 = DocumentLink(
          range: range,
          target: 'https://example.com',
        );
        final link2 = DocumentLink(
          range: range,
          target: 'https://example.com',
        );

        // Assert
        expect(link1, equals(link2));
      });

      test('should not be equal with different ranges', () {
        // Arrange
        final range1 = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 10),
        );
        final range2 = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 20),
        );
        final link1 = DocumentLink(range: range1, target: 'url');
        final link2 = DocumentLink(range: range2, target: 'url');

        // Assert
        expect(link1, isNot(equals(link2)));
      });

      test('should not be equal with different targets', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 10),
        );
        final link1 = DocumentLink(range: range, target: 'url1');
        final link2 = DocumentLink(range: range, target: 'url2');

        // Assert
        expect(link1, isNot(equals(link2)));
      });
    });

    group('Freezed Functionality', () {
      test('should support copyWith', () {
        // Arrange
        final range = TextSelection(
          start: const CursorPosition(line: 0, column: 0),
          end: const CursorPosition(line: 0, column: 10),
        );
        final original = DocumentLink(range: range);

        // Act
        final modified = original.copyWith(
          target: 'https://example.com',
          tooltip: 'Example site',
        );

        // Assert
        expect(modified.target, equals('https://example.com'));
        expect(modified.tooltip, equals('Example site'));
        expect(original.target, isNull); // Original unchanged
      });
    });
  });
}
