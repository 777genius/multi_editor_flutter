import 'package:test/test.dart';
import 'package:git_integration/src/infrastructure/adapters/git_parser_adapter.dart';
import 'package:git_integration/src/domain/value_objects/file_status.dart';

void main() {
  group('GitParserAdapter', () {
    late GitParserAdapter parser;

    setUp(() {
      parser = GitParserAdapter();
    });

    group('parseStatus', () {
      test('should parse empty status output', () {
        // Arrange
        const output = '';

        // Act
        final result = parser.parseStatus(output);

        // Assert
        expect(result.changes, isEmpty);
        expect(result.stagedChanges, isEmpty);
      });

      test('should parse branch information', () {
        // Arrange
        const output = '''
# branch.oid abc1234567890abcdef1234567890abcdef123456
# branch.head main
# branch.upstream origin/main
# branch.ab +3 -2
''';

        // Act
        final result = parser.parseStatus(output);

        // Assert
        expect(result.currentBranch, equals('main'));
        expect(result.headCommit, equals('abc1234567890abcdef1234567890abcdef123456'));
        expect(result.upstreamBranch, equals('origin/main'));
        expect(result.ahead, equals(3));
        expect(result.behind, equals(2));
      });

      test('should parse untracked file', () {
        // Arrange
        const output = '? new_file.txt';

        // Act
        final result = parser.parseStatus(output);

        // Assert
        expect(result.changes.length, equals(1));
        expect(result.changes[0].filePath, equals('new_file.txt'));
        expect(result.changes[0].status, equals(const FileStatus.untracked()));
        expect(result.changes[0].isStaged, isFalse);
      });

      test('should parse ignored file', () {
        // Arrange
        const output = '! ignored_file.txt';

        // Act
        final result = parser.parseStatus(output);

        // Assert
        expect(result.changes.length, equals(1));
        expect(result.changes[0].filePath, equals('ignored_file.txt'));
        expect(result.changes[0].status, equals(const FileStatus.ignored()));
      });

      test('should parse modified file', () {
        // Arrange
        const output = '1 .M N... 100644 100644 100644 abc123 def456 src/file.dart';

        // Act
        final result = parser.parseStatus(output);

        // Assert
        expect(result.changes.length, equals(1));
        expect(result.changes[0].filePath, equals('src/file.dart'));
        expect(result.changes[0].isStaged, isFalse);
      });

      test('should parse staged file', () {
        // Arrange
        const output = '1 M. N... 100644 100644 100644 abc123 def456 src/file.dart';

        // Act
        final result = parser.parseStatus(output);

        // Assert
        expect(result.stagedChanges.length, equals(1));
        expect(result.stagedChanges[0].filePath, equals('src/file.dart'));
        expect(result.stagedChanges[0].isStaged, isTrue);
      });

      test('should parse file with both staged and unstaged changes', () {
        // Arrange
        const output = '1 MM N... 100644 100644 100644 abc123 def456 src/file.dart';

        // Act
        final result = parser.parseStatus(output);

        // Assert
        expect(result.stagedChanges.length, equals(1));
        expect(result.changes.length, equals(1));
        expect(result.stagedChanges[0].filePath, equals('src/file.dart'));
        expect(result.changes[0].filePath, equals('src/file.dart'));
      });

      test('should parse file path with spaces', () {
        // Arrange
        const output = '1 .M N... 100644 100644 100644 abc123 def456 path with spaces/file.dart';

        // Act
        final result = parser.parseStatus(output);

        // Assert
        expect(result.changes.length, equals(1));
        expect(result.changes[0].filePath, equals('path with spaces/file.dart'));
      });

      test('should parse conflicted file', () {
        // Arrange
        const output = 'u UU N... 100644 100644 100644 100644 abc123 def456 ghi789 src/conflicted.dart';

        // Act
        final result = parser.parseStatus(output);

        // Assert
        expect(result.changes.length, equals(1));
        expect(result.changes[0].filePath, equals('src/conflicted.dart'));
        expect(result.changes[0].status, equals(const FileStatus.conflicted()));
      });

      test('should handle invalid ahead/behind format', () {
        // Arrange
        const output = '''
# branch.head main
# branch.ab invalid format
''';

        // Act
        final result = parser.parseStatus(output);

        // Assert
        expect(result.ahead, equals(0));
        expect(result.behind, equals(0));
      });

      test('should skip malformed status lines', () {
        // Arrange
        const output = '''
1 .M
invalid line
? valid_file.txt
''';

        // Act
        final result = parser.parseStatus(output);

        // Assert
        expect(result.changes.length, equals(1));
        expect(result.changes[0].filePath, equals('valid_file.txt'));
      });
    });

    group('parseLog', () {
      test('should parse empty log output', () {
        // Arrange
        const output = '';

        // Act
        final commits = parser.parseLog(output);

        // Assert
        expect(commits, isEmpty);
      });

      test('should parse single commit', () {
        // Arrange
        const output = '''
abc1234567890abcdef1234567890abcdef123456
def4567890123456789012345678901234567890
John Doe
john@example.com
1680000000
Jane Smith
jane@example.com
1680000100
Add new feature
This is the commit body
with multiple lines
---END---
''';

        // Act
        final commits = parser.parseLog(output);

        // Assert
        expect(commits.length, equals(1));
        expect(commits[0].hash.value, equals('abc1234567890abcdef1234567890abcdef123456'));
        expect(commits[0].author.name, equals('John Doe'));
        expect(commits[0].author.email, equals('john@example.com'));
        expect(commits[0].committer.name, equals('Jane Smith'));
        expect(commits[0].message.value, startsWith('Add new feature'));
      });

      test('should parse commit without parent', () {
        // Arrange
        const output = '''
abc1234567890abcdef1234567890abcdef123456
(no parent)
John Doe
john@example.com
1680000000
John Doe
john@example.com
1680000000
Initial commit

---END---
''';

        // Act
        final commits = parser.parseLog(output);

        // Assert
        expect(commits.length, equals(1));
        expect(commits[0].parentHash.isNone(), isTrue);
      });

      test('should parse multiple commits', () {
        // Arrange
        const output = '''
abc1234567890abcdef1234567890abcdef123456
def4567890123456789012345678901234567890
Author One
one@example.com
1680000000
Author One
one@example.com
1680000000
First commit

---END---
def4567890123456789012345678901234567890
ghi7890123456789012345678901234567890abc
Author Two
two@example.com
1680001000
Author Two
two@example.com
1680001000
Second commit

---END---
''';

        // Act
        final commits = parser.parseLog(output);

        // Assert
        expect(commits.length, equals(2));
        expect(commits[0].message.value, contains('First commit'));
        expect(commits[1].message.value, contains('Second commit'));
      });

      test('should skip malformed commits', () {
        // Arrange
        const output = '''
invalid
format
---END---
abc1234567890abcdef1234567890abcdef123456
def4567890123456789012345678901234567890
John Doe
john@example.com
1680000000
John Doe
john@example.com
1680000000
Valid commit

---END---
''';

        // Act
        final commits = parser.parseLog(output);

        // Assert
        expect(commits.length, equals(1));
        expect(commits[0].message.value, contains('Valid commit'));
      });

      test('should combine subject and body in message', () {
        // Arrange
        const output = '''
abc1234567890abcdef1234567890abcdef123456
def4567890123456789012345678901234567890
John Doe
john@example.com
1680000000
John Doe
john@example.com
1680000000
Subject line
Body line 1
Body line 2
---END---
''';

        // Act
        final commits = parser.parseLog(output);

        // Assert
        expect(commits.length, equals(1));
        expect(commits[0].message.value, contains('Subject line'));
        expect(commits[0].message.value, contains('Body line 1'));
        expect(commits[0].message.value, contains('Body line 2'));
      });
    });

    group('parseBlame', () {
      test('should parse empty blame output', () {
        // Arrange
        const output = '';

        // Act
        final lines = parser.parseBlame(output);

        // Assert
        expect(lines, isEmpty);
      });

      test('should parse single blame line', () {
        // Arrange
        const output = '''
abc1234567890abcdef1234567890abcdef123456 1 1 1
author John Doe
author-mail <john@example.com>
author-time 1680000000
author-tz +0000
committer John Doe
committer-mail <john@example.com>
committer-time 1680000000
committer-tz +0000
summary Initial commit
filename test.dart
\tfinal value = 42;
''';

        // Act
        final lines = parser.parseBlame(output);

        // Assert
        expect(lines.length, equals(1));
        expect(lines[0].lineNumber, equals(1));
        expect(lines[0].commit.author.name, equals('John Doe'));
        expect(lines[0].commit.message.value, equals('Initial commit'));
        expect(lines[0].content, equals('final value = 42;'));
      });

      test('should parse multiple blame lines', () {
        // Arrange
        const output = '''
abc1234567890abcdef1234567890abcdef123456 1 1 1
author John Doe
author-mail <john@example.com>
author-time 1680000000
author-tz +0000
committer John Doe
committer-mail <john@example.com>
committer-time 1680000000
committer-tz +0000
summary First commit
filename test.dart
\tline 1
def4567890123456789012345678901234567890 2 2 1
author Jane Smith
author-mail <jane@example.com>
author-time 1680001000
author-tz +0000
committer Jane Smith
committer-mail <jane@example.com>
committer-time 1680001000
committer-tz +0000
summary Second commit
filename test.dart
\tline 2
''';

        // Act
        final lines = parser.parseBlame(output);

        // Assert
        expect(lines.length, equals(2));
        expect(lines[0].commit.author.name, equals('John Doe'));
        expect(lines[1].commit.author.name, equals('Jane Smith'));
      });
    });

    group('parseBranches', () {
      test('should parse empty branches output', () {
        // Arrange
        const output = '';

        // Act
        final branches = parser.parseBranches(output);

        // Assert
        expect(branches, isEmpty);
      });

      test('should parse current branch', () {
        // Arrange
        const output = '* main abc1234567890abcdef1234567890abcdef123456 Commit message';

        // Act
        final branches = parser.parseBranches(output);

        // Assert
        expect(branches.length, equals(1));
        expect(branches[0].name.value, equals('main'));
        expect(branches[0].isCurrent, isTrue);
        expect(branches[0].isRemote, isFalse);
      });

      test('should parse local branch', () {
        // Arrange
        const output = '  feature/test abc1234567890abcdef1234567890abcdef123456 Feature commit';

        // Act
        final branches = parser.parseBranches(output);

        // Assert
        expect(branches.length, equals(1));
        expect(branches[0].name.value, equals('feature/test'));
        expect(branches[0].isCurrent, isFalse);
        expect(branches[0].isRemote, isFalse);
      });

      test('should parse remote branch', () {
        // Arrange
        const output = '  remotes/origin/main abc1234567890abcdef1234567890abcdef123456 Commit';

        // Act
        final branches = parser.parseBranches(output);

        // Assert
        expect(branches.length, equals(1));
        expect(branches[0].name.value, equals('origin/main'));
        expect(branches[0].isCurrent, isFalse);
        expect(branches[0].isRemote, isTrue);
      });

      test('should parse multiple branches', () {
        // Arrange
        const output = '''
* main abc1234567890abcdef1234567890abcdef123456 Main commit
  develop def4567890123456789012345678901234567890 Dev commit
  remotes/origin/main abc1234567890abcdef1234567890abcdef123456 Remote commit
''';

        // Act
        final branches = parser.parseBranches(output);

        // Assert
        expect(branches.length, equals(3));
        expect(branches[0].isCurrent, isTrue);
        expect(branches[1].name.value, equals('develop'));
        expect(branches[2].isRemote, isTrue);
      });

      test('should skip invalid branches', () {
        // Arrange
        const output = '''
* main abc1234567890abcdef1234567890abcdef123456 Valid

  feature def4567890123456789012345678901234567890 Also valid
''';

        // Act
        final branches = parser.parseBranches(output);

        // Assert
        expect(branches.length, equals(2));
      });
    });

    group('parseRemotes', () {
      test('should parse empty remotes output', () {
        // Arrange
        const output = '';

        // Act
        final remotes = parser.parseRemotes(output);

        // Assert
        expect(remotes, isEmpty);
      });

      test('should parse single remote', () {
        // Arrange
        const output = '''
origin\thttps://github.com/user/repo.git (fetch)
origin\thttps://github.com/user/repo.git (push)
''';

        // Act
        final remotes = parser.parseRemotes(output);

        // Assert
        expect(remotes.length, equals(1));
        expect(remotes[0].name.value, equals('origin'));
        expect(remotes[0].fetchUrl, equals('https://github.com/user/repo.git'));
        expect(remotes[0].pushUrl, equals('https://github.com/user/repo.git'));
      });

      test('should parse multiple remotes', () {
        // Arrange
        const output = '''
origin\thttps://github.com/user/repo.git (fetch)
origin\thttps://github.com/user/repo.git (push)
upstream\thttps://github.com/upstream/repo.git (fetch)
upstream\thttps://github.com/upstream/repo.git (push)
''';

        // Act
        final remotes = parser.parseRemotes(output);

        // Assert
        expect(remotes.length, equals(2));
        expect(remotes[0].name.value, equals('origin'));
        expect(remotes[1].name.value, equals('upstream'));
      });

      test('should handle different fetch and push URLs', () {
        // Arrange
        const output = '''
origin\thttps://github.com/user/repo.git (fetch)
origin\tgit@github.com:user/repo.git (push)
''';

        // Act
        final remotes = parser.parseRemotes(output);

        // Assert
        expect(remotes.length, equals(1));
        expect(remotes[0].fetchUrl, equals('https://github.com/user/repo.git'));
        expect(remotes[0].pushUrl, equals('git@github.com:user/repo.git'));
      });
    });

    group('parseStashes', () {
      test('should parse empty stash output', () {
        // Arrange
        const output = '';

        // Act
        final stashes = parser.parseStashes(output);

        // Assert
        expect(stashes, isEmpty);
      });

      test('should parse single stash', () {
        // Arrange
        const output = 'stash@{0}: WIP on main: abc1234 Commit message';

        // Act
        final stashes = parser.parseStashes(output);

        // Assert
        expect(stashes.length, equals(1));
        expect(stashes[0].index, equals(0));
        expect(stashes[0].description, equals('WIP on main: abc1234 Commit message'));
      });

      test('should parse multiple stashes', () {
        // Arrange
        const output = '''
stash@{0}: WIP on main: abc1234 Latest stash
stash@{1}: On feature: def5678 Previous stash
stash@{2}: WIP on develop: ghi9012 Old stash
''';

        // Act
        final stashes = parser.parseStashes(output);

        // Assert
        expect(stashes.length, equals(3));
        expect(stashes[0].index, equals(0));
        expect(stashes[1].index, equals(1));
        expect(stashes[2].index, equals(2));
      });

      test('should skip invalid stash lines', () {
        // Arrange
        const output = '''
stash@{0}: Valid stash
invalid line
stash@{1}: Another valid stash
''';

        // Act
        final stashes = parser.parseStashes(output);

        // Assert
        expect(stashes.length, equals(2));
      });
    });

    group('parseDiffStat', () {
      test('should parse empty diff stat', () {
        // Arrange
        const output = '';

        // Act
        final stats = parser.parseDiffStat(output);

        // Assert
        expect(stats, isEmpty);
      });

      test('should parse single file stat', () {
        // Arrange
        const output = '10\t5\tpath/to/file.dart';

        // Act
        final stats = parser.parseDiffStat(output);

        // Assert
        expect(stats.length, equals(1));
        expect(stats['path/to/file.dart']?.additions, equals(10));
        expect(stats['path/to/file.dart']?.deletions, equals(5));
        expect(stats['path/to/file.dart']?.total, equals(15));
      });

      test('should parse multiple file stats', () {
        // Arrange
        const output = '''
10\t5\tfile1.dart
3\t0\tfile2.dart
0\t8\tfile3.dart
''';

        // Act
        final stats = parser.parseDiffStat(output);

        // Assert
        expect(stats.length, equals(3));
        expect(stats['file1.dart']?.additions, equals(10));
        expect(stats['file2.dart']?.additions, equals(3));
        expect(stats['file3.dart']?.deletions, equals(8));
      });

      test('should parse file path with spaces', () {
        // Arrange
        const output = '5\t3\tpath with spaces/file.dart';

        // Act
        final stats = parser.parseDiffStat(output);

        // Assert
        expect(stats.containsKey('path with spaces/file.dart'), isTrue);
        expect(stats['path with spaces/file.dart']?.additions, equals(5));
      });

      test('should handle invalid stat lines', () {
        // Arrange
        const output = '''
10\t5\tvalid.dart
invalid
3\t2\talso_valid.dart
''';

        // Act
        final stats = parser.parseDiffStat(output);

        // Assert
        expect(stats.length, equals(2));
        expect(stats.containsKey('valid.dart'), isTrue);
        expect(stats.containsKey('also_valid.dart'), isTrue);
      });

      test('should handle binary files', () {
        // Arrange
        const output = '-\t-\tbinary_file.png';

        // Act
        final stats = parser.parseDiffStat(output);

        // Assert
        expect(stats.length, equals(1));
        expect(stats['binary_file.png']?.additions, equals(0));
        expect(stats['binary_file.png']?.deletions, equals(0));
      });
    });
  });

  group('DiffStat', () {
    test('should calculate total correctly', () {
      // Arrange
      final stat = DiffStat(additions: 10, deletions: 5);

      // Act & Assert
      expect(stat.total, equals(15));
    });

    test('should handle zero additions and deletions', () {
      // Arrange
      final stat = DiffStat(additions: 0, deletions: 0);

      // Act & Assert
      expect(stat.total, equals(0));
    });
  });
}
