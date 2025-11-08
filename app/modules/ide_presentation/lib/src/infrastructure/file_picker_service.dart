import 'package:file_picker/file_picker.dart';

/// FilePickerService
///
/// Service for picking files using native file picker dialogs.
///
/// Architecture (Clean Architecture):
/// - Belongs to Presentation layer
/// - Wraps platform file_picker package
/// - Returns simple String paths (no domain logic)
///
/// Responsibilities:
/// - Show native file picker for opening files
/// - Show native file picker for saving files
/// - Filter by file types
///
/// Example:
/// ```dart
/// final service = FilePickerService();
///
/// final filePath = await service.pickFile();
/// if (filePath != null) {
///   // Load file
/// }
/// ```
class FilePickerService {
  /// Picks a single file using native dialog
  ///
  /// Returns file path or null if cancelled
  ///
  /// Parameters:
  /// - [allowedExtensions]: List of allowed file extensions (e.g., ['dart', 'js'])
  /// - [dialogTitle]: Dialog window title
  Future<String?> pickFile({
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        dialogTitle: dialogTitle ?? 'Open File',
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }

      return null;
    } catch (e) {
      // Return null on error (user can try again)
      return null;
    }
  }

  /// Picks multiple files using native dialog
  ///
  /// Returns list of file paths or empty list if cancelled
  Future<List<String>> pickMultipleFiles({
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        dialogTitle: dialogTitle ?? 'Open Files',
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Picks a directory using native dialog
  ///
  /// Returns directory path or null if cancelled
  Future<String?> pickDirectory({String? dialogTitle}) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle ?? 'Select Directory',
      );

      return result;
    } catch (e) {
      return null;
    }
  }

  /// Shows save file dialog
  ///
  /// Note: file_picker doesn't support save dialog directly,
  /// so this uses pick directory and lets user type filename
  ///
  /// Returns file path or null if cancelled
  Future<String?> saveFile({
    String? suggestedFileName,
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    try {
      // For now, use file picker to select location
      // In future, we can use platform-specific save dialogs
      final directory = await pickDirectory(
        dialogTitle: dialogTitle ?? 'Save File',
      );

      if (directory != null && suggestedFileName != null) {
        return '$directory/$suggestedFileName';
      }

      return directory;
    } catch (e) {
      return null;
    }
  }

  /// Common file type filters
  static const codeFileExtensions = [
    'dart',
    'js',
    'ts',
    'jsx',
    'tsx',
    'rs',
    'go',
    'py',
    'java',
    'kt',
    'swift',
    'c',
    'cpp',
    'h',
    'hpp',
    'cs',
    'rb',
    'php',
  ];

  static const markdownExtensions = ['md', 'markdown'];
  static const configExtensions = ['json', 'yaml', 'yml', 'toml', 'xml'];
  static const allTextExtensions = [
    ...codeFileExtensions,
    ...markdownExtensions,
    ...configExtensions,
    'txt',
  ];
}
