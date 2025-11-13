import 'package:freezed_annotation/freezed_annotation.dart';
import '../value_objects/commit_hash.dart';
import '../value_objects/git_author.dart';

part 'blame_line.freezed.dart';

/// Represents a line with blame information
@freezed
class BlameLine with _$BlameLine {
  const BlameLine._();

  const factory BlameLine({
    required int lineNumber,
    required String content,
    required CommitHash commitHash,
    required GitAuthor author,
    required DateTime timestamp,
    required String commitMessage,
  }) = _BlameLine;

  /// Domain logic: Short commit hash
  String get shortHash => commitHash.short;

  /// Domain logic: Time since this line was last modified
  Duration get age => DateTime.now().difference(timestamp);

  /// Domain logic: Is recent? (within last 7 days)
  bool get isRecent => age.inDays < 7;

  /// Domain logic: Is old? (more than 1 year)
  bool get isOld => age.inDays > 365;

  /// Domain logic: Relative time (e.g., "2 hours ago")
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

  /// Domain logic: Format for display (compact)
  String formatCompact() {
    return '$shortHash ${author.name} ($relativeTime)';
  }

  /// Domain logic: Format for display (full)
  String formatFull() {
    final sb = StringBuffer();
    sb.write(shortHash);
    sb.write(' (');
    sb.write(author.display);
    sb.write(', ');
    sb.write(timestamp.toString().substring(0, 19)); // YYYY-MM-DD HH:MM:SS
    sb.write(') ');
    sb.write(commitMessage.split('\n').first); // First line only
    return sb.toString();
  }

  /// Domain logic: Get color intensity based on age (0.0 - 1.0)
  /// Recent changes are more intense
  double get colorIntensity {
    if (age.inDays == 0) return 1.0;
    if (age.inDays < 7) return 0.9;
    if (age.inDays < 30) return 0.7;
    if (age.inDays < 90) return 0.5;
    if (age.inDays < 365) return 0.3;
    return 0.1;
  }
}
