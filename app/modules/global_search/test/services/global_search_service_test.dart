import 'package:flutter_test/flutter_test.dart';
import 'package:global_search/global_search.dart';

void main() {
  group('GlobalSearchService', () {
    late GlobalSearchService service;

    setUp(() {
      service = GlobalSearchService();
    });

    test('should search files with basic pattern', () async {
      // Arrange
      final files = [
        const FileContent(
          filePath: '/test/file1.dart',
          content: 'const value = 42;\nfinal test = true;',
        ),
        const FileContent(
          filePath: '/test/file2.dart',
          content: 'test function() { return test; }',
        ),
      ];

      final config = const SearchConfig(
        pattern: 'test',
        caseInsensitive: false,
        useRegex: false,
        maxResults: 100,
      );

      // Act
      final result = await service.searchFiles(
        files: files,
        config: config,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (results) {
          expect(results.totalMatches, greaterThan(0));
          expect(results.filesWithMatches, greaterThan(0));
        },
      );
    });

    test('should perform case insensitive search', () async {
      // Arrange
      final files = [
        const FileContent(
          filePath: '/test/file.dart',
          content: 'Test TEST test TeSt',
        ),
      ];

      final config = const SearchConfig(
        pattern: 'test',
        caseInsensitive: true,
        useRegex: false,
        maxResults: 100,
      );

      // Act
      final result = await service.searchFiles(
        files: files,
        config: config,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (results) {
          expect(results.totalMatches, equals(4));
        },
      );
    });

    test('should return empty results when pattern not found', () async {
      // Arrange
      final files = [
        const FileContent(
          filePath: '/test/file.dart',
          content: 'const value = 42;',
        ),
      ];

      final config = const SearchConfig(
        pattern: 'nonexistent',
        caseInsensitive: false,
        useRegex: false,
        maxResults: 100,
      );

      // Act
      final result = await service.searchFiles(
        files: files,
        config: config,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (results) {
          expect(results.totalMatches, equals(0));
          expect(results.filesWithMatches, equals(0));
        },
      );
    });

    test('should search with regex pattern', () async {
      // Arrange
      final files = [
        const FileContent(
          filePath: '/test/file.dart',
          content: 'value1 value2 value3 test4',
        ),
      ];

      final config = const SearchConfig(
        pattern: r'value\d+',
        caseInsensitive: false,
        useRegex: true,
        maxResults: 100,
      );

      // Act
      final result = await service.searchFiles(
        files: files,
        config: config,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (results) {
          expect(results.totalMatches, greaterThanOrEqualTo(3));
        },
      );
    });

    test('should respect maxResults limit', () async {
      // Arrange
      final files = [
        const FileContent(
          filePath: '/test/file.dart',
          content: 'test test test test test',
        ),
      ];

      final config = const SearchConfig(
        pattern: 'test',
        caseInsensitive: false,
        useRegex: false,
        maxResults: 2,
      );

      // Act
      final result = await service.searchFiles(
        files: files,
        config: config,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (results) {
          expect(results.matches.length, lessThanOrEqualTo(2));
        },
      );
    });

    test('should handle empty file list', () async {
      // Arrange
      final files = <FileContent>[];

      final config = const SearchConfig(
        pattern: 'test',
        caseInsensitive: false,
        useRegex: false,
        maxResults: 100,
      );

      // Act
      final result = await service.searchFiles(
        files: files,
        config: config,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (results) {
          expect(results.totalMatches, equals(0));
          expect(results.filesSearched, equals(0));
        },
      );
    });

    test('should find matches across multiple files', () async {
      // Arrange
      final files = [
        const FileContent(
          filePath: '/test/file1.dart',
          content: 'test content',
        ),
        const FileContent(
          filePath: '/test/file2.dart',
          content: 'more test here',
        ),
        const FileContent(
          filePath: '/test/file3.dart',
          content: 'final test value',
        ),
      ];

      final config = const SearchConfig(
        pattern: 'test',
        caseInsensitive: false,
        useRegex: false,
        maxResults: 100,
      );

      // Act
      final result = await service.searchFiles(
        files: files,
        config: config,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (error) => fail('Should not fail: $error'),
        (results) {
          expect(results.filesWithMatches, equals(3));
          expect(results.totalMatches, greaterThanOrEqualTo(3));
        },
      );
    });
  });
}
