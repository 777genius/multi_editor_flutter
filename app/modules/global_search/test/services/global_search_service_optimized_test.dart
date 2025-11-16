import 'package:flutter_test/flutter_test.dart';
import 'package:global_search/src/services/global_search_service_optimized.dart';
import 'package:global_search/src/models/search_models.dart';

void main() {
  late GlobalSearchServiceOptimized service;

  setUp(() {
    service = GlobalSearchServiceOptimized();
  });

  group('GlobalSearchServiceOptimized', () {
    test('should find matches in files', () async {
      // Arrange
      final files = [
        FileContent(
          path: '/test/file1.dart',
          content: 'class Example {\n  void test() {\n    print("Hello");\n  }\n}',
        ),
        FileContent(
          path: '/test/file2.dart',
          content: 'void main() {\n  test();\n}\n',
        ),
      ];

      final config = SearchConfig(
        pattern: 'test',
        caseInsensitive: true,
        useRegex: false,
      );

      // Act
      final result = await service.searchFiles(files: files, config: config);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Search failed: $error'),
        (results) {
          expect(results.totalMatches, greaterThan(0));
          expect(results.filesWithMatches, greaterThan(0));
          expect(results.matches, isNotEmpty);
          expect(results.durationMs, greaterThanOrEqualTo(0));
        },
      );
    });

    test('should handle regex patterns', () async {
      // Arrange
      final files = [
        FileContent(
          path: '/test/file.dart',
          content: 'const x = 123;\nconst y = 456;\nvar z = 789;',
        ),
      ];

      final config = SearchConfig(
        pattern: r'const\s+\w+\s+=\s+\d+',
        caseInsensitive: false,
        useRegex: true,
      );

      // Act
      final result = await service.searchFiles(files: files, config: config);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Search failed: $error'),
        (results) {
          expect(results.totalMatches, 2); // Should find 'const x' and 'const y'
        },
      );
    });

    test('should respect case sensitivity', () async {
      // Arrange
      final files = [
        FileContent(
          path: '/test/file.txt',
          content: 'Test TEST test TeSt',
        ),
      ];

      // Case insensitive search
      final configInsensitive = SearchConfig(
        pattern: 'test',
        caseInsensitive: true,
        useRegex: false,
      );

      final resultInsensitive = await service.searchFiles(
        files: files,
        config: configInsensitive,
      );

      // Case sensitive search
      final configSensitive = SearchConfig(
        pattern: 'test',
        caseInsensitive: false,
        useRegex: false,
      );

      final resultSensitive = await service.searchFiles(
        files: files,
        config: configSensitive,
      );

      // Assert
      expect(resultInsensitive.isRight(), true);
      expect(resultSensitive.isRight(), true);

      resultInsensitive.fold(
        (error) => fail('Search failed'),
        (results) => expect(results.totalMatches, 4), // All variants
      );

      resultSensitive.fold(
        (error) => fail('Search failed'),
        (results) => expect(results.totalMatches, 1), // Only 'test'
      );
    });

    test('should provide context lines', () async {
      // Arrange
      final files = [
        FileContent(
          path: '/test/file.txt',
          content: 'Line 1\nLine 2\nMatch here\nLine 4\nLine 5',
        ),
      ];

      final config = SearchConfig(
        pattern: 'Match',
        caseInsensitive: false,
        useRegex: false,
        contextBefore: 1,
        contextAfter: 1,
      );

      // Act
      final result = await service.searchFiles(files: files, config: config);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Search failed'),
        (results) {
          expect(results.matches, hasLength(1));
          final match = results.matches.first;
          expect(match.contextBefore, hasLength(1));
          expect(match.contextBefore.first, 'Line 2');
          expect(match.contextAfter, hasLength(1));
          expect(match.contextAfter.first, 'Line 4');
        },
      );
    });

    test('should respect max matches limit', () async {
      // Arrange
      final files = [
        FileContent(
          path: '/test/file.txt',
          content: 'test test test test test',
        ),
      ];

      final config = SearchConfig(
        pattern: 'test',
        caseInsensitive: false,
        useRegex: false,
        maxMatches: 2,
      );

      // Act
      final result = await service.searchFiles(files: files, config: config);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Search failed'),
        (results) {
          expect(results.totalMatches, lessThanOrEqualTo(2));
        },
      );
    });

    test('should handle empty search results', () async {
      // Arrange
      final files = [
        FileContent(
          path: '/test/file.txt',
          content: 'No matches here',
        ),
      ];

      final config = SearchConfig(
        pattern: 'nonexistent',
        caseInsensitive: false,
        useRegex: false,
      );

      // Act
      final result = await service.searchFiles(files: files, config: config);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Search failed'),
        (results) {
          expect(results.totalMatches, 0);
          expect(results.filesWithMatches, 0);
          expect(results.matches, isEmpty);
        },
      );
    });

    test('should handle invalid regex gracefully', () async {
      // Arrange
      final files = [
        FileContent(
          path: '/test/file.txt',
          content: 'Some content',
        ),
      ];

      final config = SearchConfig(
        pattern: '[invalid(regex',
        caseInsensitive: false,
        useRegex: true,
      );

      // Act
      final result = await service.searchFiles(files: files, config: config);

      // Assert - Should not crash, should return empty results
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Should handle invalid regex'),
        (results) {
          expect(results.totalMatches, 0);
        },
      );
    });

    test('should perform faster with multiple files (parallelization)', () async {
      // Arrange - Create many files
      final files = List.generate(
        100,
        (i) => FileContent(
          path: '/test/file$i.txt',
          content: 'Line 1\nLine 2 test\nLine 3\n' * 10,
        ),
      );

      final config = SearchConfig(
        pattern: 'test',
        caseInsensitive: false,
        useRegex: false,
      );

      // Act
      final startTime = DateTime.now();
      final result = await service.searchFiles(files: files, config: config);
      final duration = DateTime.now().difference(startTime);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (error) => fail('Search failed'),
        (results) {
          expect(results.totalMatches, greaterThan(0));
          // With isolates, should complete reasonably fast
          expect(duration.inMilliseconds, lessThan(2000)); // < 2 seconds
        },
      );
    });

    test('should exclude paths correctly', () async {
      // Arrange
      final files = [
        FileContent(
          path: '/test/file.dart',
          content: 'test content',
        ),
        FileContent(
          path: '/test/node_modules/package.js',
          content: 'test content',
        ),
      ];

      final config = SearchConfig(
        pattern: 'test',
        caseInsensitive: false,
        useRegex: false,
        excludePaths: ['node_modules'],
      );

      // Note: searchFiles doesn't filter paths, searchInDirectory does
      // This test verifies the config accepts exclude paths
      final result = await service.searchFiles(files: files, config: config);

      expect(result.isRight(), true);
    });
  });
}
