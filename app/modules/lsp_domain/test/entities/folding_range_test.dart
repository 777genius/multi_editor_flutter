import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('FoldingRange', () {
    group('creation', () {
      test('should create folding range with start and end lines', () {
        // Act
        const foldingRange = FoldingRange(
          startLine: 10,
          endLine: 20,
        );

        // Assert
        expect(foldingRange.startLine, equals(10));
        expect(foldingRange.endLine, equals(20));
        expect(foldingRange.startCharacter, isNull);
        expect(foldingRange.endCharacter, isNull);
        expect(foldingRange.kind, isNull);
        expect(foldingRange.collapsedText, isNull);
      });

      test('should create folding range with character positions', () {
        // Act
        const foldingRange = FoldingRange(
          startLine: 5,
          startCharacter: 4,
          endLine: 15,
          endCharacter: 8,
        );

        // Assert
        expect(foldingRange.startCharacter, equals(4));
        expect(foldingRange.endCharacter, equals(8));
      });

      test('should create folding range with kind', () {
        // Act
        const foldingRange = FoldingRange(
          startLine: 0,
          endLine: 10,
          kind: FoldingRangeKind.imports,
        );

        // Assert
        expect(foldingRange.kind, equals(FoldingRangeKind.imports));
      });

      test('should create folding range with collapsed text', () {
        // Act
        const foldingRange = FoldingRange(
          startLine: 10,
          endLine: 50,
          collapsedText: '... 40 lines ...',
        );

        // Assert
        expect(foldingRange.collapsedText, equals('... 40 lines ...'));
      });
    });

    group('FoldingRangeKind', () {
      test('should have comment kind', () {
        expect(FoldingRangeKind.values, contains(FoldingRangeKind.comment));
      });

      test('should have imports kind', () {
        expect(FoldingRangeKind.values, contains(FoldingRangeKind.imports));
      });

      test('should have region kind', () {
        expect(FoldingRangeKind.values, contains(FoldingRangeKind.region));
      });

      test('should have other kind', () {
        expect(FoldingRangeKind.values, contains(FoldingRangeKind.other));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        const range1 = FoldingRange(startLine: 5, endLine: 15);
        const range2 = FoldingRange(startLine: 5, endLine: 15);

        expect(range1, equals(range2));
        expect(range1.hashCode, equals(range2.hashCode));
      });

      test('should not be equal with different start line', () {
        const range1 = FoldingRange(startLine: 5, endLine: 15);
        const range2 = FoldingRange(startLine: 10, endLine: 15);

        expect(range1, isNot(equals(range2)));
      });

      test('should not be equal with different end line', () {
        const range1 = FoldingRange(startLine: 5, endLine: 15);
        const range2 = FoldingRange(startLine: 5, endLine: 20);

        expect(range1, isNot(equals(range2)));
      });

      test('should not be equal with different kind', () {
        const range1 = FoldingRange(
          startLine: 5,
          endLine: 15,
          kind: FoldingRangeKind.comment,
        );

        const range2 = FoldingRange(
          startLine: 5,
          endLine: 15,
          kind: FoldingRangeKind.imports,
        );

        expect(range1, isNot(equals(range2)));
      });
    });

    group('use cases', () {
      test('should represent function body folding', () {
        const foldingRange = FoldingRange(
          startLine: 10,
          startCharacter: 0,
          endLine: 50,
          endCharacter: 1,
          collapsedText: 'function body',
        );

        expect(foldingRange.startLine, equals(10));
        expect(foldingRange.endLine, equals(50));
        expect(foldingRange.collapsedText, equals('function body'));
      });

      test('should represent class definition folding', () {
        const foldingRange = FoldingRange(
          startLine: 5,
          endLine: 100,
          kind: FoldingRangeKind.region,
        );

        expect(foldingRange.kind, equals(FoldingRangeKind.region));
      });

      test('should represent comment block folding', () {
        const foldingRange = FoldingRange(
          startLine: 1,
          endLine: 10,
          kind: FoldingRangeKind.comment,
          collapsedText: '/** ... */',
        );

        expect(foldingRange.kind, equals(FoldingRangeKind.comment));
        expect(foldingRange.collapsedText, contains('...'));
      });

      test('should represent import section folding', () {
        const foldingRange = FoldingRange(
          startLine: 0,
          endLine: 15,
          kind: FoldingRangeKind.imports,
          collapsedText: 'imports',
        );

        expect(foldingRange.kind, equals(FoldingRangeKind.imports));
        expect(foldingRange.startLine, equals(0));
      });

      test('should represent custom region folding', () {
        const foldingRange = FoldingRange(
          startLine: 100,
          endLine: 200,
          kind: FoldingRangeKind.region,
          collapsedText: '// region Helper Methods',
        );

        expect(foldingRange.kind, equals(FoldingRangeKind.region));
        expect(foldingRange.collapsedText, contains('Helper Methods'));
      });
    });

    group('copyWith', () {
      test('should copy with new end line', () {
        const range = FoldingRange(startLine: 5, endLine: 15);

        final copied = range.copyWith(endLine: 25);

        expect(copied.endLine, equals(25));
        expect(copied.startLine, equals(range.startLine));
      });

      test('should copy with new kind', () {
        const range = FoldingRange(
          startLine: 5,
          endLine: 15,
          kind: FoldingRangeKind.comment,
        );

        final copied = range.copyWith(kind: FoldingRangeKind.region);

        expect(copied.kind, equals(FoldingRangeKind.region));
        expect(range.kind, equals(FoldingRangeKind.comment));
      });

      test('should copy with new collapsed text', () {
        const range = FoldingRange(
          startLine: 10,
          endLine: 20,
          collapsedText: 'old',
        );

        final copied = range.copyWith(collapsedText: 'new');

        expect(copied.collapsedText, equals('new'));
        expect(range.collapsedText, equals('old'));
      });
    });

    group('validation', () {
      test('should allow valid line ranges', () {
        const validRanges = [
          FoldingRange(startLine: 0, endLine: 1),
          FoldingRange(startLine: 10, endLine: 20),
          FoldingRange(startLine: 100, endLine: 1000),
        ];

        for (final range in validRanges) {
          expect(range.startLine, lessThanOrEqualTo(range.endLine));
        }
      });

      test('should handle character-level precision', () {
        const range = FoldingRange(
          startLine: 10,
          startCharacter: 5,
          endLine: 10,
          endCharacter: 20,
        );

        expect(range.startLine, equals(range.endLine));
        expect(range.startCharacter, lessThan(range.endCharacter!));
      });
    });

    group('sorting', () {
      test('should be sortable by start line', () {
        final ranges = [
          const FoldingRange(startLine: 50, endLine: 60),
          const FoldingRange(startLine: 10, endLine: 20),
          const FoldingRange(startLine: 30, endLine: 40),
        ];

        ranges.sort((a, b) => a.startLine.compareTo(b.startLine));

        expect(ranges[0].startLine, equals(10));
        expect(ranges[1].startLine, equals(30));
        expect(ranges[2].startLine, equals(50));
      });

      test('should be sortable by range size', () {
        final ranges = [
          const FoldingRange(startLine: 0, endLine: 100),
          const FoldingRange(startLine: 0, endLine: 10),
          const FoldingRange(startLine: 0, endLine: 50),
        ];

        ranges.sort((a, b) {
          final sizeA = a.endLine - a.startLine;
          final sizeB = b.endLine - b.startLine;
          return sizeA.compareTo(sizeB);
        });

        expect(ranges[0].endLine - ranges[0].startLine, equals(10));
        expect(ranges[1].endLine - ranges[1].startLine, equals(50));
        expect(ranges[2].endLine - ranges[2].startLine, equals(100));
      });
    });
  });
}
