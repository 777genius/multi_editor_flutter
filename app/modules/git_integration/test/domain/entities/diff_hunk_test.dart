import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('DiffLine', () {
    group('creation', () {
      test('should create added line', () {
        // Arrange & Act
        const line = DiffLine(
          type: DiffLineType.added,
          content: 'new line',
          oldLineNumber: none(),
          newLineNumber: some(10),
        );

        // Assert
        expect(line.type, equals(DiffLineType.added));
        expect(line.content, equals('new line'));
        expect(line.isAdded, isTrue);
      });

      test('should create removed line', () {
        // Arrange & Act
        const line = DiffLine(
          type: DiffLineType.removed,
          content: 'old line',
          oldLineNumber: some(5),
          newLineNumber: none(),
        );

        // Assert
        expect(line.type, equals(DiffLineType.removed));
        expect(line.isRemoved, isTrue);
      });

      test('should create context line', () {
        // Arrange & Act
        const line = DiffLine(
          type: DiffLineType.context,
          content: 'context line',
          oldLineNumber: some(5),
          newLineNumber: some(10),
        );

        // Assert
        expect(line.type, equals(DiffLineType.context));
        expect(line.isContext, isTrue);
      });
    });

    group('prefix', () {
      test('should return + for added line', () {
        // Arrange
        const line = DiffLine(
          type: DiffLineType.added,
          content: 'new',
          oldLineNumber: none(),
          newLineNumber: some(1),
        );

        // Act & Assert
        expect(line.prefix, equals('+'));
      });

      test('should return - for removed line', () {
        // Arrange
        const line = DiffLine(
          type: DiffLineType.removed,
          content: 'old',
          oldLineNumber: some(1),
          newLineNumber: none(),
        );

        // Act & Assert
        expect(line.prefix, equals('-'));
      });

      test('should return space for context line', () {
        // Arrange
        const line = DiffLine(
          type: DiffLineType.context,
          content: 'context',
          oldLineNumber: some(1),
          newLineNumber: some(1),
        );

        // Act & Assert
        expect(line.prefix, equals(' '));
      });
    });

    group('formatForDisplay', () {
      test('should format added line with prefix', () {
        // Arrange
        const line = DiffLine(
          type: DiffLineType.added,
          content: 'new line',
          oldLineNumber: none(),
          newLineNumber: some(1),
        );

        // Act
        final formatted = line.formatForDisplay();

        // Assert
        expect(formatted, equals('+new line'));
      });

      test('should format removed line with prefix', () {
        // Arrange
        const line = DiffLine(
          type: DiffLineType.removed,
          content: 'old line',
          oldLineNumber: some(1),
          newLineNumber: none(),
        );

        // Act
        final formatted = line.formatForDisplay();

        // Assert
        expect(formatted, equals('-old line'));
      });

      test('should format context line with prefix', () {
        // Arrange
        const line = DiffLine(
          type: DiffLineType.context,
          content: 'context',
          oldLineNumber: some(1),
          newLineNumber: some(1),
        );

        // Act
        final formatted = line.formatForDisplay();

        // Assert
        expect(formatted, equals(' context'));
      });
    });
  });

  group('DiffHunk', () {
    late List<DiffLine> mixedLines;
    late List<DiffLine> addedOnlyLines;
    late List<DiffLine> removedOnlyLines;

    setUp(() {
      mixedLines = const [
        DiffLine(
          type: DiffLineType.context,
          content: 'unchanged',
          oldLineNumber: some(1),
          newLineNumber: some(1),
        ),
        DiffLine(
          type: DiffLineType.removed,
          content: 'old line',
          oldLineNumber: some(2),
          newLineNumber: none(),
        ),
        DiffLine(
          type: DiffLineType.added,
          content: 'new line',
          oldLineNumber: none(),
          newLineNumber: some(2),
        ),
        DiffLine(
          type: DiffLineType.context,
          content: 'another unchanged',
          oldLineNumber: some(3),
          newLineNumber: some(3),
        ),
      ];

      addedOnlyLines = const [
        DiffLine(
          type: DiffLineType.added,
          content: 'line 1',
          oldLineNumber: none(),
          newLineNumber: some(1),
        ),
        DiffLine(
          type: DiffLineType.added,
          content: 'line 2',
          oldLineNumber: none(),
          newLineNumber: some(2),
        ),
      ];

      removedOnlyLines = const [
        DiffLine(
          type: DiffLineType.removed,
          content: 'line 1',
          oldLineNumber: some(1),
          newLineNumber: none(),
        ),
        DiffLine(
          type: DiffLineType.removed,
          content: 'line 2',
          oldLineNumber: some(2),
          newLineNumber: none(),
        ),
      ];
    });

    group('creation', () {
      test('should create hunk with all fields', () {
        // Arrange & Act
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 3,
          lines: mixedLines,
          header: 'function main()',
        );

        // Assert
        expect(hunk.oldStart, equals(1));
        expect(hunk.oldCount, equals(3));
        expect(hunk.newStart, equals(1));
        expect(hunk.newCount, equals(3));
        expect(hunk.lines.length, equals(4));
        expect(hunk.header, equals('function main()'));
      });
    });

    group('line counts', () {
      test('should count added lines correctly', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 3,
          lines: mixedLines,
          header: '',
        );

        // Act
        final count = hunk.addedLinesCount;

        // Assert
        expect(count, equals(1));
      });

      test('should count removed lines correctly', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 3,
          lines: mixedLines,
          header: '',
        );

        // Act
        final count = hunk.removedLinesCount;

        // Assert
        expect(count, equals(1));
      });

      test('should count context lines correctly', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 3,
          lines: mixedLines,
          header: '',
        );

        // Act
        final count = hunk.contextLinesCount;

        // Assert
        expect(count, equals(2));
      });

      test('should return total lines count', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 3,
          lines: mixedLines,
          header: '',
        );

        // Act
        final count = hunk.totalLinesCount;

        // Assert
        expect(count, equals(4));
      });
    });

    group('hasChanges', () {
      test('should detect changes in mixed hunk', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 3,
          lines: mixedLines,
          header: '',
        );

        // Act & Assert
        expect(hunk.hasChanges, isTrue);
      });

      test('should detect no changes in context-only hunk', () {
        // Arrange
        const contextLines = [
          DiffLine(
            type: DiffLineType.context,
            content: 'line 1',
            oldLineNumber: some(1),
            newLineNumber: some(1),
          ),
        ];
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 1,
          newStart: 1,
          newCount: 1,
          lines: contextLines,
          header: '',
        );

        // Act & Assert
        expect(hunk.hasChanges, isFalse);
      });
    });

    group('change type detection', () {
      test('should detect only additions', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 0,
          newStart: 1,
          newCount: 2,
          lines: addedOnlyLines,
          header: '',
        );

        // Act & Assert
        expect(hunk.onlyAdditions, isTrue);
        expect(hunk.onlyDeletions, isFalse);
        expect(hunk.mixedChanges, isFalse);
      });

      test('should detect only deletions', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 2,
          newStart: 1,
          newCount: 0,
          lines: removedOnlyLines,
          header: '',
        );

        // Act & Assert
        expect(hunk.onlyDeletions, isTrue);
        expect(hunk.onlyAdditions, isFalse);
        expect(hunk.mixedChanges, isFalse);
      });

      test('should detect mixed changes', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 3,
          lines: mixedLines,
          header: '',
        );

        // Act & Assert
        expect(hunk.mixedChanges, isTrue);
        expect(hunk.onlyAdditions, isFalse);
        expect(hunk.onlyDeletions, isFalse);
      });
    });

    group('changeRatio', () {
      test('should calculate positive ratio for more additions', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 0,
          newStart: 1,
          newCount: 2,
          lines: addedOnlyLines,
          header: '',
        );

        // Act
        final ratio = hunk.changeRatio;

        // Assert
        expect(ratio, equals(1.0)); // All additions
      });

      test('should calculate negative ratio for more deletions', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 2,
          newStart: 1,
          newCount: 0,
          lines: removedOnlyLines,
          header: '',
        );

        // Act
        final ratio = hunk.changeRatio;

        // Assert
        expect(ratio, equals(-1.0)); // All deletions
      });

      test('should calculate zero ratio for balanced changes', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 3,
          lines: mixedLines,
          header: '',
        );

        // Act
        final ratio = hunk.changeRatio;

        // Assert
        expect(ratio, equals(0.0)); // Equal adds/removes
      });

      test('should return zero for no changes', () {
        // Arrange
        const contextLines = [
          DiffLine(
            type: DiffLineType.context,
            content: 'line',
            oldLineNumber: some(1),
            newLineNumber: some(1),
          ),
        ];
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 1,
          newStart: 1,
          newCount: 1,
          lines: contextLines,
          header: '',
        );

        // Act
        final ratio = hunk.changeRatio;

        // Assert
        expect(ratio, equals(0.0));
      });
    });

    group('hunkSize', () {
      test('should calculate hunk size correctly', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 5,
          newStart: 1,
          newCount: 7,
          lines: mixedLines,
          header: '',
        );

        // Act
        final size = hunk.hunkSize;

        // Assert
        expect(size, equals(12)); // 5 + 7
      });
    });

    group('oldRange and newRange', () {
      test('should calculate old range correctly', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 10,
          oldCount: 5,
          newStart: 1,
          newCount: 1,
          lines: mixedLines,
          header: '',
        );

        // Act
        final range = hunk.oldRange;

        // Assert
        expect(range, equals('10,14')); // 10 to 14
      });

      test('should calculate new range correctly', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 1,
          newStart: 20,
          newCount: 3,
          lines: mixedLines,
          header: '',
        );

        // Act
        final range = hunk.newRange;

        // Assert
        expect(range, equals('20,22')); // 20 to 22
      });
    });

    group('formattedHeader', () {
      test('should format header correctly', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 4,
          lines: mixedLines,
          header: 'function main()',
        );

        // Act
        final formatted = hunk.formattedHeader;

        // Assert
        expect(formatted, equals('@@ -1,3 +1,4 @@ function main()'));
      });

      test('should format header with empty context', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 10,
          oldCount: 5,
          newStart: 10,
          newCount: 6,
          lines: mixedLines,
          header: '',
        );

        // Act
        final formatted = hunk.formattedHeader;

        // Assert
        expect(formatted, equals('@@ -10,5 +10,6 @@ '));
      });
    });

    group('summary', () {
      test('should generate summary with change counts', () {
        // Arrange
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 4,
          lines: mixedLines,
          header: '',
        );

        // Act
        final summary = hunk.summary;

        // Assert
        expect(summary, contains('Hunk'));
        expect(summary, contains('+1'));
        expect(summary, contains('-1'));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        // Arrange
        final hunk1 = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 3,
          lines: mixedLines,
          header: 'test',
        );

        final hunk2 = DiffHunk(
          oldStart: 1,
          oldCount: 3,
          newStart: 1,
          newCount: 3,
          lines: mixedLines,
          header: 'test',
        );

        // Act & Assert
        expect(hunk1, equals(hunk2));
      });
    });

    group('use cases', () {
      test('should represent file addition hunk', () {
        // Arrange & Act
        final hunk = DiffHunk(
          oldStart: 0,
          oldCount: 0,
          newStart: 1,
          newCount: 10,
          lines: addedOnlyLines,
          header: '',
        );

        // Assert
        expect(hunk.onlyAdditions, isTrue);
        expect(hunk.removedLinesCount, equals(0));
        expect(hunk.changeRatio, equals(1.0));
      });

      test('should represent file deletion hunk', () {
        // Arrange & Act
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 10,
          newStart: 0,
          newCount: 0,
          lines: removedOnlyLines,
          header: '',
        );

        // Assert
        expect(hunk.onlyDeletions, isTrue);
        expect(hunk.addedLinesCount, equals(0));
        expect(hunk.changeRatio, equals(-1.0));
      });

      test('should represent code refactoring hunk', () {
        // Arrange & Act
        final hunk = DiffHunk(
          oldStart: 1,
          oldCount: 5,
          newStart: 1,
          newCount: 5,
          lines: mixedLines,
          header: 'class MyClass',
        );

        // Assert
        expect(hunk.mixedChanges, isTrue);
        expect(hunk.hasChanges, isTrue);
      });
    });
  });
}
