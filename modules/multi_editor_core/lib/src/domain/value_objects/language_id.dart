import '../failures/domain_failure.dart';
import 'file_name.dart';

class LanguageId {
  final String value;

  static const Set<String> supportedLanguages = {
    'dart',
    'javascript',
    'typescript',
    'python',
    'rust',
    'go',
    'java',
    'kotlin',
    'swift',
    'c',
    'cpp',
    'csharp',
    'ruby',
    'php',
    'html',
    'css',
    'scss',
    'json',
    'yaml',
    'xml',
    'markdown',
    'plaintext',
  };

  static const Map<String, String> extensionToLanguage = {
    'dart': 'dart',
    'js': 'javascript',
    'mjs': 'javascript',
    'cjs': 'javascript',
    'ts': 'typescript',
    'tsx': 'typescript',
    'py': 'python',
    'rs': 'rust',
    'go': 'go',
    'java': 'java',
    'kt': 'kotlin',
    'kts': 'kotlin',
    'swift': 'swift',
    'c': 'c',
    'h': 'c',
    'cpp': 'cpp',
    'cc': 'cpp',
    'cxx': 'cpp',
    'hpp': 'cpp',
    'cs': 'csharp',
    'rb': 'ruby',
    'php': 'php',
    'html': 'html',
    'htm': 'html',
    'css': 'css',
    'scss': 'scss',
    'sass': 'scss',
    'json': 'json',
    'yaml': 'yaml',
    'yml': 'yaml',
    'xml': 'xml',
    'md': 'markdown',
    'txt': 'plaintext',
  };

  LanguageId._(this.value);

  static Either<DomainFailure, LanguageId> create(String input) {
    final normalized = input.trim().toLowerCase();

    if (normalized.isEmpty) {
      return Right(LanguageId._('plaintext'));
    }

    if (!supportedLanguages.contains(normalized)) {
      return Left(
        DomainFailure.validationError(
          field: 'languageId',
          reason: 'Unsupported language: $input',
          value: input,
        ),
      );
    }

    return Right(LanguageId._(normalized));
  }

  static LanguageId fromFileExtension(String extension) {
    final normalized = extension.trim().toLowerCase();
    final language = extensionToLanguage[normalized] ?? 'plaintext';
    return LanguageId._(language);
  }

  static LanguageId get plaintext => LanguageId._('plaintext');

  bool get isSupported => supportedLanguages.contains(value);

  String get displayName {
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
