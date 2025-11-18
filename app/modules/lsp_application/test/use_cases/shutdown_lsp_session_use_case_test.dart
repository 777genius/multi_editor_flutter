import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('ShutdownLspSessionUseCase', () {
    late MockLspClientRepository mockLspRepository;
    late ShutdownLspSessionUseCase useCase;
    late SessionId sessionId;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      useCase = ShutdownLspSessionUseCase(mockLspRepository);
      sessionId = SessionId.generate();

      registerFallbackValue(sessionId);
    });

    group('call', () {
      test('should shutdown session successfully', () async {
        // Arrange
        when(() => mockLspRepository.shutdown(any()))
            .thenAnswer((_) async => right(unit));

        // Act
        final result = await useCase(sessionId: sessionId);

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (value) => expect(value, equals(unit)),
        );

        verify(() => mockLspRepository.shutdown(sessionId)).called(1);
      });

      test('should fail when shutdown fails', () async {
        // Arrange
        when(() => mockLspRepository.shutdown(any()))
            .thenAnswer((_) async => left(const LspFailure.serverError(
              message: 'Failed to shutdown server',
            )));

        // Act
        final result = await useCase(sessionId: sessionId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<LspFailure>());
            expect(failure.message, contains('Failed to shutdown'));
          },
          (_) => fail('Should not succeed'),
        );

        verify(() => mockLspRepository.shutdown(sessionId)).called(1);
      });

      test('should fail when session not found', () async {
        // Arrange
        when(() => mockLspRepository.shutdown(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        // Act
        final result = await useCase(sessionId: sessionId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LspFailure>()),
          (_) => fail('Should not succeed'),
        );
      });

      test('should handle timeout error', () async {
        // Arrange
        when(() => mockLspRepository.shutdown(any()))
            .thenAnswer((_) async => left(const LspFailure.timeout(
              message: 'Shutdown timeout',
            )));

        // Act
        final result = await useCase(sessionId: sessionId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LspFailure>()),
          (_) => fail('Should not succeed'),
        );
      });

      test('should handle connection error', () async {
        // Arrange
        when(() => mockLspRepository.shutdown(any()))
            .thenAnswer((_) async => left(const LspFailure.connectionFailed(
              message: 'Connection lost',
            )));

        // Act
        final result = await useCase(sessionId: sessionId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LspFailure>()),
          (_) => fail('Should not succeed'),
        );
      });

      test('should be idempotent - calling twice should not fail', () async {
        // Arrange
        when(() => mockLspRepository.shutdown(any()))
            .thenAnswer((_) async => right(unit));

        // Act
        final result1 = await useCase(sessionId: sessionId);
        final result2 = await useCase(sessionId: sessionId);

        // Assert
        expect(result1.isRight(), isTrue);
        expect(result2.isRight(), isTrue);

        verify(() => mockLspRepository.shutdown(sessionId)).called(2);
      });

      test('should handle multiple session shutdowns', () async {
        // Arrange
        final session1 = SessionId.generate();
        final session2 = SessionId.generate();
        final session3 = SessionId.generate();

        when(() => mockLspRepository.shutdown(any()))
            .thenAnswer((_) async => right(unit));

        // Act
        final result1 = await useCase(sessionId: session1);
        final result2 = await useCase(sessionId: session2);
        final result3 = await useCase(sessionId: session3);

        // Assert
        expect(result1.isRight(), isTrue);
        expect(result2.isRight(), isTrue);
        expect(result3.isRight(), isTrue);

        verify(() => mockLspRepository.shutdown(session1)).called(1);
        verify(() => mockLspRepository.shutdown(session2)).called(1);
        verify(() => mockLspRepository.shutdown(session3)).called(1);
      });

      test('should handle unexpected error', () async {
        // Arrange
        when(() => mockLspRepository.shutdown(any()))
            .thenAnswer((_) async => left(const LspFailure.unexpected(
              message: 'Unexpected error occurred',
            )));

        // Act
        final result = await useCase(sessionId: sessionId);

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<LspFailure>());
            expect(failure.message, contains('Unexpected error'));
          },
          (_) => fail('Should not succeed'),
        );
      });
    });
  });
}
