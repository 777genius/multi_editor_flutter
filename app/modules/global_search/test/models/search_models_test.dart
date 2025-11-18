import 'package:flutter_test/flutter_test.dart';
import 'package:global_search/global_search.dart';

void main() {
  group('SearchMatch', () {
    test('should create SearchMatch from constructor', () {
      // Arrange & Act
      const match = SearchMatch(
        filePath: '/test/file.dart',
        lineNumber: 10,
        column: 5,
        lineContent: 'const value = "test";',
        matchLength: 4,
        contextBefore: ['// Previous line'],
        contextAfter: ['// Next line'],
      );

      // Assert
      expect(match.filePath, equals('/test/file.dart'));
      expect(match.lineNumber, equals(10));
      expect(match.column, equals(5));
      expect(match.lineContent, equals('const value = "test";'));
      expect(match.matchLength, equals(4));
      expect(match.contextBefore.length, equals(1));
      expect(match.contextAfter.length, equals(1));
    });

    test('should parse SearchMatch from JSON', () {
      // Arrange
      final json = {
        'file_path': '/src/main.dart',
        'line_number': 15,
        'column': 8,
        'line_content': 'print("hello");',
        'match_length': 5,
        'context_before': ['import "dart:io";'],
        'context_after': ['}'],
      };

      // Act
      final match = SearchMatch.fromJson(json);

      // Assert
      expect(match.filePath, equals('/src/main.dart'));
      expect(match.lineNumber, equals(15));
      expect(match.column, equals(8));
      expect(match.lineContent, equals('print("hello");'));
      expect(match.matchLength, equals(5));
      expect(match.contextBefore[0], equals('import "dart:io";'));
      expect(match.contextAfter[0], equals('}'));
    });

    test('should extract matched text correctly', () {
      // Arrange
      const match = SearchMatch(
        filePath: '/test/file.dart',
        lineNumber: 1,
        column: 6,
        lineContent: 'const value = 42;',
        matchLength: 5,
        contextBefore: [],
        contextAfter: [],
      );

      // Act
      final matchedText = match.matchedText;

      // Assert
      expect(matchedText, equals('value'));
    });

    test('should return empty string when match exceeds line length', () {
      // Arrange
      const match = SearchMatch(
        filePath: '/test/file.dart',
        lineNumber: 1,
        column: 100,
        lineContent: 'short line',
        matchLength: 50,
        contextBefore: [],
        contextAfter: [],
      );

      // Act
      final matchedText = match.matchedText;

      // Assert
      expect(matchedText, isEmpty);
    });

    test('should handle empty context arrays', () {
      // Arrange
      const match = SearchMatch(
        filePath: '/test/file.dart',
        lineNumber: 1,
        column: 0,
        lineContent: 'test',
        matchLength: 4,
        contextBefore: [],
        contextAfter: [],
      );

      // Assert
      expect(match.contextBefore, isEmpty);
      expect(match.contextAfter, isEmpty);
    });
  });

  group('SearchResults', () {
    test('should create SearchResults from constructor', () {
      // Arrange
      final matches = [
        const SearchMatch(
          filePath: '/test/file1.dart',
          lineNumber: 1,
          column: 0,
          lineContent: 'test',
          matchLength: 4,
          contextBefore: [],
          contextAfter: [],
        ),
        const SearchMatch(
          filePath: '/test/file2.dart',
          lineNumber: 5,
          column: 2,
          lineContent: 'test again',
          matchLength: 4,
          contextBefore: [],
          contextAfter: [],
        ),
      ];

      // Act
      final results = SearchResults(
        matches: matches,
        totalMatches: 2,
        filesSearched: 10,
        filesWithMatches: 2,
        durationMs: 150,
      );

      // Assert
      expect(results.matches.length, equals(2));
      expect(results.totalMatches, equals(2));
      expect(results.filesSearched, equals(10));
      expect(results.filesWithMatches, equals(2));
      expect(results.durationMs, equals(150));
    });

    test('should parse SearchResults from JSON', () {
      // Arrange
      final json = {
        'matches': [
          {
            'file_path': '/src/main.dart',
            'line_number': 10,
            'column': 5,
            'line_content': 'const test = 1;',
            'match_length': 4,
            'context_before': <String>[],
            'context_after': <String>[],
          },
        ],
        'total_matches': 1,
        'files_searched': 25,
        'files_with_matches': 1,
        'duration_ms': 200,
      };

      // Act
      final results = SearchResults.fromJson(json);

      // Assert
      expect(results.matches.length, equals(1));
      expect(results.matches[0].filePath, equals('/src/main.dart'));
      expect(results.totalMatches, equals(1));
      expect(results.filesSearched, equals(25));
      expect(results.filesWithMatches, equals(1));
      expect(results.durationMs, equals(200));
    });

    test('should handle empty matches list', () {
      // Arrange
      const results = SearchResults(
        matches: [],
        totalMatches: 0,
        filesSearched: 100,
        filesWithMatches: 0,
        durationMs: 50,
      );

      // Assert
      expect(results.matches, isEmpty);
      expect(results.totalMatches, equals(0));
      expect(results.filesWithMatches, equals(0));
    });

    test('should handle large number of matches', () {
      // Arrange
      final matches = List.generate(
        1000,
        (i) => SearchMatch(
          filePath: '/test/file$i.dart',
          lineNumber: i,
          column: 0,
          lineContent: 'test $i',
          matchLength: 4,
          contextBefore: const [],
          contextAfter: const [],
        ),
      );

      // Act
      final results = SearchResults(
        matches: matches,
        totalMatches: 1000,
        filesSearched: 1000,
        filesWithMatches: 1000,
        durationMs: 5000,
      );

      // Assert
      expect(results.matches.length, equals(1000));
      expect(results.totalMatches, equals(1000));
    });

    test('should handle search results with multiple files', () {
      // Arrange
      final json = {
        'matches': [
          {
            'file_path': '/src/file1.dart',
            'line_number': 5,
            'column': 0,
            'line_content': 'search term',
            'match_length': 11,
            'context_before': <String>[],
            'context_after': <String>[],
          },
          {
            'file_path': '/src/file2.dart',
            'line_number': 10,
            'column': 3,
            'line_content': 'another search term',
            'match_length': 11,
            'context_before': <String>[],
            'context_after': <String>[],
          },
        ],
        'total_matches': 2,
        'files_searched': 50,
        'files_with_matches': 2,
        'duration_ms': 300,
      };

      // Act
      final results = SearchResults.fromJson(json);

      // Assert
      expect(results.matches.length, equals(2));
      expect(results.filesWithMatches, equals(2));
      expect(results.matches[0].filePath, contains('file1.dart'));
      expect(results.matches[1].filePath, contains('file2.dart'));
    });
  });
}
