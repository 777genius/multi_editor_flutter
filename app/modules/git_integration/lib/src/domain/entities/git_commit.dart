import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import '../value_objects/commit_hash.dart';
import '../value_objects/commit_message.dart';
import '../value_objects/git_author.dart';

part 'git_commit.freezed.dart';

/// Represents a Git commit entity
@freezed
class GitCommit with _$GitCommit {
  const GitCommit._();

  const factory GitCommit({
    required CommitHash hash,
    Option<CommitHash>? parentHash,
    required GitAuthor author,
    required GitAuthor committer,
    required CommitMessage message,
    required DateTime authorDate,
    required DateTime commitDate,
    @Default([]) List<String> changedFiles,
    @Default(0) int insertions,
    @Default(0) int deletions,
    @Default([]) List<String> tags,
  }) = _GitCommit;

  /// Domain logic: Is merge commit? (has multiple parents)
  bool get isMergeCommit =>
      message.subject.toLowerCase().startsWith('merge ');

  /// Domain logic: Is initial commit?
  bool get isInitialCommit =>
      (parentHash ?? none()).isNone();

  /// Domain logic: Short hash (7 chars)
  String get shortHash => hash.short;

  /// Domain logic: Subject (first line of message)
  String get subject => message.subject;

  /// Domain logic: Body (rest of message)
  Option<String> get body => message.body;

  /// Domain logic: Total changes count
  int get totalChanges => insertions + deletions;

  /// Domain logic: Files changed count
  int get filesChanged => changedFiles.length;

  /// Domain logic: Has tags?
  bool get hasTags => tags.isNotEmpty;

  /// Domain logic: Time since commit
  Duration get age => DateTime.now().difference(authorDate);

  /// Domain logic: Is recent? (within last 24 hours)
  bool get isRecent => age.inHours < 24;

  /// Domain logic: Format age for display (e.g., "2 hours ago")
  String get ageDisplay {
    if (age.inDays > 365) {
      final years = (age.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"} ago';
    } else if (age.inDays > 30) {
      final months = (age.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else if (age.inDays > 0) {
      return '${age.inDays} ${age.inDays == 1 ? "day" : "days"} ago';
    } else if (age.inHours > 0) {
      return '${age.inHours} ${age.inHours == 1 ? "hour" : "hours"} ago';
    } else if (age.inMinutes > 0) {
      return '${age.inMinutes} ${age.inMinutes == 1 ? "minute" : "minutes"} ago';
    } else {
      return 'just now';
    }
  }

  /// Domain logic: Is same author and committer?
  bool get isSingleAuthor => author.isSamePerson(committer);

  /// Domain logic: Commit summary for display
  String get summary {
    final sb = StringBuffer();
    sb.write(shortHash);
    sb.write(' - ');
    sb.write(message.formatForDisplay(maxLength: 50));
    sb.write(' (');
    sb.write(author.name);
    sb.write(', ');
    sb.write(ageDisplay);
    sb.write(')');
    return sb.toString();
  }
}
