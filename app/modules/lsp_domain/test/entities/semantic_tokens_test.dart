import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('SemanticTokens', () {
    group('Construction', () {
      test('should create with empty data', () {
        // Act
        const tokens = SemanticTokens(data: []);

        // Assert
        expect(tokens.data, isEmpty);
        expect(tokens.resultId, isNull);
      });

      test('should create with token data', () {
        // Arrange - Each token is 5 integers
        const data = [
          0, 0, 5, 1, 0, // Token 1: line 0, char 0, length 5, type 1, mods 0
          0, 6, 4, 2, 0, // Token 2: line 0, char 6, length 4, type 2, mods 0
        ];

        // Act
        const tokens = SemanticTokens(data: data);

        // Assert
        expect(tokens.data.length, equals(10));
      });

      test('should create with result ID', () {
        // Act
        const tokens = SemanticTokens(
          resultId: 'result-123',
          data: [],
        );

        // Assert
        expect(tokens.resultId, equals('result-123'));
      });

      test('should create with all parameters', () {
        // Act
        const tokens = SemanticTokens(
          resultId: 'v1',
          data: [0, 0, 5, 1, 0],
        );

        // Assert
        expect(tokens.resultId, isNotNull);
        expect(tokens.data, isNotEmpty);
      });
    });

    group('empty constant', () {
      test('should provide empty tokens', () {
        // Act
        const tokens = SemanticTokens.empty;

        // Assert
        expect(tokens.data, isEmpty);
        expect(tokens.resultId, isNull);
      });

      test('should be const', () {
        // Act
        const tokens1 = SemanticTokens.empty;
        const tokens2 = SemanticTokens.empty;

        // Assert
        expect(identical(tokens1, tokens2), isTrue);
      });
    });

    group('Token Encoding', () {
      test('should encode token at document start', () {
        // Arrange - First token: line 0, char 0, length 3, type 0, mods 0
        const data = [0, 0, 3, 0, 0];

        // Act
        const tokens = SemanticTokens(data: data);

        // Assert
        expect(tokens.data[0], equals(0)); // deltaLine
        expect(tokens.data[1], equals(0)); // deltaStartChar
        expect(tokens.data[2], equals(3)); // length
        expect(tokens.data[3], equals(0)); // tokenType
        expect(tokens.data[4], equals(0)); // tokenModifiers
      });

      test('should encode multiple tokens on same line', () {
        // Arrange
        const data = [
          0, 0, 3, 0, 0, // Token 1: line 0, char 0-3
          0, 4, 5, 1, 0, // Token 2: line 0, char 4-9 (delta from prev)
        ];

        // Act
        const tokens = SemanticTokens(data: data);

        // Assert
        expect(tokens.data.length, equals(10));
        expect(tokens.data[5], equals(0)); // Same line (delta = 0)
        expect(tokens.data[6], equals(4)); // Delta from previous token
      });

      test('should encode tokens on different lines', () {
        // Arrange
        const data = [
          0, 0, 5, 0, 0,  // Token 1: line 0
          1, 0, 3, 1, 0,  // Token 2: line 1 (delta = 1)
        ];

        // Act
        const tokens = SemanticTokens(data: data);

        // Assert
        expect(tokens.data[5], equals(1)); // Next line (delta = 1)
        expect(tokens.data[6], equals(0)); // Start from beginning of line
      });

      test('should encode tokens with type indices', () {
        // Arrange - Different token types
        const data = [
          0, 0, 5, 0, 0,  // Type 0 (namespace)
          0, 6, 4, 1, 0,  // Type 1 (class)
          0, 11, 6, 2, 0, // Type 2 (function)
        ];

        // Act
        const tokens = SemanticTokens(data: data);

        // Assert
        expect(tokens.data[3], equals(0));  // First token type
        expect(tokens.data[8], equals(1));  // Second token type
        expect(tokens.data[13], equals(2)); // Third token type
      });

      test('should encode tokens with modifiers bitmask', () {
        // Arrange - Token with modifiers
        const data = [
          0, 0, 5, 1, 3, // Type 1, modifiers: bits 0 and 1 set (3 = 0b11)
        ];

        // Act
        const tokens = SemanticTokens(data: data);

        // Assert
        expect(tokens.data[4], equals(3)); // Modifier bitmask
      });

      test('should handle large documents with many tokens', () {
        // Arrange - 100 tokens
        final data = <int>[];
        for (var i = 0; i < 100; i++) {
          data.addAll([0, i, 3, 0, 0]);
        }

        // Act
        final tokens = SemanticTokens(data: data);

        // Assert
        expect(tokens.data.length, equals(500)); // 100 tokens * 5 values
      });
    });

    group('Equality', () {
      test('should be equal with same data', () {
        // Arrange
        const tokens1 = SemanticTokens(
          data: [0, 0, 5, 1, 0],
        );
        const tokens2 = SemanticTokens(
          data: [0, 0, 5, 1, 0],
        );

        // Assert
        expect(tokens1, equals(tokens2));
      });

      test('should not be equal with different data', () {
        // Arrange
        const tokens1 = SemanticTokens(data: [0, 0, 5, 1, 0]);
        const tokens2 = SemanticTokens(data: [0, 0, 5, 2, 0]);

        // Assert
        expect(tokens1, isNot(equals(tokens2)));
      });

      test('should not be equal with different result IDs', () {
        // Arrange
        const tokens1 = SemanticTokens(resultId: 'v1', data: []);
        const tokens2 = SemanticTokens(resultId: 'v2', data: []);

        // Assert
        expect(tokens1, isNot(equals(tokens2)));
      });
    });
  });

  group('SemanticTokensDelta', () {
    group('Construction', () {
      test('should create with empty edits', () {
        // Act
        const delta = SemanticTokensDelta(edits: []);

        // Assert
        expect(delta.edits, isEmpty);
        expect(delta.resultId, isNull);
      });

      test('should create with edits', () {
        // Arrange
        const edits = [
          SemanticTokensEdit(start: 0, deleteCount: 5),
        ];

        // Act
        const delta = SemanticTokensDelta(edits: edits);

        // Assert
        expect(delta.edits.length, equals(1));
      });

      test('should create with result ID', () {
        // Act
        const delta = SemanticTokensDelta(
          resultId: 'delta-123',
          edits: [],
        );

        // Assert
        expect(delta.resultId, equals('delta-123'));
      });
    });

    group('Multiple Edits', () {
      test('should support multiple edits', () {
        // Arrange
        const edits = [
          SemanticTokensEdit(start: 0, deleteCount: 5),
          SemanticTokensEdit(start: 10, deleteCount: 3, data: [0, 0, 3, 1, 0]),
        ];

        // Act
        const delta = SemanticTokensDelta(edits: edits);

        // Assert
        expect(delta.edits.length, equals(2));
      });
    });
  });

  group('SemanticTokensEdit', () {
    group('Construction', () {
      test('should create deletion edit', () {
        // Act
        const edit = SemanticTokensEdit(
          start: 10,
          deleteCount: 5,
        );

        // Assert
        expect(edit.start, equals(10));
        expect(edit.deleteCount, equals(5));
        expect(edit.data, isNull);
      });

      test('should create insertion edit', () {
        // Act
        const edit = SemanticTokensEdit(
          start: 10,
          deleteCount: 0,
          data: [0, 0, 3, 1, 0],
        );

        // Assert
        expect(edit.deleteCount, equals(0));
        expect(edit.data, isNotNull);
        expect(edit.data!.length, equals(5));
      });

      test('should create replacement edit', () {
        // Act
        const edit = SemanticTokensEdit(
          start: 5,
          deleteCount: 10,
          data: [0, 0, 5, 2, 0],
        );

        // Assert
        expect(edit.deleteCount, greaterThan(0));
        expect(edit.data, isNotNull);
      });

      test('should create edit at document start', () {
        // Act
        const edit = SemanticTokensEdit(
          start: 0,
          deleteCount: 3,
        );

        // Assert
        expect(edit.start, equals(0));
      });

      test('should create edit with large data', () {
        // Arrange - Multiple tokens
        const data = [
          0, 0, 5, 1, 0,
          0, 6, 3, 2, 0,
          1, 0, 4, 1, 0,
        ];

        // Act
        const edit = SemanticTokensEdit(
          start: 100,
          deleteCount: 15,
          data: data,
        );

        // Assert
        expect(edit.data!.length, equals(15));
      });
    });

    group('Edit Types', () {
      test('deletion only - removes tokens', () {
        // Act
        const edit = SemanticTokensEdit(
          start: 20,
          deleteCount: 10,
        );

        // Assert
        expect(edit.deleteCount, greaterThan(0));
        expect(edit.data, isNull);
      });

      test('insertion only - adds tokens', () {
        // Act
        const edit = SemanticTokensEdit(
          start: 0,
          deleteCount: 0,
          data: [0, 0, 3, 1, 0],
        );

        // Assert
        expect(edit.deleteCount, equals(0));
        expect(edit.data, isNotNull);
      });

      test('replacement - deletes and inserts', () {
        // Act
        const edit = SemanticTokensEdit(
          start: 15,
          deleteCount: 5,
          data: [0, 0, 10, 1, 0],
        );

        // Assert
        expect(edit.deleteCount, greaterThan(0));
        expect(edit.data, isNotNull);
      });
    });

    group('Equality', () {
      test('should be equal with same values', () {
        // Arrange
        const edit1 = SemanticTokensEdit(start: 10, deleteCount: 5);
        const edit2 = SemanticTokensEdit(start: 10, deleteCount: 5);

        // Assert
        expect(edit1, equals(edit2));
      });

      test('should not be equal with different start', () {
        // Arrange
        const edit1 = SemanticTokensEdit(start: 10, deleteCount: 5);
        const edit2 = SemanticTokensEdit(start: 15, deleteCount: 5);

        // Assert
        expect(edit1, isNot(equals(edit2)));
      });

      test('should not be equal with different data', () {
        // Arrange
        const edit1 = SemanticTokensEdit(start: 0, deleteCount: 0, data: [1, 2, 3]);
        const edit2 = SemanticTokensEdit(start: 0, deleteCount: 0, data: [4, 5, 6]);

        // Assert
        expect(edit1, isNot(equals(edit2)));
      });
    });
  });

  group('SemanticTokensLegend', () {
    group('Construction', () {
      test('should create with token types and modifiers', () {
        // Arrange
        const tokenTypes = ['namespace', 'class', 'function'];
        const tokenModifiers = ['declaration', 'readonly', 'static'];

        // Act
        const legend = SemanticTokensLegend(
          tokenTypes: tokenTypes,
          tokenModifiers: tokenModifiers,
        );

        // Assert
        expect(legend.tokenTypes.length, equals(3));
        expect(legend.tokenModifiers.length, equals(3));
      });

      test('should support standard LSP token types', () {
        // Arrange
        const tokenTypes = [
          'namespace',
          'type',
          'class',
          'enum',
          'interface',
          'struct',
          'typeParameter',
          'parameter',
          'variable',
          'property',
          'enumMember',
          'event',
          'function',
          'method',
          'macro',
          'keyword',
          'modifier',
          'comment',
          'string',
          'number',
          'regexp',
          'operator',
        ];

        // Act
        const legend = SemanticTokensLegend(
          tokenTypes: tokenTypes,
          tokenModifiers: [],
        );

        // Assert
        expect(legend.tokenTypes, contains('function'));
        expect(legend.tokenTypes, contains('class'));
        expect(legend.tokenTypes, contains('keyword'));
      });

      test('should support standard LSP token modifiers', () {
        // Arrange
        const tokenModifiers = [
          'declaration',
          'definition',
          'readonly',
          'static',
          'deprecated',
          'abstract',
          'async',
          'modification',
          'documentation',
          'defaultLibrary',
        ];

        // Act
        const legend = SemanticTokensLegend(
          tokenTypes: [],
          tokenModifiers: tokenModifiers,
        );

        // Assert
        expect(legend.tokenModifiers, contains('readonly'));
        expect(legend.tokenModifiers, contains('static'));
        expect(legend.tokenModifiers, contains('deprecated'));
      });

      test('should support empty lists', () {
        // Act
        const legend = SemanticTokensLegend(
          tokenTypes: [],
          tokenModifiers: [],
        );

        // Assert
        expect(legend.tokenTypes, isEmpty);
        expect(legend.tokenModifiers, isEmpty);
      });
    });

    group('Index Mapping', () {
      test('should map token type index to name', () {
        // Arrange
        const tokenTypes = ['namespace', 'class', 'function'];
        const legend = SemanticTokensLegend(
          tokenTypes: tokenTypes,
          tokenModifiers: [],
        );

        // Assert - index 0, 1, 2 map to types
        expect(legend.tokenTypes[0], equals('namespace'));
        expect(legend.tokenTypes[1], equals('class'));
        expect(legend.tokenTypes[2], equals('function'));
      });

      test('should map modifier bitmask to modifiers', () {
        // Arrange
        const tokenModifiers = ['readonly', 'static', 'deprecated'];
        const legend = SemanticTokensLegend(
          tokenTypes: [],
          tokenModifiers: tokenModifiers,
        );

        // Assert - bit 0, 1, 2 represent modifiers
        // Bitmask 0b101 (5) = readonly (bit 0) + deprecated (bit 2)
        expect(legend.tokenModifiers[0], equals('readonly'));  // bit 0
        expect(legend.tokenModifiers[1], equals('static'));    // bit 1
        expect(legend.tokenModifiers[2], equals('deprecated')); // bit 2
      });
    });

    group('Equality', () {
      test('should be equal with same values', () {
        // Arrange
        const legend1 = SemanticTokensLegend(
          tokenTypes: ['class', 'function'],
          tokenModifiers: ['readonly'],
        );
        const legend2 = SemanticTokensLegend(
          tokenTypes: ['class', 'function'],
          tokenModifiers: ['readonly'],
        );

        // Assert
        expect(legend1, equals(legend2));
      });

      test('should not be equal with different token types', () {
        // Arrange
        const legend1 = SemanticTokensLegend(
          tokenTypes: ['class'],
          tokenModifiers: [],
        );
        const legend2 = SemanticTokensLegend(
          tokenTypes: ['function'],
          tokenModifiers: [],
        );

        // Assert
        expect(legend1, isNot(equals(legend2)));
      });
    });
  });
}
