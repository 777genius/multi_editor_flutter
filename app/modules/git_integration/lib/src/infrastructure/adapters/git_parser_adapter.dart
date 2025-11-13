import 'package:fpdart/fpdart.dart' as fp;
import '../../domain/entities/git_commit.dart';
import '../../domain/entities/git_branch.dart';
import '../../domain/entities/git_remote.dart';
import '../../domain/entities/file_change.dart';
import '../../domain/entities/blame_line.dart';
import '../../domain/entities/git_stash.dart';
import '../../domain/value_objects/commit_hash.dart';
import '../../domain/value_objects/commit_message.dart';
import '../../domain/value_objects/git_author.dart';
import '../../domain/value_objects/branch_name.dart';
import '../../domain/value_objects/remote_name.dart';
import '../../domain/value_objects/file_status.dart';

/// Adapter for parsing git command output into domain entities
///
/// This provides parsers for various git output formats:
/// - git status --porcelain=v2
/// - git log
/// - git blame --porcelain
/// - git branch
/// - git remote
class GitParserAdapter {
  // ============================================================================
  // Status Parsing
  // ============================================================================

  /// Parse git status --porcelain=v2 output
  ///
  /// Format:
  /// ```
  /// # branch.oid <commit>
  /// # branch.head <branch>
  /// # branch.upstream <upstream>
  /// # branch.ab +<ahead> -<behind>
  /// 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
  /// 2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <X><score> <path><sep><origPath>
  /// u <XY> <sub> <m1> <m2> <m3> <mW> <h1> <h2> <h3> <path>
  /// ? <path>
  /// ! <path>
  /// ```
  ParsedStatus parseStatus(String output) {
    final lines = output.split('\n');
    String? currentBranch;
    String? headCommit;
    String? upstreamBranch;
    int ahead = 0;
    int behind = 0;
    final changes = <FileChange>[];
    final stagedChanges = <FileChange>[];

    for (final line in lines) {
      if (line.isEmpty) continue;

      if (line.startsWith('# branch.head ')) {
        currentBranch = line.substring(14);
      } else if (line.startsWith('# branch.oid ')) {
        headCommit = line.substring(13);
      } else if (line.startsWith('# branch.upstream ')) {
        upstreamBranch = line.substring(18);
      } else if (line.startsWith('# branch.ab ')) {
        final parts = line.substring(12).split(' ');
        ahead = int.parse(parts[0].substring(1)); // Remove '+'
        behind = int.parse(parts[1].substring(1)); // Remove '-'
      } else if (line.startsWith('1 ') || line.startsWith('2 ')) {
        // Regular file change
        final parts = line.split(' ');
        final xy = parts[1];
        final path = parts.length > 8 ? parts[8] : '';

        // Parse status codes
        final stagedStatus = xy[0];
        final unstagedStatus = xy[1];

        // Create file change for staged
        if (stagedStatus != '.') {
          final status = FileStatus.fromGitStatusCode(stagedStatus);
          stagedChanges.add(FileChange(
            filePath: path,
            status: status,
            isStaged: true,
          ));
        }

        // Create file change for unstaged
        if (unstagedStatus != '.') {
          final status = FileStatus.fromGitStatusCode(unstagedStatus);
          changes.add(FileChange(
            filePath: path,
            status: status,
            isStaged: false,
          ));
        }
      } else if (line.startsWith('? ')) {
        // Untracked file
        final path = line.substring(2);
        changes.add(FileChange(
          filePath: path,
          status: const FileStatus.untracked(),
          isStaged: false,
        ));
      } else if (line.startsWith('! ')) {
        // Ignored file
        final path = line.substring(2);
        changes.add(FileChange(
          filePath: path,
          status: const FileStatus.ignored(),
          isStaged: false,
        ));
      } else if (line.startsWith('u ')) {
        // Unmerged file (conflict)
        final parts = line.split(' ');
        final path = parts.length > 10 ? parts[10] : '';
        changes.add(FileChange(
          filePath: path,
          status: const FileStatus.conflicted(),
          isStaged: false,
        ));
      }
    }

    return ParsedStatus(
      currentBranch: currentBranch,
      headCommit: headCommit,
      upstreamBranch: upstreamBranch,
      ahead: ahead,
      behind: behind,
      changes: changes,
      stagedChanges: stagedChanges,
    );
  }

  // ============================================================================
  // Log Parsing
  // ============================================================================

  /// Parse git log output
  ///
  /// Format (from --pretty):
  /// ```
  /// <hash>
  /// <parent>
  /// <author_name>
  /// <author_email>
  /// <author_timestamp>
  /// <committer_name>
  /// <committer_email>
  /// <committer_timestamp>
  /// <subject>
  /// <body>
  /// ---END---
  /// ```
  List<GitCommit> parseLog(String output) {
    if (output.isEmpty) return [];

    final commits = <GitCommit>[];
    final commitBlocks = output.split('---END---');

    for (final block in commitBlocks) {
      if (block.trim().isEmpty) continue;

      final lines = block.trim().split('\n');
      if (lines.length < 9) continue; // Need at least 9 lines

      try {
        final hash = CommitHash.create(lines[0].trim());
        final parentStr = lines[1].trim();
        final parentHash = parentStr.isNotEmpty && parentStr != '(no parent)'
            ? fp.some(CommitHash.create(parentStr.split(' ').first))
            : fp.none<CommitHash>();

        final authorName = lines[2].trim();
        final authorEmail = lines[3].trim();
        final authorTimestamp = int.parse(lines[4].trim());
        final authorDate =
            DateTime.fromMillisecondsSinceEpoch(authorTimestamp * 1000);

        final committerName = lines[5].trim();
        final committerEmail = lines[6].trim();
        final committerTimestamp = int.parse(lines[7].trim());
        final commitDate =
            DateTime.fromMillisecondsSinceEpoch(committerTimestamp * 1000);

        final subject = lines[8].trim();
        final body = lines.length > 9 ? lines.sublist(9).join('\n').trim() : '';
        final messageText = body.isEmpty ? subject : '$subject\n\n$body';

        commits.add(GitCommit(
          hash: hash,
          parentHash: parentHash,
          author: GitAuthor.create(
            name: authorName,
            email: authorEmail,
          ),
          committer: GitAuthor.create(
            name: committerName,
            email: committerEmail,
          ),
          message: CommitMessage.create(messageText),
          authorDate: authorDate,
          commitDate: commitDate,
        ));
      } catch (e) {
        // Skip malformed commit
        continue;
      }
    }

    return commits;
  }

  // ============================================================================
  // Blame Parsing
  // ============================================================================

  /// Parse git blame --porcelain output
  ///
  /// Format:
  /// ```
  /// <hash> <original-line> <final-line> <num-lines>
  /// author <author>
  /// author-mail <email>
  /// author-time <timestamp>
  /// author-tz <timezone>
  /// committer <committer>
  /// committer-mail <email>
  /// committer-time <timestamp>
  /// committer-tz <timezone>
  /// summary <message>
  /// filename <file>
  /// \t<line-content>
  /// ```
  List<BlameLine> parseBlame(String output) {
    if (output.isEmpty) return [];

    final lines = output.split('\n');
    final blameLines = <BlameLine>[];
    GitCommit? currentCommit;
    int currentLineNumber = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.isEmpty) continue;

      // Commit header line
      if (RegExp(r'^[a-f0-9]{40} \d+ \d+ \d+').hasMatch(line)) {
        final parts = line.split(' ');
        final hash = parts[0];
        final lineNumber = int.parse(parts[2]);
        currentLineNumber = lineNumber;

        // Parse commit details from following lines
        String? authorName;
        String? authorEmail;
        int? authorTimestamp;
        String? committerName;
        String? committerEmail;
        int? committerTimestamp;
        String? summary;

        // Read commit details
        while (i + 1 < lines.length && !lines[i + 1].startsWith('\t')) {
          i++;
          final detailLine = lines[i];

          if (detailLine.startsWith('author ')) {
            authorName = detailLine.substring(7);
          } else if (detailLine.startsWith('author-mail ')) {
            authorEmail = detailLine.substring(12).replaceAll(RegExp(r'[<>]'), '');
          } else if (detailLine.startsWith('author-time ')) {
            authorTimestamp = int.parse(detailLine.substring(12));
          } else if (detailLine.startsWith('committer ')) {
            committerName = detailLine.substring(10);
          } else if (detailLine.startsWith('committer-mail ')) {
            committerEmail =
                detailLine.substring(15).replaceAll(RegExp(r'[<>]'), '');
          } else if (detailLine.startsWith('committer-time ')) {
            committerTimestamp = int.parse(detailLine.substring(15));
          } else if (detailLine.startsWith('summary ')) {
            summary = detailLine.substring(8);
          }
        }

        // Create commit object
        if (authorName != null &&
            authorEmail != null &&
            authorTimestamp != null &&
            committerName != null &&
            committerEmail != null &&
            committerTimestamp != null &&
            summary != null) {
          currentCommit = GitCommit(
            hash: CommitHash.create(hash),
            parentHash: fp.none(),
            author: GitAuthor.create(
              name: authorName,
              email: authorEmail,
            ),
            committer: GitAuthor.create(
              name: committerName,
              email: committerEmail,
            ),
            message: CommitMessage.create(summary),
            authorDate:
                DateTime.fromMillisecondsSinceEpoch(authorTimestamp * 1000),
            commitDate:
                DateTime.fromMillisecondsSinceEpoch(committerTimestamp * 1000),
          );
        }

        // Read line content
        if (i + 1 < lines.length && lines[i + 1].startsWith('\t')) {
          i++;
          final content = lines[i].substring(1); // Remove tab

          if (currentCommit != null) {
            blameLines.add(BlameLine(
              lineNumber: currentLineNumber,
              commit: currentCommit,
              content: content,
            ));
          }
        }
      }
    }

    return blameLines;
  }

  // ============================================================================
  // Branch Parsing
  // ============================================================================

  /// Parse git branch -a -v --no-abbrev output
  ///
  /// Format:
  /// ```
  /// * master                abc1234 Commit message
  ///   feature/branch        def5678 Another commit
  ///   remotes/origin/master abc1234 Commit message
  /// ```
  List<GitBranch> parseBranches(String output) {
    if (output.isEmpty) return [];

    final lines = output.split('\n');
    final branches = <GitBranch>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final isCurrent = line.startsWith('*');
      final cleanLine = line.substring(2).trim(); // Remove '* ' or '  '
      final parts = cleanLine.split(RegExp(r'\s+'));

      if (parts.isEmpty) continue;

      final name = parts[0];
      final isRemote = name.startsWith('remotes/');
      final branchName = isRemote ? name.substring(8) : name; // Remove 'remotes/'

      // Parse commit hash if available
      final commitHash = parts.length > 1 ? parts[1] : null;

      try {
        branches.add(GitBranch(
          name: BranchName.create(branchName),
          isCurrent: isCurrent && !isRemote,
          isRemote: isRemote,
          headCommit: commitHash != null && commitHash.length == 40
              ? fp.some(CommitHash.create(commitHash))
              : fp.none(),
        ));
      } catch (e) {
        // Skip invalid branch
        continue;
      }
    }

    return branches;
  }

  // ============================================================================
  // Remote Parsing
  // ============================================================================

  /// Parse git remote -v output
  ///
  /// Format:
  /// ```
  /// origin  https://github.com/user/repo.git (fetch)
  /// origin  https://github.com/user/repo.git (push)
  /// upstream        https://github.com/upstream/repo.git (fetch)
  /// upstream        https://github.com/upstream/repo.git (push)
  /// ```
  List<GitRemote> parseRemotes(String output) {
    if (output.isEmpty) return [];

    final lines = output.split('\n');
    final remoteMap = <String, Map<String, String>>{};

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 3) continue;

      final name = parts[0];
      final url = parts[1];
      final type = parts[2].replaceAll(RegExp(r'[()]'), ''); // Remove parens

      if (!remoteMap.containsKey(name)) {
        remoteMap[name] = {};
      }

      remoteMap[name]![type] = url;
    }

    // Convert map to list of GitRemote
    final remotes = <GitRemote>[];
    for (final entry in remoteMap.entries) {
      final name = entry.key;
      final urls = entry.value;

      try {
        remotes.add(GitRemote(
          name: RemoteName.create(name),
          fetchUrl: urls['fetch'] ?? '',
          pushUrl: urls['push'] ?? urls['fetch'] ?? '',
        ));
      } catch (e) {
        // Skip invalid remote
        continue;
      }
    }

    return remotes;
  }

  // ============================================================================
  // Stash Parsing
  // ============================================================================

  /// Parse git stash list output
  ///
  /// Format:
  /// ```
  /// stash@{0}: WIP on master: abc1234 Commit message
  /// stash@{1}: On feature: Some message
  /// ```
  List<GitStash> parseStashes(String output) {
    if (output.isEmpty) return [];

    final lines = output.split('\n');
    final stashes = <GitStash>[];

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final match = RegExp(r'stash@\{(\d+)\}: (.+)').firstMatch(line);
      if (match == null) continue;

      final index = int.parse(match.group(1)!);
      final description = match.group(2)!;

      stashes.add(GitStash(
        index: index,
        description: description,
        createdAt: DateTime.now(), // TODO: Get actual timestamp
      ));
    }

    return stashes;
  }

  // ============================================================================
  // Diff Stat Parsing
  // ============================================================================

  /// Parse git diff --numstat output
  ///
  /// Format:
  /// ```
  /// 10      5       path/to/file.txt
  /// 3       0       path/to/another.txt
  /// ```
  Map<String, DiffStat> parseDiffStat(String output) {
    if (output.isEmpty) return {};

    final lines = output.split('\n');
    final stats = <String, DiffStat>{};

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 3) continue;

      final additions = int.tryParse(parts[0]) ?? 0;
      final deletions = int.tryParse(parts[1]) ?? 0;
      final path = parts.sublist(2).join(' ');

      stats[path] = DiffStat(
        additions: additions,
        deletions: deletions,
      );
    }

    return stats;
  }
}

// ============================================================================
// Helper Classes
// ============================================================================

/// Parsed status result
class ParsedStatus {
  final String? currentBranch;
  final String? headCommit;
  final String? upstreamBranch;
  final int ahead;
  final int behind;
  final List<FileChange> changes;
  final List<FileChange> stagedChanges;

  ParsedStatus({
    this.currentBranch,
    this.headCommit,
    this.upstreamBranch,
    this.ahead = 0,
    this.behind = 0,
    required this.changes,
    required this.stagedChanges,
  });
}

/// Diff statistics for a file
class DiffStat {
  final int additions;
  final int deletions;

  DiffStat({
    required this.additions,
    required this.deletions,
  });

  int get total => additions + deletions;
}
