import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('FileChange', () {
    group('creation', () {
      test('should create file change with basic information', () {
        // Act
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
        );

        // Assert
        expect(change.filePath, equals('lib/main.dart'));
        expect(change.insertions, equals(0));
        expect(change.deletions, equals(0));
        expect(change.isStaged, isFalse);
      });

      test('should create file change with line counts', () {
        final change = FileChange(
          filePath: 'lib/feature.dart',
          status: const FileStatus.modified(),
          insertions: 25,
          deletions: 10,
        );

        expect(change.insertions, equals(25));
        expect(change.deletions, equals(10));
      });

      test('should create staged file change', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          isStaged: true,
        );

        expect(change.isStaged, isTrue);
      });

      test('should create renamed file change', () {
        final change = FileChange(
          filePath: 'lib/new_name.dart',
          status: const FileStatus.renamed(),
          oldPath: some('lib/old_name.dart'),
        );

        expect(change.isRenamed, isTrue);
      });
    });

    group('status detection - new files', () {
      test('should detect added file', () {
        final change = FileChange(
          filePath: 'lib/new_file.dart',
          status: const FileStatus.added(),
        );

        expect(change.isNew, isTrue);
        expect(change.isModified, isFalse);
        expect(change.isDeleted, isFalse);
      });

      test('should detect untracked file', () {
        final change = FileChange(
          filePath: 'lib/untracked.dart',
          status: const FileStatus.untracked(),
        );

        expect(change.isNew, isTrue);
        expect(change.isTracked, isFalse);
      });
    });

    group('status detection - modified files', () {
      test('should detect modified file', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
        );

        expect(change.isModified, isTrue);
        expect(change.isNew, isFalse);
        expect(change.isDeleted, isFalse);
      });
    });

    group('status detection - deleted files', () {
      test('should detect deleted file', () {
        final change = FileChange(
          filePath: 'lib/old_file.dart',
          status: const FileStatus.deleted(),
        );

        expect(change.isDeleted, isTrue);
        expect(change.isNew, isFalse);
        expect(change.isModified, isFalse);
      });
    });

    group('status detection - renamed files', () {
      test('should detect renamed file', () {
        final change = FileChange(
          filePath: 'lib/new_name.dart',
          status: const FileStatus.renamed(),
          oldPath: some('lib/old_name.dart'),
        );

        expect(change.isRenamed, isTrue);
        expect(change.isNew, isFalse);
      });

      test('should not detect renamed without old path', () {
        final change = FileChange(
          filePath: 'lib/file.dart',
          status: const FileStatus.renamed(),
        );

        // Without oldPath, isRenamed should be false
        expect(change.isRenamed, isFalse);
      });
    });

    group('status detection - conflicted files', () {
      test('should detect conflicted file', () {
        final change = FileChange(
          filePath: 'lib/conflicted.dart',
          status: const FileStatus.conflicted(),
        );

        expect(change.hasConflict, isTrue);
      });
    });

    group('staging operations', () {
      test('should detect when can be staged', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          isStaged: false,
        );

        expect(change.canBeStaged, isTrue);
        expect(change.canBeUnstaged, isFalse);
      });

      test('should detect when can be unstaged', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          isStaged: true,
        );

        expect(change.canBeUnstaged, isTrue);
        expect(change.canBeStaged, isFalse);
      });

      test('should not stage already staged file', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          isStaged: true,
        );

        expect(change.canBeStaged, isFalse);
      });
    });

    group('change statistics', () {
      test('should calculate total changes', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 50,
          deletions: 30,
        );

        expect(change.totalChanges, equals(80));
      });

      test('should detect when has line changes', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 10,
          deletions: 5,
        );

        expect(change.hasLineChanges, isTrue);
      });

      test('should detect when has no line changes', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
        );

        expect(change.hasLineChanges, isFalse);
      });
    });

    group('change ratio', () {
      test('should calculate positive ratio for more additions', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 80,
          deletions: 20,
        );

        expect(change.changeRatio, equals(0.6));
      });

      test('should calculate negative ratio for more deletions', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 20,
          deletions: 80,
        );

        expect(change.changeRatio, equals(-0.6));
      });

      test('should calculate zero ratio for no changes', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
        );

        expect(change.changeRatio, equals(0.0));
      });

      test('should calculate zero ratio for equal changes', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 50,
          deletions: 50,
        );

        expect(change.changeRatio, equals(0.0));
      });
    });

    group('change ratio categorization', () {
      test('should detect mostly additions', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 90,
          deletions: 10,
        );

        expect(change.isMostlyAdditions, isTrue);
        expect(change.isMostlyDeletions, isFalse);
      });

      test('should detect mostly deletions', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 10,
          deletions: 90,
        );

        expect(change.isMostlyDeletions, isTrue);
        expect(change.isMostlyAdditions, isFalse);
      });

      test('should not categorize balanced changes', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 50,
          deletions: 50,
        );

        expect(change.isMostlyAdditions, isFalse);
        expect(change.isMostlyDeletions, isFalse);
      });
    });

    group('file path parsing', () {
      test('should extract file name from path', () {
        final change = FileChange(
          filePath: 'lib/src/features/auth/login.dart',
          status: const FileStatus.modified(),
        );

        expect(change.fileName, equals('login.dart'));
      });

      test('should extract file name from simple path', () {
        final change = FileChange(
          filePath: 'main.dart',
          status: const FileStatus.modified(),
        );

        expect(change.fileName, equals('main.dart'));
      });

      test('should extract directory from path', () {
        final change = FileChange(
          filePath: 'lib/src/features/auth/login.dart',
          status: const FileStatus.modified(),
        );

        expect(change.directory, equals('lib/src/features/auth'));
      });

      test('should return empty directory for simple file', () {
        final change = FileChange(
          filePath: 'main.dart',
          status: const FileStatus.modified(),
        );

        expect(change.directory, isEmpty);
      });

      test('should extract file extension', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
        );

        expect(change.extension, equals('dart'));
      });

      test('should handle file without extension', () {
        final change = FileChange(
          filePath: 'lib/README',
          status: const FileStatus.modified(),
        );

        expect(change.extension, isEmpty);
      });
    });

    group('display path', () {
      test('should show normal path for non-renamed files', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
        );

        expect(change.displayPath, equals('lib/main.dart'));
      });

      test('should show rename arrow for renamed files', () {
        final change = FileChange(
          filePath: 'lib/new_name.dart',
          status: const FileStatus.renamed(),
          oldPath: some('lib/old_name.dart'),
        );

        expect(change.displayPath, equals('lib/old_name.dart → lib/new_name.dart'));
      });

      test('should show normal path if renamed but no old path', () {
        final change = FileChange(
          filePath: 'lib/file.dart',
          status: const FileStatus.renamed(),
        );

        expect(change.displayPath, equals('lib/file.dart'));
      });
    });

    group('summary', () {
      test('should generate summary with changes', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 25,
          deletions: 10,
        );

        final summary = change.summary;

        expect(summary, contains('lib/main.dart'));
        expect(summary, contains('+25'));
        expect(summary, contains('-10'));
      });

      test('should generate summary without line counts for no changes', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
        );

        final summary = change.summary;

        expect(summary, contains('lib/main.dart'));
        expect(summary, isNot(contains('+')));
      });

      test('should show status icon in summary', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
        );

        expect(change.summary, isNotEmpty);
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        final change1 = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 10,
          deletions: 5,
        );

        final change2 = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 10,
          deletions: 5,
        );

        expect(change1, equals(change2));
      });

      test('should not be equal with different paths', () {
        final change1 = FileChange(
          filePath: 'lib/file1.dart',
          status: const FileStatus.modified(),
        );

        final change2 = FileChange(
          filePath: 'lib/file2.dart',
          status: const FileStatus.modified(),
        );

        expect(change1, isNot(equals(change2)));
      });
    });

    group('copyWith', () {
      test('should copy with staging status changed', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          isStaged: false,
        );

        final staged = change.copyWith(isStaged: true);

        expect(staged.isStaged, isTrue);
        expect(change.isStaged, isFalse);
      });

      test('should copy with updated line counts', () {
        final change = FileChange(
          filePath: 'lib/main.dart',
          status: const FileStatus.modified(),
          insertions: 10,
          deletions: 5,
        );

        final updated = change.copyWith(
          insertions: 20,
          deletions: 10,
        );

        expect(updated.insertions, equals(20));
        expect(updated.deletions, equals(10));
        expect(change.insertions, equals(10));
      });
    });

    group('use cases', () {
      test('should represent new file addition', () {
        final change = FileChange(
          filePath: 'lib/features/auth/login_page.dart',
          status: const FileStatus.added(),
          insertions: 150,
          deletions: 0,
          isStaged: true,
        );

        expect(change.isNew, isTrue);
        expect(change.isMostlyAdditions, isTrue);
        expect(change.isStaged, isTrue);
        expect(change.fileName, equals('login_page.dart'));
      });

      test('should represent file refactoring', () {
        final change = FileChange(
          filePath: 'lib/core/utils.dart',
          status: const FileStatus.modified(),
          insertions: 45,
          deletions: 60,
          isStaged: false,
        );

        expect(change.isModified, isTrue);
        expect(change.isMostlyDeletions, isTrue);
        expect(change.canBeStaged, isTrue);
      });

      test('should represent file rename', () {
        final change = FileChange(
          filePath: 'lib/widgets/custom_button.dart',
          status: const FileStatus.renamed(),
          oldPath: some('lib/widgets/button.dart'),
          isStaged: true,
        );

        expect(change.isRenamed, isTrue);
        expect(change.displayPath, contains('→'));
      });

      test('should represent file deletion', () {
        final change = FileChange(
          filePath: 'lib/deprecated/old_api.dart',
          status: const FileStatus.deleted(),
          insertions: 0,
          deletions: 200,
        );

        expect(change.isDeleted, isTrue);
        expect(change.deletions, equals(200));
      });

      test('should represent merge conflict', () {
        final change = FileChange(
          filePath: 'lib/config/app_config.dart',
          status: const FileStatus.conflicted(),
          isStaged: false,
        );

        expect(change.hasConflict, isTrue);
        expect(change.canBeStaged, isFalse);
      });
    });
  });
}
