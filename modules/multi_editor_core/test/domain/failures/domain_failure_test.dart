import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/src/domain/failures/domain_failure.dart';

void main() {
  group('DomainFailure', () {
    group('notFound', () {
      test('should create not found failure', () {
        // Arrange & Act
        const failure = DomainFailure.notFound(
          entityType: 'FileDocument',
          entityId: '123',
        );

        // Assert
        expect(failure, isA<DomainFailure>());
        failure.when(
          notFound: (type, id, msg) {
            expect(type, equals('FileDocument'));
            expect(id, equals('123'));
            expect(msg, isNull);
          },
          alreadyExists: (_, __, ___) => fail('Should be notFound'),
          validationError: (_, __, ___) => fail('Should be notFound'),
          permissionDenied: (_, __, ___) => fail('Should be notFound'),
          syncError: (_, __, ___) => fail('Should be notFound'),
          unexpected: (_, __, ___) => fail('Should be notFound'),
        );
      });

      test('should create not found failure with custom message', () {
        // Arrange & Act
        const failure = DomainFailure.notFound(
          entityType: 'FileDocument',
          entityId: '123',
          message: 'File was deleted',
        );

        // Assert
        failure.when(
          notFound: (type, id, msg) {
            expect(msg, equals('File was deleted'));
          },
          alreadyExists: (_, __, ___) => fail('Should be notFound'),
          validationError: (_, __, ___) => fail('Should be notFound'),
          permissionDenied: (_, __, ___) => fail('Should be notFound'),
          syncError: (_, __, ___) => fail('Should be notFound'),
          unexpected: (_, __, ___) => fail('Should be notFound'),
        );
      });

      test('should have default display message', () {
        // Arrange
        const failure = DomainFailure.notFound(
          entityType: 'FileDocument',
          entityId: '123',
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, equals('FileDocument with id "123" not found'));
      });

      test('should use custom display message if provided', () {
        // Arrange
        const failure = DomainFailure.notFound(
          entityType: 'FileDocument',
          entityId: '123',
          message: 'Custom message',
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, equals('Custom message'));
      });
    });

    group('alreadyExists', () {
      test('should create already exists failure', () {
        // Arrange & Act
        const failure = DomainFailure.alreadyExists(
          entityType: 'FileDocument',
          entityId: '123',
        );

        // Assert
        failure.when(
          notFound: (_, __, ___) => fail('Should be alreadyExists'),
          alreadyExists: (type, id, msg) {
            expect(type, equals('FileDocument'));
            expect(id, equals('123'));
            expect(msg, isNull);
          },
          validationError: (_, __, ___) => fail('Should be alreadyExists'),
          permissionDenied: (_, __, ___) => fail('Should be alreadyExists'),
          syncError: (_, __, ___) => fail('Should be alreadyExists'),
          unexpected: (_, __, ___) => fail('Should be alreadyExists'),
        );
      });

      test('should have default display message', () {
        // Arrange
        const failure = DomainFailure.alreadyExists(
          entityType: 'FileDocument',
          entityId: 'main.dart',
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, equals('FileDocument with id "main.dart" already exists'));
      });
    });

    group('validationError', () {
      test('should create validation error failure', () {
        // Arrange & Act
        const failure = DomainFailure.validationError(
          field: 'fileName',
          reason: 'Contains invalid characters',
        );

        // Assert
        failure.when(
          notFound: (_, __, ___) => fail('Should be validationError'),
          alreadyExists: (_, __, ___) => fail('Should be validationError'),
          validationError: (field, reason, value) {
            expect(field, equals('fileName'));
            expect(reason, equals('Contains invalid characters'));
            expect(value, isNull);
          },
          permissionDenied: (_, __, ___) => fail('Should be validationError'),
          syncError: (_, __, ___) => fail('Should be validationError'),
          unexpected: (_, __, ___) => fail('Should be validationError'),
        );
      });

      test('should create validation error with value', () {
        // Arrange & Act
        const failure = DomainFailure.validationError(
          field: 'fileName',
          reason: 'Contains invalid characters',
          value: 'file<name>.txt',
        );

        // Assert
        failure.when(
          notFound: (_, __, ___) => fail('Should be validationError'),
          alreadyExists: (_, __, ___) => fail('Should be validationError'),
          validationError: (field, reason, value) {
            expect(value, equals('file<name>.txt'));
          },
          permissionDenied: (_, __, ___) => fail('Should be validationError'),
          syncError: (_, __, ___) => fail('Should be validationError'),
          unexpected: (_, __, ___) => fail('Should be validationError'),
        );
      });

      test('should have display message', () {
        // Arrange
        const failure = DomainFailure.validationError(
          field: 'fileName',
          reason: 'Contains invalid characters',
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, equals('Validation error in fileName: Contains invalid characters'));
      });
    });

    group('permissionDenied', () {
      test('should create permission denied failure', () {
        // Arrange & Act
        const failure = DomainFailure.permissionDenied(
          operation: 'delete',
          resource: '/system/file.txt',
        );

        // Assert
        failure.when(
          notFound: (_, __, ___) => fail('Should be permissionDenied'),
          alreadyExists: (_, __, ___) => fail('Should be permissionDenied'),
          validationError: (_, __, ___) => fail('Should be permissionDenied'),
          permissionDenied: (operation, resource, msg) {
            expect(operation, equals('delete'));
            expect(resource, equals('/system/file.txt'));
            expect(msg, isNull);
          },
          syncError: (_, __, ___) => fail('Should be permissionDenied'),
          unexpected: (_, __, ___) => fail('Should be permissionDenied'),
        );
      });

      test('should have default display message', () {
        // Arrange
        const failure = DomainFailure.permissionDenied(
          operation: 'delete',
          resource: '/system/file.txt',
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, equals('Permission denied for delete on /system/file.txt'));
      });
    });

    group('syncError', () {
      test('should create sync error failure', () {
        // Arrange & Act
        const failure = DomainFailure.syncError(
          operation: 'save',
        );

        // Assert
        failure.when(
          notFound: (_, __, ___) => fail('Should be syncError'),
          alreadyExists: (_, __, ___) => fail('Should be syncError'),
          validationError: (_, __, ___) => fail('Should be syncError'),
          permissionDenied: (_, __, ___) => fail('Should be syncError'),
          syncError: (operation, msg, cause) {
            expect(operation, equals('save'));
            expect(msg, isNull);
            expect(cause, isNull);
          },
          unexpected: (_, __, ___) => fail('Should be syncError'),
        );
      });

      test('should create sync error with cause', () {
        // Arrange
        final exception = Exception('Network error');

        // Act
        final failure = DomainFailure.syncError(
          operation: 'save',
          cause: exception,
        );

        // Assert
        failure.when(
          notFound: (_, __, ___) => fail('Should be syncError'),
          alreadyExists: (_, __, ___) => fail('Should be syncError'),
          validationError: (_, __, ___) => fail('Should be syncError'),
          permissionDenied: (_, __, ___) => fail('Should be syncError'),
          syncError: (operation, msg, cause) {
            expect(cause, equals(exception));
          },
          unexpected: (_, __, ___) => fail('Should be syncError'),
        );
      });

      test('should have display message', () {
        // Arrange
        const failure = DomainFailure.syncError(
          operation: 'save',
          message: 'Failed to sync',
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, equals('Failed to sync'));
      });
    });

    group('unexpected', () {
      test('should create unexpected failure', () {
        // Arrange & Act
        const failure = DomainFailure.unexpected(
          message: 'Something went wrong',
        );

        // Assert
        failure.when(
          notFound: (_, __, ___) => fail('Should be unexpected'),
          alreadyExists: (_, __, ___) => fail('Should be unexpected'),
          validationError: (_, __, ___) => fail('Should be unexpected'),
          permissionDenied: (_, __, ___) => fail('Should be unexpected'),
          syncError: (_, __, ___) => fail('Should be unexpected'),
          unexpected: (msg, cause, stackTrace) {
            expect(msg, equals('Something went wrong'));
            expect(cause, isNull);
            expect(stackTrace, isNull);
          },
        );
      });

      test('should create unexpected failure with cause and stack trace', () {
        // Arrange
        final exception = Exception('Error');
        final stackTrace = StackTrace.current;

        // Act
        final failure = DomainFailure.unexpected(
          message: 'Unexpected error',
          cause: exception,
          stackTrace: stackTrace,
        );

        // Assert
        failure.when(
          notFound: (_, __, ___) => fail('Should be unexpected'),
          alreadyExists: (_, __, ___) => fail('Should be unexpected'),
          validationError: (_, __, ___) => fail('Should be unexpected'),
          permissionDenied: (_, __, ___) => fail('Should be unexpected'),
          syncError: (_, __, ___) => fail('Should be unexpected'),
          unexpected: (msg, cause, st) {
            expect(cause, equals(exception));
            expect(st, equals(stackTrace));
          },
        );
      });

      test('should have display message', () {
        // Arrange
        const failure = DomainFailure.unexpected(
          message: 'Something went wrong',
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, equals('Something went wrong'));
      });
    });

    group('use cases', () {
      test('should handle file not found scenario', () {
        // Arrange
        const failure = DomainFailure.notFound(
          entityType: 'FileDocument',
          entityId: 'missing.dart',
          message: 'The file you are looking for does not exist',
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, contains('does not exist'));
      });

      test('should handle duplicate file scenario', () {
        // Arrange
        const failure = DomainFailure.alreadyExists(
          entityType: 'FileDocument',
          entityId: 'main.dart',
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, contains('already exists'));
      });

      test('should handle invalid file name scenario', () {
        // Arrange
        const failure = DomainFailure.validationError(
          field: 'fileName',
          reason: 'File name contains invalid characters',
          value: 'file<name>.dart',
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, contains('Validation error'));
        expect(message, contains('fileName'));
      });

      test('should handle permission denied scenario', () {
        // Arrange
        const failure = DomainFailure.permissionDenied(
          operation: 'write',
          resource: '/system/config.txt',
          message: 'You do not have permission to modify system files',
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, contains('permission'));
      });

      test('should handle sync error scenario', () {
        // Arrange
        final networkError = Exception('Network timeout');
        final failure = DomainFailure.syncError(
          operation: 'save',
          message: 'Failed to save file',
          cause: networkError,
        );

        // Act
        final message = failure.displayMessage;

        // Assert
        expect(message, equals('Failed to save file'));
        failure.when(
          notFound: (_, __, ___) => fail('Should be syncError'),
          alreadyExists: (_, __, ___) => fail('Should be syncError'),
          validationError: (_, __, ___) => fail('Should be syncError'),
          permissionDenied: (_, __, ___) => fail('Should be syncError'),
          syncError: (_, __, cause) {
            expect(cause, equals(networkError));
          },
          unexpected: (_, __, ___) => fail('Should be syncError'),
        );
      });
    });
  });
}
