import 'package:freezed_annotation/freezed_annotation.dart';

part 'git_author.freezed.dart';

/// Git author value object with validation
@freezed
class GitAuthor with _$GitAuthor {
  const GitAuthor._();

  const factory GitAuthor({
    required String name,
    required String email,
  }) = _GitAuthor;

  /// Factory with validation
  factory GitAuthor.create({
    required String name,
    required String email,
  }) {
    if (name.trim().isEmpty) {
      throw GitAuthorValidationException('Author name cannot be empty');
    }

    if (email.trim().isEmpty) {
      throw GitAuthorValidationException('Author email cannot be empty');
    }

    // Basic email validation
    if (!email.contains('@') || !email.contains('.')) {
      throw GitAuthorValidationException(
        'Invalid email format: $email',
      );
    }

    return GitAuthor(
      name: name.trim(),
      email: email.trim(),
    );
  }

  /// Parse from git format: "Name <email@example.com>"
  factory GitAuthor.parse(String gitFormat) {
    final match = RegExp(r'^(.+?)\s*<(.+?)>$').firstMatch(gitFormat);

    if (match == null) {
      throw GitAuthorValidationException(
        'Invalid git author format: $gitFormat',
      );
    }

    return GitAuthor.create(
      name: match.group(1)!.trim(),
      email: match.group(2)!.trim(),
    );
  }

  /// Domain logic: Format for git (Name <email>)
  String toGitFormat() => '$name <$email>';

  /// Domain logic: Format for display
  String get display => toGitFormat();

  /// Domain logic: Get initials (for avatar)
  String get initials {
    final parts = name.split(' ');
    if (parts.isEmpty) return '';

    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    return parts[0].substring(0, 1).toUpperCase() +
        parts[1].substring(0, 1).toUpperCase();
  }

  /// Domain logic: Get email domain
  String get emailDomain {
    final parts = email.split('@');
    return parts.length > 1 ? parts[1] : '';
  }

  /// Domain logic: Is same person? (case-insensitive email comparison)
  bool isSamePerson(GitAuthor other) {
    return email.toLowerCase() == other.email.toLowerCase();
  }
}

/// Exception for git author validation
class GitAuthorValidationException implements Exception {
  final String message;
  GitAuthorValidationException(this.message);

  @override
  String toString() => 'GitAuthorValidationException: $message';
}
