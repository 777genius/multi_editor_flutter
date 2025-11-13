import 'package:freezed_annotation/freezed_annotation.dart';
import '../value_objects/commit_hash.dart';
import '../value_objects/branch_name.dart';

part 'git_stash.freezed.dart';

/// Represents a stash entry entity
@freezed
class GitStash with _$GitStash {
  const GitStash._();

  const factory GitStash({
    required int index,
    required CommitHash hash,
    required String description,
    required BranchName branch,
    required DateTime timestamp,
    @Default([]) List<String> changedFiles,
  }) = _GitStash;

  /// Domain logic: Stash reference (e.g., "stash@{0}")
  String get reference => 'stash@{$index}';

  /// Domain logic: Short hash
  String get shortHash => hash.short;

  /// Domain logic: Time since stash was created
  Duration get age => DateTime.now().difference(timestamp);

  /// Domain logic: Is recent? (within last 24 hours)
  bool get isRecent => age.inHours < 24;

  /// Domain logic: Relative time
  String get relativeTime {
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

  /// Domain logic: Has files?
  bool get hasFiles => changedFiles.isNotEmpty;

  /// Domain logic: Files count
  int get filesCount => changedFiles.length;

  /// Domain logic: Display name
  String get displayName {
    final sb = StringBuffer();
    sb.write('stash@{$index}: ');

    if (description.startsWith('WIP on ')) {
      // Extract branch name from "WIP on <branch>: <message>"
      sb.write(description);
    } else if (description.startsWith('On ')) {
      // Extract from "On <branch>: <message>"
      sb.write(description);
    } else {
      sb.write(description);
    }

    return sb.toString();
  }

  /// Domain logic: Summary for display
  String get summary {
    final sb = StringBuffer();
    sb.write(reference);
    sb.write(' (');
    sb.write(branch.value);
    sb.write(', ');
    sb.write(relativeTime);
    sb.write('): ');
    sb.write(description.length > 50
        ? '${description.substring(0, 47)}...'
        : description);
    return sb.toString();
  }
}
