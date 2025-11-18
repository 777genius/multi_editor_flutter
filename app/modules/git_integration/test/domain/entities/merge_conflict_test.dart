import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('ConflictMarker', () {
    group('creation', () {
      test('should create conflict marker with line numbers', () {
        // Act
        const marker = ConflictMarker(
          startLine: 10,
          middleLine: 15,
          endLine: 20,
        );

        // Assert
        expect(marker.startLine, equals(10));
        expect(marker.middleLine, equals(15));
        expect(marker.endLine, equals(20));
      });
    });

    group('line counting', () {
      test('should calculate total line count', () {
        const marker = ConflictMarker(
          startLine: 10,
          middleLine: 15,
          endLine: 20,
        );

        expect(marker.lineCount, equals(11)); // 20 - 10 + 1
      });

      test('should calculate "ours" line count', () {
        const marker = ConflictMarker(
          startLine: 10,
          middleLine: 15,
          endLine: 20,
        );

        expect(marker.oursLineCount, equals(4)); // 15 - 10 - 1
      });

      test('should calculate "theirs" line count', () {
        const marker = ConflictMarker(
          startLine: 10,
          middleLine: 15,
          endLine: 20,
        );

        expect(marker.theirsLineCount, equals(4)); // 20 - 15 - 1
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        const marker1 = ConflictMarker(
          startLine: 10,
          middleLine: 15,
          endLine: 20,
        );

        const marker2 = ConflictMarker(
          startLine: 10,
          middleLine: 15,
          endLine: 20,
        );

        expect(marker1, equals(marker2));
      });
    });
  });

  group('ConflictedFile', () {
    group('creation', () {
      test('should create conflicted file', () {
        // Act
        const file = ConflictedFile(
          filePath: 'lib/main.dart',
          theirContent: 'their version',
          ourContent: 'our version',
          baseContent: 'base version',
          markers: [],
          isResolved: false,
        );

        // Assert
        expect(file.filePath, equals('lib/main.dart'));
        expect(file.theirContent, isNotEmpty);
        expect(file.ourContent, isNotEmpty);
        expect(file.isResolved, isFalse);
      });

      test('should create conflicted file with markers', () {
        const file = ConflictedFile(
          filePath: 'lib/main.dart',
          theirContent: 'their version',
          ourContent: 'our version',
          baseContent: 'base version',
          markers: [
            ConflictMarker(startLine: 10, middleLine: 12, endLine: 14),
          ],
          isResolved: false,
        );

        expect(file.hasConflictMarkers, isTrue);
        expect(file.conflictCount, equals(1));
      });

      test('should create resolved file', () {
        const file = ConflictedFile(
          filePath: 'lib/main.dart',
          theirContent: 'their version',
          ourContent: 'our version',
          baseContent: 'base version',
          markers: [],
          isResolved: true,
          resolvedContent: some('resolved version'),
        );

        expect(file.isResolved, isTrue);
      });
    });

    group('conflict markers', () {
      test('should detect conflict markers', () {
        const file = ConflictedFile(
          filePath: 'lib/main.dart',
          theirContent: 'their version',
          ourContent: 'our version',
          baseContent: 'base version',
          markers: [
            ConflictMarker(startLine: 5, middleLine: 7, endLine: 9),
            ConflictMarker(startLine: 20, middleLine: 22, endLine: 24),
          ],
          isResolved: false,
        );

        expect(file.hasConflictMarkers, isTrue);
        expect(file.conflictCount, equals(2));
      });

      test('should detect no conflict markers', () {
        const file = ConflictedFile(
          filePath: 'lib/main.dart',
          theirContent: 'their version',
          ourContent: 'our version',
          baseContent: 'base version',
          markers: [],
          isResolved: false,
        );

        expect(file.hasConflictMarkers, isFalse);
        expect(file.conflictCount, equals(0));
      });

      test('should detect when can auto-merge', () {
        const file = ConflictedFile(
          filePath: 'lib/main.dart',
          theirContent: 'their version',
          ourContent: 'our version',
          baseContent: 'base version',
          markers: [],
          isResolved: false,
        );

        expect(file.canAutoMerge, isTrue);
      });

      test('should detect when cannot auto-merge', () {
        const file = ConflictedFile(
          filePath: 'lib/main.dart',
          theirContent: 'their version',
          ourContent: 'our version',
          baseContent: 'base version',
          markers: [
            ConflictMarker(startLine: 10, middleLine: 12, endLine: 14),
          ],
          isResolved: false,
        );

        expect(file.canAutoMerge, isFalse);
      });
    });

    group('file name extraction', () {
      test('should extract file name from path', () {
        const file = ConflictedFile(
          filePath: 'lib/src/features/auth/login.dart',
          theirContent: 'their version',
          ourContent: 'our version',
          baseContent: 'base version',
          markers: [],
          isResolved: false,
        );

        expect(file.fileName, equals('login.dart'));
      });

      test('should handle simple file name', () {
        const file = ConflictedFile(
          filePath: 'main.dart',
          theirContent: 'their version',
          ourContent: 'our version',
          baseContent: 'base version',
          markers: [],
          isResolved: false,
        );

        expect(file.fileName, equals('main.dart'));
      });
    });

    group('content resolution', () {
      test('should return our content when not resolved', () {
        const file = ConflictedFile(
          filePath: 'lib/main.dart',
          theirContent: 'their version',
          ourContent: 'our version',
          baseContent: 'base version',
          markers: [],
          isResolved: false,
        );

        expect(file.contentToResolve, equals('our version'));
      });

      test('should return resolved content when resolved', () {
        const file = ConflictedFile(
          filePath: 'lib/main.dart',
          theirContent: 'their version',
          ourContent: 'our version',
          baseContent: 'base version',
          markers: [],
          isResolved: true,
          resolvedContent: some('final merged version'),
        );

        expect(file.contentToResolve, equals('final merged version'));
      });
    });
  });

  group('MergeConflict', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    group('creation', () {
      test('should create merge conflict', () {
        // Act
        final conflict = MergeConflict(
          sourceBranch: 'feature/authentication',
          targetBranch: 'main',
          conflictedFiles: const [],
          detectedAt: now,
        );

        // Assert
        expect(conflict.sourceBranch, equals('feature/authentication'));
        expect(conflict.targetBranch, equals('main'));
        expect(conflict.conflictedFiles, isEmpty);
      });

      test('should create merge conflict with files', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'lib/main.dart',
              theirContent: 'their version',
              ourContent: 'our version',
              baseContent: 'base version',
              markers: [],
              isResolved: false,
            ),
          ],
          detectedAt: now,
        );

        expect(conflict.totalFilesCount, equals(1));
      });
    });

    group('resolution status', () {
      test('should detect all conflicts resolved', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'file1.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: true,
            ),
            ConflictedFile(
              filePath: 'file2.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: true,
            ),
          ],
          detectedAt: now,
        );

        expect(conflict.isResolved, isTrue);
      });

      test('should detect unresolved conflicts', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'file1.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: true,
            ),
            ConflictedFile(
              filePath: 'file2.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: false,
            ),
          ],
          detectedAt: now,
        );

        expect(conflict.isResolved, isFalse);
      });

      test('should count unresolved conflicts', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'file1.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: true,
            ),
            ConflictedFile(
              filePath: 'file2.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: false,
            ),
            ConflictedFile(
              filePath: 'file3.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: false,
            ),
          ],
          detectedAt: now,
        );

        expect(conflict.unresolvedCount, equals(2));
        expect(conflict.resolvedCount, equals(1));
      });
    });

    group('conflict statistics', () {
      test('should count total files', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'file1.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: false,
            ),
            ConflictedFile(
              filePath: 'file2.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: false,
            ),
          ],
          detectedAt: now,
        );

        expect(conflict.totalFilesCount, equals(2));
      });

      test('should count total conflict markers', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'file1.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [
                ConflictMarker(startLine: 10, middleLine: 12, endLine: 14),
                ConflictMarker(startLine: 20, middleLine: 22, endLine: 24),
              ],
              isResolved: false,
            ),
            ConflictedFile(
              filePath: 'file2.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [
                ConflictMarker(startLine: 5, middleLine: 7, endLine: 9),
              ],
              isResolved: false,
            ),
          ],
          detectedAt: now,
        );

        expect(conflict.totalConflictMarkersCount, equals(3));
      });
    });

    group('resolution progress', () {
      test('should calculate progress with no files', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [],
          detectedAt: now,
        );

        expect(conflict.resolutionProgress, equals(1.0));
      });

      test('should calculate progress with partial resolution', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'file1.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: true,
            ),
            ConflictedFile(
              filePath: 'file2.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: false,
            ),
          ],
          detectedAt: now,
        );

        expect(conflict.resolutionProgress, equals(0.5));
      });

      test('should calculate 100% progress when all resolved', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'file1.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: true,
            ),
            ConflictedFile(
              filePath: 'file2.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: true,
            ),
          ],
          detectedAt: now,
        );

        expect(conflict.resolutionProgress, equals(1.0));
      });
    });

    group('recency', () {
      test('should detect recent conflict (within last hour)', () {
        final recentTime = DateTime.now().subtract(const Duration(minutes: 30));

        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [],
          detectedAt: recentTime,
        );

        expect(conflict.isRecent, isTrue);
      });

      test('should detect old conflict (beyond 1 hour)', () {
        final oldTime = DateTime.now().subtract(const Duration(hours: 2));

        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [],
          detectedAt: oldTime,
        );

        expect(conflict.isRecent, isFalse);
      });
    });

    group('summary', () {
      test('should generate summary for unresolved conflict', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/authentication',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'file1.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [
                ConflictMarker(startLine: 10, middleLine: 12, endLine: 14),
              ],
              isResolved: false,
            ),
          ],
          detectedAt: now,
        );

        final summary = conflict.summary;

        expect(summary, contains('feature/authentication'));
        expect(summary, contains('main'));
        expect(summary, contains('1 file'));
        expect(summary, contains('1 conflict'));
      });

      test('should generate summary for resolved conflict', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'develop',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'file1.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: true,
            ),
          ],
          detectedAt: now,
        );

        final summary = conflict.summary;

        expect(summary, contains('Resolved'));
      });

      test('should generate summary with partial resolution', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'file1.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: true,
            ),
            ConflictedFile(
              filePath: 'file2.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: false,
            ),
            ConflictedFile(
              filePath: 'file3.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: false,
            ),
          ],
          detectedAt: now,
        );

        final summary = conflict.summary;

        expect(summary, contains('1/3 resolved'));
      });

      test('should use plural for multiple files', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/auth',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'file1.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: false,
            ),
            ConflictedFile(
              filePath: 'file2.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: false,
            ),
          ],
          detectedAt: now,
        );

        expect(conflict.summary, contains('files'));
      });
    });

    group('use cases', () {
      test('should represent typical merge conflict', () {
        final conflict = MergeConflict(
          sourceBranch: 'feature/new-ui',
          targetBranch: 'develop',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'lib/ui/home_page.dart',
              theirContent: 'their version',
              ourContent: 'our version',
              baseContent: 'base version',
              markers: [
                ConflictMarker(startLine: 25, middleLine: 30, endLine: 35),
                ConflictMarker(startLine: 50, middleLine: 52, endLine: 54),
              ],
              isResolved: false,
            ),
          ],
          detectedAt: now,
        );

        expect(conflict.totalFilesCount, equals(1));
        expect(conflict.totalConflictMarkersCount, equals(2));
        expect(conflict.isResolved, isFalse);
        expect(conflict.resolutionProgress, equals(0.0));
      });

      test('should represent conflict in resolution', () {
        final conflict = MergeConflict(
          sourceBranch: 'hotfix/critical-bug',
          targetBranch: 'main',
          conflictedFiles: const [
            ConflictedFile(
              filePath: 'lib/core/api.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [],
              isResolved: true,
              resolvedContent: some('merged content'),
            ),
            ConflictedFile(
              filePath: 'lib/core/config.dart',
              theirContent: 'their',
              ourContent: 'our',
              baseContent: 'base',
              markers: [
                ConflictMarker(startLine: 10, middleLine: 12, endLine: 14),
              ],
              isResolved: false,
            ),
          ],
          detectedAt: now,
        );

        expect(conflict.resolutionProgress, equals(0.5));
        expect(conflict.unresolvedCount, equals(1));
        expect(conflict.resolvedCount, equals(1));
      });
    });
  });
}
