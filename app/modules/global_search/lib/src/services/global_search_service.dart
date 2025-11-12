import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as path;
import '../models/search_models.dart';

/// Service for global text search across files
///
/// Provides both WASM (fast) and pure Dart (fallback) implementations.
class GlobalSearchService {
  /// Search across multiple files
  ///
  /// Parameters:
  /// - [files]: List of files with content to search
  /// - [config]: Search configuration
  ///
  /// Returns:
  /// - Right(SearchResults) on success
  /// - Left(error) on failure
  Future<Either<String, SearchResults>> searchFiles({
    required List<FileContent> files,
    required SearchConfig config,
  }) async {
    try {
      // TODO: Replace with WASM implementation when available
      // For now, use pure Dart fallback
      final results = await _searchFilesDart(files, config);
      return right(results);
    } catch (e) {
      return left('Search failed: $e');
    }
  }

  /// Search in a directory
  ///
  /// Parameters:
  /// - [directoryPath]: Path to directory to search
  /// - [config]: Search configuration
  /// - [recursive]: Whether to search recursively
  ///
  /// Returns:
  /// - Right(SearchResults) on success
  /// - Left(error) on failure
  Future<Either<String, SearchResults>> searchInDirectory({
    required String directoryPath,
    required SearchConfig config,
    bool recursive = true,
  }) async {
    try {
      // Collect files
      final files = await _collectFiles(directoryPath, config, recursive);

      if (files.isEmpty) {
        return right(SearchResults.empty);
      }

      // Search files
      return await searchFiles(files: files, config: config);
    } catch (e) {
      return left('Failed to search directory: $e');
    }
  }

  /// Pure Dart fallback implementation
  Future<SearchResults> _searchFilesDart(
    List<FileContent> files,
    SearchConfig config,
  ) async {
    final startTime = DateTime.now();
    final allMatches = <SearchMatch>[];
    var filesWithMatches = 0;

    // Prepare pattern
    final pattern = config.caseInsensitive
        ? config.pattern.toLowerCase()
        : config.pattern;

    // Compile regex if needed
    RegExp? regex;
    if (config.useRegex) {
      try {
        regex = RegExp(
          config.pattern,
          caseSensitive: !config.caseInsensitive,
        );
      } catch (e) {
        // Invalid regex
        return SearchResults.empty;
      }
    }

    for (final file in files) {
      // Check if file should be excluded
      if (_shouldExcludeFile(file.path, config)) {
        continue;
      }

      final fileMatches = _searchFile(file, config, pattern, regex);

      if (fileMatches.isNotEmpty) {
        filesWithMatches++;
        allMatches.addAll(fileMatches);
      }

      // Check max matches limit
      if (config.maxMatches > 0 && allMatches.length >= config.maxMatches) {
        allMatches.length = config.maxMatches;
        break;
      }
    }

    final duration = DateTime.now().difference(startTime);

    return SearchResults(
      matches: allMatches,
      totalMatches: allMatches.length,
      filesSearched: files.length,
      filesWithMatches: filesWithMatches,
      durationMs: duration.inMilliseconds,
    );
  }

  /// Search within a single file
  List<SearchMatch> _searchFile(
    FileContent file,
    SearchConfig config,
    String pattern,
    RegExp? regex,
  ) {
    final matches = <SearchMatch>[];
    final lines = file.content.split('\n');

    for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx];
      final lineMatches = regex != null
          ? _findRegexMatches(line, regex)
          : _findTextMatches(line, config.pattern, pattern, config.caseInsensitive);

      for (final match in lineMatches) {
        // Get context
        final contextBefore = _getContextLines(lines, lineIdx, config.contextBefore, true);
        final contextAfter = _getContextLines(lines, lineIdx, config.contextAfter, false);

        matches.add(SearchMatch(
          filePath: file.path,
          lineNumber: lineIdx + 1, // 1-indexed
          column: match.$1,
          lineContent: line,
          matchLength: match.$2,
          contextBefore: contextBefore,
          contextAfter: contextAfter,
        ));
      }
    }

    return matches;
  }

  /// Find regex matches in a line
  List<(int, int)> _findRegexMatches(String line, RegExp regex) {
    final matches = <(int, int)>[];
    for (final match in regex.allMatches(line)) {
      matches.add((match.start, match.end - match.start));
    }
    return matches;
  }

  /// Find plain text matches in a line
  List<(int, int)> _findTextMatches(
    String line,
    String originalPattern,
    String pattern,
    bool caseInsensitive,
  ) {
    final matches = <(int, int)>[];
    final searchIn = caseInsensitive ? line.toLowerCase() : line;

    var start = 0;
    while (true) {
      final pos = searchIn.indexOf(pattern, start);
      if (pos == -1) break;

      matches.add((pos, originalPattern.length));
      start = pos + 1;
    }

    return matches;
  }

  /// Get context lines before or after a given line
  List<String> _getContextLines(
    List<String> lines,
    int lineIdx,
    int count,
    bool before,
  ) {
    if (count == 0) return [];

    if (before) {
      final start = (lineIdx - count).clamp(0, lineIdx);
      return lines.sublist(start, lineIdx);
    } else {
      final end = (lineIdx + 1 + count).clamp(lineIdx + 1, lines.length);
      return lines.sublist(lineIdx + 1, end);
    }
  }

  /// Check if file should be excluded
  bool _shouldExcludeFile(String filePath, SearchConfig config) {
    // Check excluded paths
    for (final exclude in config.excludePaths) {
      if (filePath.contains(exclude)) {
        return true;
      }
    }

    // Get extension
    final ext = path.extension(filePath).replaceFirst('.', '');

    // Check excluded extensions
    if (config.excludeExtensions.contains(ext)) {
      return true;
    }

    // Check included extensions
    if (config.includeExtensions.isNotEmpty &&
        !config.includeExtensions.contains(ext)) {
      return true;
    }

    return false;
  }

  /// Collect files from directory
  Future<List<FileContent>> _collectFiles(
    String directoryPath,
    SearchConfig config,
    bool recursive,
  ) async {
    final files = <FileContent>[];
    final dir = Directory(directoryPath);

    if (!await dir.exists()) {
      return files;
    }

    await for (final entity in dir.list(recursive: recursive)) {
      if (entity is File) {
        // Check if should exclude
        if (_shouldExcludeFile(entity.path, config)) {
          continue;
        }

        try {
          final content = await entity.readAsString();
          files.add(FileContent(
            path: entity.path,
            content: content,
          ));
        } catch (e) {
          // Skip files that can't be read (binary, permissions, etc.)
          continue;
        }
      }
    }

    return files;
  }
}
