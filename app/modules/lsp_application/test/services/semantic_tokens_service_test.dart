import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('SemanticTokensService', () {
    late MockLspClientRepository mockLspRepository;
    late SemanticTokensService service;
    late LspSession session;
    late DocumentUri documentUri;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      service = SemanticTokensService(mockLspRepository);

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );

      documentUri = DocumentUri.fromFilePath('/lib/test.dart');

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(LanguageId.dart);
      registerFallbackValue(documentUri);
    });

    tearDown(() async {
      await service.dispose();
    });

    group('getSemanticTokens', () {
      test('should get semantic tokens successfully', () async {
        // Arrange
        final tokens = SemanticTokens(
          data: [0, 5, 3, 1, 0, 1, 10, 4, 2, 0],
          resultId: 'result-1',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(tokens));

        // Act
        final result = await service.getSemanticTokens(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultTokens) {
            expect(resultTokens.data.length, equals(10));
            expect(resultTokens.resultId, equals('result-1'));
          },
        );

        verify(() => mockLspRepository.getSemanticTokens(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(1);
      });

      test('should return cached tokens on second call', () async {
        // Arrange
        final tokens = SemanticTokens(
          data: [0, 5, 3, 1, 0],
          resultId: 'result-1',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(tokens));

        // Act
        await service.getSemanticTokens(languageId: LanguageId.dart, documentUri: documentUri);
        await service.getSemanticTokens(languageId: LanguageId.dart, documentUri: documentUri);

        // Assert
        verify(() => mockLspRepository.getSemanticTokens(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(1);
      });

      test('should return empty tokens when disabled', () async {
        // Arrange
        service.setEnabled(false);

        // Act
        final result = await service.getSemanticTokens(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (tokens) => expect(tokens.data, isEmpty),
        );

        verifyNever(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            ));
      });

      test('should emit update event', () async {
        // Arrange
        final tokens = SemanticTokens(
          data: [0, 5, 3, 1, 0],
          resultId: 'result-1',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(tokens));

        final events = <SemanticTokensUpdate>[];
        final subscription = service.onTokensChanged.listen(events.add);

        // Act
        await service.getSemanticTokens(languageId: LanguageId.dart, documentUri: documentUri);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(documentUri));
        expect(events[0].isDelta, isFalse);

        await subscription.cancel();
      });

      test('should refresh when forceRefresh is true', () async {
        // Arrange
        final tokens = SemanticTokens(
          data: [0, 5, 3, 1, 0],
          resultId: 'result-1',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(tokens));

        // Act
        await service.getSemanticTokens(languageId: LanguageId.dart, documentUri: documentUri);
        await service.getSemanticTokens(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          forceRefresh: true,
        );

        // Assert
        verify(() => mockLspRepository.getSemanticTokens(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(2);
      });

      test('should fail when session not found', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        // Act
        final result = await service.getSemanticTokens(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('getSemanticTokensDelta', () {
      test('should get semantic tokens delta successfully', () async {
        // Arrange
        final tokens = SemanticTokens(
          data: [0, 5, 3, 1, 0],
          resultId: 'result-2',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getSemanticTokensDelta(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              previousResultId: any(named: 'previousResultId'),
            )).thenAnswer((_) async => right(tokens));

        // Act
        final result = await service.getSemanticTokensDelta(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          previousResultId: 'result-1',
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultTokens) {
            expect(resultTokens.resultId, equals('result-2'));
          },
        );

        verify(() => mockLspRepository.getSemanticTokensDelta(
              sessionId: session.id,
              documentUri: documentUri,
              previousResultId: 'result-1',
            )).called(1);
      });

      test('should emit delta update event', () async {
        // Arrange
        final tokens = SemanticTokens(
          data: [0, 5, 3, 1, 0],
          resultId: 'result-2',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getSemanticTokensDelta(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
              previousResultId: any(named: 'previousResultId'),
            )).thenAnswer((_) async => right(tokens));

        final events = <SemanticTokensUpdate>[];
        final subscription = service.onTokensChanged.listen(events.add);

        // Act
        await service.getSemanticTokensDelta(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          previousResultId: 'result-1',
        );

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(documentUri));
        expect(events[0].isDelta, isTrue);

        await subscription.cancel();
      });

      test('should return empty when disabled', () async {
        // Arrange
        service.setEnabled(false);

        // Act
        final result = await service.getSemanticTokensDelta(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          previousResultId: 'result-1',
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (tokens) => expect(tokens.data, isEmpty),
        );
      });
    });

    group('refreshSemanticTokens', () {
      test('should force refresh tokens', () async {
        // Arrange
        final tokens = SemanticTokens(
          data: [0, 5, 3, 1, 0],
          resultId: 'result-1',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(tokens));

        await service.getSemanticTokens(languageId: LanguageId.dart, documentUri: documentUri);

        // Act
        final result = await service.refreshSemanticTokens(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result, isTrue);
        verify(() => mockLspRepository.getSemanticTokens(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(2);
      });
    });

    group('clearSemanticTokens', () {
      test('should clear tokens for document', () async {
        // Arrange
        final tokens = SemanticTokens(
          data: [0, 5, 3, 1, 0],
          resultId: 'result-1',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(tokens));

        await service.getSemanticTokens(languageId: LanguageId.dart, documentUri: documentUri);

        // Act
        service.clearSemanticTokens(documentUri: documentUri);

        // Assert
        expect(service.hasSemanticTokens(documentUri: documentUri), isFalse);
      });

      test('should emit update event when cleared', () async {
        // Arrange
        final events = <SemanticTokensUpdate>[];
        final subscription = service.onTokensChanged.listen(events.add);

        // Act
        service.clearSemanticTokens(documentUri: documentUri);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(documentUri));
        expect(events[0].tokens.data, isEmpty);

        await subscription.cancel();
      });
    });

    group('setEnabled', () {
      test('should clear all tokens when disabled', () async {
        // Arrange
        final tokens = SemanticTokens(
          data: [0, 5, 3, 1, 0],
          resultId: 'result-1',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(tokens));

        await service.getSemanticTokens(languageId: LanguageId.dart, documentUri: documentUri);

        // Act
        service.setEnabled(false);

        // Assert
        expect(service.isEnabled, isFalse);
        expect(service.hasSemanticTokens(documentUri: documentUri), isFalse);
      });

      test('should allow enabling again', () async {
        // Arrange
        service.setEnabled(false);

        // Act
        service.setEnabled(true);

        // Assert
        expect(service.isEnabled, isTrue);
      });
    });

    group('tokensForDocument', () {
      test('should filter updates for specific document', () async {
        // Arrange
        final doc1 = DocumentUri.fromFilePath('/lib/file1.dart');
        final doc2 = DocumentUri.fromFilePath('/lib/file2.dart');

        final events = <SemanticTokensUpdate>[];
        final subscription = service.tokensForDocument(documentUri: doc1).listen(events.add);

        // Act
        service.clearSemanticTokens(documentUri: doc1);
        service.clearSemanticTokens(documentUri: doc2);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(doc1));

        await subscription.cancel();
      });
    });

    group('getDocumentsWithSemanticTokens', () {
      test('should return all documents with tokens', () async {
        // Arrange
        final doc1 = DocumentUri.fromFilePath('/lib/file1.dart');
        final doc2 = DocumentUri.fromFilePath('/lib/file2.dart');

        final tokens = SemanticTokens(
          data: [0, 5, 3, 1, 0],
          resultId: 'result-1',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: doc1,
            )).thenAnswer((_) async => right(tokens));

        when(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: doc2,
            )).thenAnswer((_) async => right(tokens));

        // Act
        await service.getSemanticTokens(languageId: LanguageId.dart, documentUri: doc1);
        await service.getSemanticTokens(languageId: LanguageId.dart, documentUri: doc2);

        final documents = service.getDocumentsWithSemanticTokens();

        // Assert
        expect(documents.length, equals(2));
        expect(documents, contains(doc1));
        expect(documents, contains(doc2));
      });
    });

    group('hasSemanticTokens', () {
      test('should return true when tokens are cached', () async {
        // Arrange
        final tokens = SemanticTokens(
          data: [0, 5, 3, 1, 0],
          resultId: 'result-1',
        );

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(tokens));

        // Act
        await service.getSemanticTokens(languageId: LanguageId.dart, documentUri: documentUri);

        // Assert
        expect(service.hasSemanticTokens(documentUri: documentUri), isTrue);
      });

      test('should return false when tokens are not cached', () {
        // Assert
        expect(service.hasSemanticTokens(documentUri: documentUri), isFalse);
      });
    });

    group('cache generation', () {
      test('should invalidate in-flight requests after clear', () async {
        // Arrange
        final completer1 = Completer<Either<LspFailure, SemanticTokens>>();
        final completer2 = Completer<Either<LspFailure, SemanticTokens>>();

        final tokens1 = SemanticTokens(data: [0, 5, 3, 1, 0], resultId: 'old');
        final tokens2 = SemanticTokens(data: [1, 6, 4, 2, 1], resultId: 'new');

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        var callCount = 0;
        when(() => mockLspRepository.getSemanticTokens(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) {
          callCount++;
          if (callCount == 1) return completer1.future;
          return completer2.future;
        });

        // Act
        final future1 = service.getSemanticTokens(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          forceRefresh: true,
        );

        // Clear cache while first request is in flight
        service.clearSemanticTokens(documentUri: documentUri);

        // Start second request
        final future2 = service.getSemanticTokens(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          forceRefresh: true,
        );

        // Complete requests
        completer1.complete(right(tokens1));
        completer2.complete(right(tokens2));

        await future1;
        await future2;

        // Assert - should have tokens from second request only
        expect(service.hasSemanticTokens(documentUri: documentUri), isTrue);
      });
    });
  });
}
