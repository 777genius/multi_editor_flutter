import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:path/path.dart' as path;

/// FileService
///
/// Service for handling file I/O operations.
///
/// Architecture (Clean Architecture):
/// - Belongs to Presentation/Infrastructure boundary
/// - Uses platform APIs (dart:io) for file operations
/// - Returns Either<Failure, Success> for error handling
/// - No business logic - just file I/O
///
/// Responsibilities:
/// - Read files from filesystem
/// - Write files to filesystem
/// - Detect file language from extension
/// - Watch file changes (future)
///
/// Example:
/// ```dart
/// final service = FileService();
///
/// final result = await service.readFile('/path/to/file.dart');
/// result.fold(
///   (failure) => print('Error: \$failure'),
///   (document) => print('Loaded: \${document.uri}'),
/// );
/// ```
class FileService {
  /// Reads a file from filesystem and creates EditorDocument
  Future<Either<EditorFailure, EditorDocument>> readFile(String filePath) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return left(EditorFailure.documentNotFound(
          message: 'File not found: $filePath',
        ));
      }

      // Read file content
      final content = await file.readAsString();

      // Detect language from extension
      final languageId = _detectLanguage(filePath);

      // Create DocumentUri
      final uri = DocumentUri.fromFilePath(filePath);

      // Create EditorDocument
      final document = EditorDocument(
        uri: uri,
        content: content,
        languageId: languageId,
        lastModified: DateTime.now(),
      );

      return right(document);
    } on FileSystemException catch (e) {
      return left(EditorFailure.operationFailed(
        operation: 'readFile',
        reason: e.message,
      ));
    } catch (e) {
      return left(EditorFailure.unexpected(
        message: 'Failed to read file: $filePath',
        error: e,
      ));
    }
  }

  /// Writes EditorDocument content to filesystem
  Future<Either<EditorFailure, Unit>> writeFile({
    required String filePath,
    required String content,
  }) async {
    try {
      final file = File(filePath);

      // Create parent directories if they don't exist
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // CRITICAL: Use atomic write to prevent data loss
      // Write to temp file first, then atomically rename
      // This prevents file corruption if process crashes during write
      final tempFile = File('$filePath.tmp.${DateTime.now().millisecondsSinceEpoch}');

      try {
        // Write content to temp file
        await tempFile.writeAsString(content, flush: true);

        // CRITICAL: Atomic overwrite with cross-platform compatibility
        // On POSIX: rename is atomic and replaces the target
        // On Windows: rename fails if target exists
        // Strategy: try atomic rename first, fallback to delete+rename on Windows
        try {
          await tempFile.rename(filePath);
        } on FileSystemException catch (e) {
          // On Windows, if rename failed because target exists, delete and retry
          if (await file.exists()) {
            await file.delete();
            await tempFile.rename(filePath);
          } else {
            rethrow;
          }
        }

        return right(unit);
      } catch (e) {
        // Clean up temp file if operation fails
        try {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        } catch (_) {
          // Ignore cleanup errors
        }
        rethrow;
      }
    } on FileSystemException catch (e) {
      return left(EditorFailure.operationFailed(
        operation: 'writeFile',
        reason: e.message,
      ));
    } catch (e) {
      return left(EditorFailure.unexpected(
        message: 'Failed to write file: $filePath',
        error: e,
      ));
    }
  }

  /// Checks if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Gets file info (size, modified date, etc.)
  Future<FileStat?> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.stat();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Lists files in directory
  Future<Either<EditorFailure, List<String>>> listDirectory(String dirPath) async {
    try {
      final directory = Directory(dirPath);

      if (!await directory.exists()) {
        return left(const EditorFailure.operationFailed(
          operation: 'listDirectory',
          reason: 'Directory not found',
        ));
      }

      final files = <String>[];
      await for (final entity in directory.list()) {
        files.add(entity.path);
      }

      return right(files);
    } on FileSystemException catch (e) {
      return left(EditorFailure.operationFailed(
        operation: 'listDirectory',
        reason: e.message,
      ));
    } catch (e) {
      return left(EditorFailure.unexpected(
        message: 'Failed to list directory: $dirPath',
        error: e,
      ));
    }
  }

  /// Detects programming language from file extension
  LanguageId _detectLanguage(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    switch (extension) {
      case '.dart':
        return LanguageId.dart;
      case '.ts':
      case '.tsx':
        return LanguageId.typescript;
      case '.js':
      case '.jsx':
        return LanguageId.javascript;
      case '.rs':
        return LanguageId.rust;
      case '.go':
        return LanguageId.go;
      case '.py':
        return LanguageId.python;
      case '.java':
        return LanguageId.java;
      case '.kt':
      case '.kts':
        return LanguageId.kotlin;
      case '.swift':
        return LanguageId.swift;
      case '.c':
        return LanguageId.c;
      case '.cpp':
      case '.cc':
      case '.cxx':
      case '.h':
      case '.hpp':
        return LanguageId.cpp;
      case '.cs':
        return LanguageId.csharp;
      case '.rb':
        return LanguageId.ruby;
      case '.php':
        return LanguageId.php;
      case '.html':
      case '.htm':
        return LanguageId.html;
      case '.css':
        return LanguageId.css;
      case '.scss':
      case '.sass':
        return LanguageId.scss;
      case '.json':
        return LanguageId.json;
      case '.xml':
        return LanguageId.xml;
      case '.yaml':
      case '.yml':
        return LanguageId.yaml;
      case '.md':
      case '.markdown':
        return LanguageId.markdown;
      case '.sql':
        return LanguageId.sql;
      case '.sh':
      case '.bash':
        return LanguageId.shellscript;
      default:
        return LanguageId.plaintext;
    }
  }

  /// Gets file name from path
  String getFileName(String filePath) {
    return path.basename(filePath);
  }

  /// Gets directory path from file path
  String getDirectoryPath(String filePath) {
    return path.dirname(filePath);
  }

  /// Checks if path is directory
  Future<bool> isDirectory(String path) async {
    try {
      final stat = await FileStat.stat(path);
      return stat.type == FileSystemEntityType.directory;
    } catch (e) {
      return false;
    }
  }

  /// Checks if path is file
  Future<bool> isFile(String path) async {
    try {
      final stat = await FileStat.stat(path);
      return stat.type == FileSystemEntityType.file;
    } catch (e) {
      return false;
    }
  }
}
