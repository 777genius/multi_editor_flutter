import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_infrastructure/lsp_infrastructure.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('LspProtocolMappers', () {
    group('Position Mapping', () {
      test('should convert LSP position to domain position', () {
        // Arrange
        final lspJson = {
          'line': 10,
          'character': 5,
        };

        // Act
        final position = LspProtocolMappers.toDomainPosition(lspJson);

        // Assert
        expect(position.line, equals(10));
        expect(position.column, equals(5));
      });

      test('should convert domain position to LSP position', () {
        // Arrange
        final position = const CursorPosition(line: 15, column: 8);

        // Act
        final lspJson = LspProtocolMappers.fromDomainPosition(position);

        // Assert
        expect(lspJson['line'], equals(15));
        expect(lspJson['character'], equals(8));
      });

      test('should roundtrip position conversion', () {
        // Arrange
        final original = const CursorPosition(line: 20, column: 12);

        // Act
        final lspJson = LspProtocolMappers.fromDomainPosition(original);
        final converted = LspProtocolMappers.toDomainPosition(lspJson);

        // Assert
        expect(converted, equals(original));
      });

      test('should handle position at line 0', () {
        // Arrange
        final lspJson = {
          'line': 0,
          'character': 0,
        };

        // Act
        final position = LspProtocolMappers.toDomainPosition(lspJson);

        // Assert
        expect(position.line, equals(0));
        expect(position.column, equals(0));
      });

      test('should handle large line numbers', () {
        // Arrange
        final lspJson = {
          'line': 10000,
          'character': 500,
        };

        // Act
        final position = LspProtocolMappers.toDomainPosition(lspJson);

        // Assert
        expect(position.line, equals(10000));
        expect(position.column, equals(500));
      });
    });

    group('Range Mapping', () {
      test('should convert LSP range to domain selection', () {
        // Arrange
        final lspJson = {
          'start': {'line': 5, 'character': 0},
          'end': {'line': 5, 'character': 10},
        };

        // Act
        final selection = LspProtocolMappers.toDomainRange(lspJson);

        // Assert
        expect(selection.start.line, equals(5));
        expect(selection.start.column, equals(0));
        expect(selection.end.line, equals(5));
        expect(selection.end.column, equals(10));
      });

      test('should convert domain selection to LSP range', () {
        // Arrange
        final selection = TextSelection(
          start: const CursorPosition(line: 10, column: 5),
          end: const CursorPosition(line: 12, column: 8),
        );

        // Act
        final lspJson = LspProtocolMappers.fromDomainRange(selection);

        // Assert
        expect(lspJson['start']['line'], equals(10));
        expect(lspJson['start']['character'], equals(5));
        expect(lspJson['end']['line'], equals(12));
        expect(lspJson['end']['character'], equals(8));
      });

      test('should roundtrip range conversion', () {
        // Arrange
        final original = TextSelection(
          start: const CursorPosition(line: 3, column: 2),
          end: const CursorPosition(line: 4, column: 7),
        );

        // Act
        final lspJson = LspProtocolMappers.fromDomainRange(original);
        final converted = LspProtocolMappers.toDomainRange(lspJson);

        // Assert
        expect(converted.start, equals(original.start));
        expect(converted.end, equals(original.end));
      });

      test('should handle single-character selection', () {
        // Arrange
        final lspJson = {
          'start': {'line': 0, 'character': 5},
          'end': {'line': 0, 'character': 6},
        };

        // Act
        final selection = LspProtocolMappers.toDomainRange(lspJson);

        // Assert
        expect(selection.start.line, equals(selection.end.line));
        expect(selection.end.column - selection.start.column, equals(1));
      });

      test('should handle multi-line selection', () {
        // Arrange
        final lspJson = {
          'start': {'line': 10, 'character': 0},
          'end': {'line': 25, 'character': 50},
        };

        // Act
        final selection = LspProtocolMappers.toDomainRange(lspJson);

        // Assert
        expect(selection.start.line, equals(10));
        expect(selection.end.line, equals(25));
      });
    });

    group('TextDocument Identifier Mapping', () {
      test('should convert domain URI to LSP text document identifier', () {
        // Arrange
        final uri = DocumentUri.fromFilePath('/path/to/file.dart');

        // Act
        final lspJson = LspProtocolMappers.fromDomainUri(uri);

        // Assert
        expect(lspJson['uri'], contains('file.dart'));
        expect(lspJson['uri'], isA<String>());
      });

      test('should convert LSP URI to domain DocumentUri', () {
        // Arrange
        final lspJson = {
          'uri': 'file:///path/to/test.dart',
        };

        // Act
        final uri = LspProtocolMappers.toDomainUri(lspJson);

        // Assert
        expect(uri.path, contains('test.dart'));
      });

      test('should roundtrip URI conversion', () {
        // Arrange
        final original = DocumentUri.fromFilePath('/test/file.dart');

        // Act
        final lspJson = LspProtocolMappers.fromDomainUri(original);
        final converted = LspProtocolMappers.toDomainUri(lspJson);

        // Assert
        expect(converted.path, equals(original.path));
      });

      test('should handle file URIs with special characters', () {
        // Arrange
        final uri = DocumentUri.fromFilePath('/path/with spaces/file.dart');

        // Act
        final lspJson = LspProtocolMappers.fromDomainUri(uri);
        final converted = LspProtocolMappers.toDomainUri(lspJson);

        // Assert
        expect(converted.path, contains('with spaces'));
      });

      test('should handle Windows file paths', () {
        // Arrange
        final lspJson = {
          'uri': 'file:///C:/Users/test/file.dart',
        };

        // Act
        final uri = LspProtocolMappers.toDomainUri(lspJson);

        // Assert
        expect(uri.path, isNotEmpty);
      });
    });

    group('Language ID Mapping', () {
      test('should convert domain LanguageId to LSP string', () {
        // Act
        final dartId = LspProtocolMappers.fromDomainLanguageId(LanguageId.dart);
        final jsId = LspProtocolMappers.fromDomainLanguageId(LanguageId.javascript);
        final tsId = LspProtocolMappers.fromDomainLanguageId(LanguageId.typescript);

        // Assert
        expect(dartId, equals('dart'));
        expect(jsId, equals('javascript'));
        expect(tsId, equals('typescript'));
      });

      test('should convert LSP language string to domain LanguageId', () {
        // Act
        final dart = LspProtocolMappers.toDomainLanguageId('dart');
        final js = LspProtocolMappers.toDomainLanguageId('javascript');
        final python = LspProtocolMappers.toDomainLanguageId('python');

        // Assert
        expect(dart, equals(LanguageId.dart));
        expect(js, equals(LanguageId.javascript));
        expect(python, equals(LanguageId.python));
      });

      test('should roundtrip language ID conversion', () {
        // Arrange
        const languages = [
          LanguageId.dart,
          LanguageId.javascript,
          LanguageId.typescript,
          LanguageId.python,
          LanguageId.java,
        ];

        for (final original in languages) {
          // Act
          final lspString = LspProtocolMappers.fromDomainLanguageId(original);
          final converted = LspProtocolMappers.toDomainLanguageId(lspString);

          // Assert
          expect(converted, equals(original), reason: 'Failed for $original');
        }
      });

      test('should handle unknown language IDs', () {
        // Act
        final unknown = LspProtocolMappers.toDomainLanguageId('unknown-lang');

        // Assert
        expect(unknown, equals(LanguageId.plaintext));
      });
    });

    group('Edge Cases', () {
      test('should handle empty URI path', () {
        // Arrange
        final lspJson = {
          'uri': 'file:///',
        };

        // Act
        final uri = LspProtocolMappers.toDomainUri(lspJson);

        // Assert
        expect(uri, isNotNull);
      });

      test('should handle collapsed range (zero width)', () {
        // Arrange
        final lspJson = {
          'start': {'line': 5, 'character': 10},
          'end': {'line': 5, 'character': 10},
        };

        // Act
        final selection = LspProtocolMappers.toDomainRange(lspJson);

        // Assert
        expect(selection.start, equals(selection.end));
        expect(selection.isEmpty, isTrue);
      });

      test('should handle maximum integer values', () {
        // Arrange
        final lspJson = {
          'line': 2147483647,
          'character': 2147483647,
        };

        // Act
        final position = LspProtocolMappers.toDomainPosition(lspJson);

        // Assert
        expect(position.line, equals(2147483647));
        expect(position.column, equals(2147483647));
      });
    });
  });
}
