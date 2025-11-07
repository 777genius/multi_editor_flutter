import '../entities/file_icon.dart';
import '../entities/icon_theme.dart';
import '../value_objects/file_extension.dart';
import '../value_objects/icon_url.dart';

/// Domain service for icon resolution logic.
///
/// This contains the core business logic for finding the right icon
/// for a given file. Pure domain logic, no infrastructure dependencies.
///
/// Follows SRP (Single Responsibility Principle).
class IconResolutionService {
  /// Resolve icon URL for a file extension using the active theme.
  ///
  /// Resolution strategy:
  /// 1. Check if theme supports this extension
  /// 2. Generate icon URL based on theme provider
  /// 3. Handle special cases (e.g., compound extensions like "test.dart")
  /// 4. Fall back to generic icon if needed
  IconUrl resolveIconUrl(FileExtension extension, IconTheme theme) {
    // Handle unknown extensions
    if (extension.isUnknown) {
      return _getGenericIconUrl(theme);
    }

    // Check if theme supports this extension
    if (!theme.supportsExtension(extension.value)) {
      return _getGenericIconUrl(theme);
    }

    // Generate icon URL based on theme provider
    try {
      final iconUrl = theme.getIconUrl(extension.value);
      return IconUrl.parse(iconUrl);
    } catch (e) {
      // If URL parsing fails, return generic icon
      return _getGenericIconUrl(theme);
    }
  }

  /// Create FileIcon entity from extension and theme.
  FileIcon createFileIcon(
    FileExtension extension,
    IconTheme theme, {
    int size = 18,
  }) {
    final url = resolveIconUrl(extension, theme);

    return FileIcon(
      url: url,
      extension: extension.value,
      themeId: theme.id,
      format: 'svg',
      size: size,
    );
  }

  /// Extract extension from filename, handling compound extensions.
  ///
  /// Examples:
  /// - "test.dart" -> "dart"
  /// - "config.test.ts" -> "test.ts" (compound extension)
  /// - "README.md" -> "md"
  /// - "Dockerfile" -> "dockerfile"
  FileExtension extractExtension(String filename) {
    if (filename.isEmpty) {
      return const FileExtension(value: 'unknown');
    }

    // Handle special filenames without extensions
    final specialFiles = {
      'dockerfile': 'dockerfile',
      'makefile': 'makefile',
      'cmakelists.txt': 'cmake',
      '.gitignore': 'git',
      '.dockerignore': 'docker',
      '.env': 'env',
    };

    final lowerFilename = filename.toLowerCase();
    if (specialFiles.containsKey(lowerFilename)) {
      return FileExtension(value: specialFiles[lowerFilename]!);
    }

    // Check for compound extensions (e.g., .test.ts, .spec.js)
    final compoundPattern = RegExp(r'\.(test|spec|stories|d)\.\w+$');
    final compoundMatch = compoundPattern.firstMatch(filename);
    if (compoundMatch != null) {
      final compoundExt = compoundMatch
          .group(0)!
          .substring(1); // Remove leading dot
      return FileExtension(value: compoundExt);
    }

    // Standard extension extraction
    return FileExtension.parse(filename);
  }

  /// Get priority for icon selection when multiple themes provide icons.
  ///
  /// Lower value = higher priority
  int getIconPriority(IconTheme theme) {
    return theme.priority;
  }

  /// Check if an icon should be loaded lazily or eagerly.
  ///
  /// Strategy: Load icons for common file types eagerly, others lazily.
  bool shouldLoadEagerly(FileExtension extension) {
    const eagerExtensions = {
      'dart',
      'js',
      'ts',
      'json',
      'md',
      'yaml',
      'yml',
      'html',
      'css',
      'scss',
      'py',
      'java',
      'go',
      'rs',
    };

    return eagerExtensions.contains(extension.value);
  }

  /// Get generic/fallback icon URL
  IconUrl _getGenericIconUrl(IconTheme theme) {
    // Most themes have a generic "file" icon
    try {
      final genericUrl = theme.getIconUrl('default');
      return IconUrl.parse(genericUrl);
    } catch (e) {
      // Ultimate fallback - return a data URL or placeholder
      return const IconUrl(
        value: 'https://api.iconify.design/vscode-icons:default-file.svg',
      );
    }
  }
}
