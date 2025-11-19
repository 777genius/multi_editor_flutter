import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multi_editor_plugins/src/services/file_navigation_service.dart';

// Concrete implementation for testing
class TestFileNavigationService implements FileNavigationService {
  final List<String> openedFiles = [];
  bool _isAvailable = true;
  Exception? _nextException;

  void setAvailable(bool available) {
    _isAvailable = available;
  }

  void throwOnNextCall(Exception exception) {
    _nextException = exception;
  }

  @override
  Future<void> openFile(String fileId) async {
    if (_nextException != null) {
      final exception = _nextException!;
      _nextException = null;
      throw exception;
    }

    if (!_isAvailable) {
      throw StateError('Service not available');
    }

    if (fileId.isEmpty) {
      throw ArgumentError('fileId cannot be empty');
    }

    openedFiles.add(fileId);
  }

  @override
  bool get isAvailable => _isAvailable;
}

class MockFileNavigationService extends Mock implements FileNavigationService {}

void main() {
  group('FileNavigationService', () {
    group('concrete implementation', () {
      late TestFileNavigationService service;

      setUp(() {
        service = TestFileNavigationService();
      });

      group('openFile', () {
        test('should successfully open file when available', () async {
          // Arrange
          const fileId = 'test-file-123';

          // Act
          await service.openFile(fileId);

          // Assert
          expect(service.openedFiles, contains(fileId));
        });

        test('should open multiple files sequentially', () async {
          // Arrange
          const fileIds = ['file1', 'file2', 'file3'];

          // Act
          for (final fileId in fileIds) {
            await service.openFile(fileId);
          }

          // Assert
          expect(service.openedFiles.length, 3);
          expect(service.openedFiles, equals(fileIds));
        });

        test('should throw when service is not available', () async {
          // Arrange
          service.setAvailable(false);

          // Act & Assert
          expect(
            () => service.openFile('test-file'),
            throwsA(isA<StateError>()),
          );
        });

        test('should throw ArgumentError when fileId is empty', () async {
          // Act & Assert
          expect(
            () => service.openFile(''),
            throwsArgumentError,
          );
        });

        test('should allow opening same file multiple times', () async {
          // Arrange
          const fileId = 'test-file';

          // Act
          await service.openFile(fileId);
          await service.openFile(fileId);

          // Assert
          expect(service.openedFiles.length, 2);
          expect(service.openedFiles.where((id) => id == fileId).length, 2);
        });

        test('should propagate exceptions from implementation', () async {
          // Arrange
          service.throwOnNextCall(Exception('File not found'));

          // Act & Assert
          expect(
            () => service.openFile('test-file'),
            throwsException,
          );
        });

        test('should handle file IDs with special characters', () async {
          // Arrange
          const specialFileIds = [
            'file-with-dash',
            'file_with_underscore',
            'file.with.dots',
            'file:with:colons',
          ];

          // Act
          for (final fileId in specialFileIds) {
            await service.openFile(fileId);
          }

          // Assert
          expect(service.openedFiles.length, 4);
        });

        test('should handle long file IDs', () async {
          // Arrange
          final longFileId = 'a' * 1000;

          // Act
          await service.openFile(longFileId);

          // Assert
          expect(service.openedFiles, contains(longFileId));
        });
      });

      group('isAvailable', () {
        test('should return true when service is available', () {
          // Arrange & Act
          service.setAvailable(true);

          // Assert
          expect(service.isAvailable, true);
        });

        test('should return false when service is not available', () {
          // Arrange & Act
          service.setAvailable(false);

          // Assert
          expect(service.isAvailable, false);
        });

        test('should start as available by default', () {
          // Assert
          expect(service.isAvailable, true);
        });

        test('should reflect availability changes immediately', () {
          // Arrange & Act
          expect(service.isAvailable, true);

          service.setAvailable(false);
          expect(service.isAvailable, false);

          service.setAvailable(true);
          expect(service.isAvailable, true);
        });
      });

      group('integration scenarios', () {
        test('should handle availability toggling during operations', () async {
          // Arrange & Act
          await service.openFile('file1');

          service.setAvailable(false);
          expect(() => service.openFile('file2'), throwsA(isA<StateError>()));

          service.setAvailable(true);
          await service.openFile('file3');

          // Assert
          expect(service.openedFiles.length, 2);
          expect(service.openedFiles, contains('file1'));
          expect(service.openedFiles, contains('file3'));
          expect(service.openedFiles, isNot(contains('file2')));
        });

        test('should maintain order of opened files', () async {
          // Arrange
          const filesInOrder = ['first', 'second', 'third'];

          // Act
          for (final file in filesInOrder) {
            await service.openFile(file);
          }

          // Assert
          expect(service.openedFiles, equals(filesInOrder));
        });
      });
    });

    group('mock implementation', () {
      late MockFileNavigationService mockService;

      setUp(() {
        mockService = MockFileNavigationService();
      });

      test('should allow mocking openFile behavior', () async {
        // Arrange
        when(() => mockService.openFile(any()))
            .thenAnswer((_) async => Future.value());
        when(() => mockService.isAvailable).thenReturn(true);

        // Act
        await mockService.openFile('test-file');

        // Assert
        verify(() => mockService.openFile('test-file')).called(1);
      });

      test('should allow mocking failures', () async {
        // Arrange
        when(() => mockService.openFile(any()))
            .thenThrow(Exception('Mock failure'));

        // Act & Assert
        expect(
          () => mockService.openFile('test-file'),
          throwsException,
        );
      });

      test('should allow verifying specific file IDs', () async {
        // Arrange
        when(() => mockService.openFile(any()))
            .thenAnswer((_) async => Future.value());

        // Act
        await mockService.openFile('specific-file-123');

        // Assert
        verify(() => mockService.openFile('specific-file-123')).called(1);
        verifyNever(() => mockService.openFile('other-file'));
      });

      test('should allow checking availability', () {
        // Arrange
        when(() => mockService.isAvailable).thenReturn(false);

        // Act
        final available = mockService.isAvailable;

        // Assert
        expect(available, false);
        verify(() => mockService.isAvailable).called(1);
      });

      test('should support different return values for different calls',
          () async {
        // Arrange
        var callCount = 0;
        when(() => mockService.openFile(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 2) {
            throw Exception('Second call fails');
          }
        });

        // Act & Assert
        await mockService.openFile('file1'); // Success
        expect(
          () => mockService.openFile('file2'),
          throwsException,
        ); // Failure
      });

      test('should allow capturing arguments', () async {
        // Arrange
        final captured = <String>[];
        when(() => mockService.openFile(any())).thenAnswer((invocation) async {
          captured.add(invocation.positionalArguments[0] as String);
        });

        // Act
        await mockService.openFile('file1');
        await mockService.openFile('file2');
        await mockService.openFile('file3');

        // Assert
        expect(captured, ['file1', 'file2', 'file3']);
      });
    });

    group('interface contract', () {
      test('should define openFile method returning Future<void>', () {
        // This test ensures the interface contract is correctly defined
        final service = TestFileNavigationService();
        expect(service.openFile('test'), isA<Future<void>>());
      });

      test('should define isAvailable getter returning bool', () {
        final service = TestFileNavigationService();
        expect(service.isAvailable, isA<bool>());
      });
    });

    group('error handling', () {
      late TestFileNavigationService service;

      setUp(() {
        service = TestFileNavigationService();
      });

      test('should handle null-like file IDs appropriately', () async {
        // Act & Assert
        expect(() => service.openFile(''), throwsArgumentError);
      });

      test('should recover from exceptions', () async {
        // Arrange
        service.throwOnNextCall(Exception('Temporary error'));

        // Act
        expect(() => service.openFile('file1'), throwsException);
        await service.openFile('file2'); // Should succeed

        // Assert
        expect(service.openedFiles, contains('file2'));
        expect(service.openedFiles, isNot(contains('file1')));
      });

      test('should handle rapid successive calls', () async {
        // Arrange
        final futures = <Future>[];

        // Act
        for (var i = 0; i < 100; i++) {
          futures.add(service.openFile('file-$i'));
        }
        await Future.wait(futures);

        // Assert
        expect(service.openedFiles.length, 100);
      });
    });

    group('edge cases', () {
      late TestFileNavigationService service;

      setUp(() {
        service = TestFileNavigationService();
      });

      test('should handle whitespace-only file IDs', () async {
        // Arrange
        const fileId = '   ';

        // Act
        await service.openFile(fileId);

        // Assert
        expect(service.openedFiles, contains(fileId));
      });

      test('should handle file IDs with newlines', () async {
        // Arrange
        const fileId = 'file\nwith\nnewlines';

        // Act
        await service.openFile(fileId);

        // Assert
        expect(service.openedFiles, contains(fileId));
      });

      test('should handle unicode file IDs', () async {
        // Arrange
        const unicodeFileIds = [
          'файл',
          '文件',
          '📁file',
          'fichier-café',
        ];

        // Act
        for (final fileId in unicodeFileIds) {
          await service.openFile(fileId);
        }

        // Assert
        expect(service.openedFiles.length, 4);
      });
    });
  });
}
