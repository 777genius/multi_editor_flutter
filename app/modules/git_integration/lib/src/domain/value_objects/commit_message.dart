import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';

part 'commit_message.freezed.dart';

/// Commit message value object with validation
@freezed
class CommitMessage with _$CommitMessage {
  const CommitMessage._();

  const factory CommitMessage({
    required String value,
  }) = _CommitMessage;

  /// Factory with validation
  factory CommitMessage.create(String value) {
    if (value.trim().isEmpty) {
      throw CommitMessageValidationException(
        'Commit message cannot be empty',
      );
    }

    // Trim and normalize line endings
    final normalized = value.trim().replaceAll('\r\n', '\n');

    return CommitMessage(value: normalized);
  }

  /// Domain logic: Get subject (first line)
  String get subject {
    final lines = value.split('\n');
    return lines.first.trim();
  }

  /// Domain logic: Get body (rest of lines after first blank line)
  Option<String> get body {
    final lines = value.split('\n');

    // Find first blank line
    var bodyStartIndex = -1;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) {
        bodyStartIndex = i + 1;
        break;
      }
    }

    if (bodyStartIndex == -1 || bodyStartIndex >= lines.length) {
      return none();
    }

    final bodyText = lines.skip(bodyStartIndex).join('\n').trim();
    return bodyText.isEmpty ? none() : some(bodyText);
  }

  /// Domain logic: Is conventional commit?
  /// Format: type(scope): description
  /// Example: feat(auth): add login functionality
  bool get isConventional {
    final pattern = RegExp(
      r'^(feat|fix|docs|style|refactor|perf|test|chore|build|ci|revert)(\(.+\))?: .+',
    );
    return pattern.hasMatch(subject);
  }

  /// Domain logic: Get conventional commit type
  Option<String> get conventionalType {
    if (!isConventional) return none();

    final match = RegExp(r'^(\w+)').firstMatch(subject);
    return match != null ? some(match.group(1)!) : none();
  }

  /// Domain logic: Get conventional commit scope
  Option<String> get conventionalScope {
    if (!isConventional) return none();

    final match = RegExp(r'\((.+?)\)').firstMatch(subject);
    return match != null ? some(match.group(1)!) : none();
  }

  /// Domain logic: Get subject length
  int get subjectLength => subject.length;

  /// Domain logic: Is subject too long? (>72 chars is not recommended)
  bool get isSubjectTooLong => subjectLength > 72;

  /// Domain logic: Has body?
  bool get hasBody => body.isSome();

  /// Domain logic: Format for display (truncate long subjects)
  String formatForDisplay({int maxLength = 72}) {
    if (subject.length <= maxLength) {
      return subject;
    }

    return '${subject.substring(0, maxLength - 3)}...';
  }
}

/// Exception for commit message validation
class CommitMessageValidationException implements Exception {
  final String message;
  CommitMessageValidationException(this.message);

  @override
  String toString() => 'CommitMessageValidationException: $message';
}
