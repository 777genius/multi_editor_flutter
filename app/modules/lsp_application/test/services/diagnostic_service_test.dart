import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('DiagnosticService', () {
    late MockLspClientRepository mockLspRepository;
    late DiagnosticService service;
    late LspSession session;
    late DocumentUri documentUri;

    setUp(() {
      mockLspRepository = MockLspClientRepository();
      service = DiagnosticService(mockLspRepository);

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

    group('getDiagnostics', () {
      test('should get diagnostics successfully', () async {
        // Arrange
        final diagnostics = [
          Diagnostic(
            range: const Range(
              start: Position(line: 5, character: 0),
              end: Position(line: 5, character: 10),
            ),
            severity: DiagnosticSeverity.error,
            message: 'Undefined name',
          ),
          Diagnostic(
            range: const Range(
              start: Position(line: 10, character: 5),
              end: Position(line: 10, character: 15),
            ),
            severity: DiagnosticSeverity.warning,
            message: 'Unused variable',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        // Act
        final result = await service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (resultDiagnostics) {
            expect(resultDiagnostics.length, equals(2));
            expect(resultDiagnostics[0].severity, equals(DiagnosticSeverity.error));
            expect(resultDiagnostics[1].severity, equals(DiagnosticSeverity.warning));
          },
        );

        verify(() => mockLspRepository.getDiagnostics(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(1);
      });

      test('should return cached diagnostics on second call', () async {
        // Arrange
        final diagnostics = [
          Diagnostic(
            range: const Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 1, character: 5),
            ),
            severity: DiagnosticSeverity.error,
            message: 'Error',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        // Act
        final result1 = await service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );
        final result2 = await service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result1.isRight(), isTrue);
        expect(result2.isRight(), isTrue);

        // Should only call repository once (second call uses cache)
        verify(() => mockLspRepository.getDiagnostics(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(1);
      });

      test('should refresh when forceRefresh is true', () async {
        // Arrange
        final diagnostics = [
          Diagnostic(
            range: const Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 1, character: 5),
            ),
            severity: DiagnosticSeverity.error,
            message: 'Error',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        // Act
        await service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );
        await service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          forceRefresh: true,
        );

        // Assert
        verify(() => mockLspRepository.getDiagnostics(
              sessionId: session.id,
              documentUri: documentUri,
            )).called(2);
      });

      test('should emit diagnostic update event', () async {
        // Arrange
        final diagnostics = [
          Diagnostic(
            range: const Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 1, character: 5),
            ),
            severity: DiagnosticSeverity.error,
            message: 'Error',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        final events = <DiagnosticUpdate>[];
        final subscription = service.onDiagnosticsChanged.listen(events.add);

        // Act
        await service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(documentUri));
        expect(events[0].diagnostics.length, equals(1));

        await subscription.cancel();
      });

      test('should handle empty diagnostics', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right([]));

        // Act
        final result = await service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (diagnostics) => expect(diagnostics, isEmpty),
        );
      });

      test('should fail when session not found', () async {
        // Arrange
        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        // Act
        final result = await service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('getErrors', () {
      test('should filter only errors', () async {
        // Arrange
        final diagnostics = [
          Diagnostic(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'Error 1',
          ),
          Diagnostic(
            range: const Range(start: Position(line: 2, character: 0), end: Position(line: 2, character: 5)),
            severity: DiagnosticSeverity.warning,
            message: 'Warning 1',
          ),
          Diagnostic(
            range: const Range(start: Position(line: 3, character: 0), end: Position(line: 3, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'Error 2',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        // Act
        final result = await service.getErrors(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (errors) {
            expect(errors.length, equals(2));
            expect(errors.every((d) => d.isError), isTrue);
          },
        );
      });
    });

    group('getWarnings', () {
      test('should filter only warnings', () async {
        // Arrange
        final diagnostics = [
          Diagnostic(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'Error 1',
          ),
          Diagnostic(
            range: const Range(start: Position(line: 2, character: 0), end: Position(line: 2, character: 5)),
            severity: DiagnosticSeverity.warning,
            message: 'Warning 1',
          ),
          Diagnostic(
            range: const Range(start: Position(line: 3, character: 0), end: Position(line: 3, character: 5)),
            severity: DiagnosticSeverity.warning,
            message: 'Warning 2',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        // Act
        final result = await service.getWarnings(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (warnings) {
            expect(warnings.length, equals(2));
            expect(warnings.every((d) => d.isWarning), isTrue);
          },
        );
      });
    });

    group('getDiagnosticCounts', () {
      test('should count diagnostics by severity', () async {
        // Arrange
        final diagnostics = [
          Diagnostic(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'Error 1',
          ),
          Diagnostic(
            range: const Range(start: Position(line: 2, character: 0), end: Position(line: 2, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'Error 2',
          ),
          Diagnostic(
            range: const Range(start: Position(line: 3, character: 0), end: Position(line: 3, character: 5)),
            severity: DiagnosticSeverity.warning,
            message: 'Warning 1',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        // Act
        await service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        final counts = service.getDiagnosticCounts(documentUri: documentUri);

        // Assert
        expect(counts[DiagnosticSeverity.error], equals(2));
        expect(counts[DiagnosticSeverity.warning], equals(1));
      });
    });

    group('getErrorCount', () {
      test('should return error count', () async {
        // Arrange
        final diagnostics = [
          Diagnostic(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'Error 1',
          ),
          Diagnostic(
            range: const Range(start: Position(line: 2, character: 0), end: Position(line: 2, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'Error 2',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        // Act
        await service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        final count = service.getErrorCount(documentUri: documentUri);

        // Assert
        expect(count, equals(2));
      });
    });

    group('clearDiagnostics', () {
      test('should clear diagnostics for document', () async {
        // Arrange
        final diagnostics = [
          Diagnostic(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'Error',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        await service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Act
        service.clearDiagnostics(documentUri: documentUri);

        final count = service.getErrorCount(documentUri: documentUri);

        // Assert
        expect(count, equals(0));
      });

      test('should emit update event when cleared', () async {
        // Arrange
        final events = <DiagnosticUpdate>[];
        final subscription = service.onDiagnosticsChanged.listen(events.add);

        // Act
        service.clearDiagnostics(documentUri: documentUri);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(documentUri));
        expect(events[0].diagnostics, isEmpty);

        await subscription.cancel();
      });
    });

    group('cache generation', () {
      test('should invalidate in-flight requests after clear', () async {
        // Arrange
        final completer1 = Completer<Either<LspFailure, List<Diagnostic>>>();
        final completer2 = Completer<Either<LspFailure, List<Diagnostic>>>();

        final diagnostics1 = [
          Diagnostic(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'Old diagnostic',
          ),
        ];

        final diagnostics2 = [
          Diagnostic(
            range: const Range(start: Position(line: 2, character: 0), end: Position(line: 2, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'New diagnostic',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        var callCount = 0;
        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) {
          callCount++;
          if (callCount == 1) return completer1.future;
          return completer2.future;
        });

        // Act
        final future1 = service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          forceRefresh: true,
        );

        // Clear cache while first request is in flight
        service.clearDiagnostics(documentUri: documentUri);

        // Start second request
        final future2 = service.getDiagnostics(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          forceRefresh: true,
        );

        // Complete requests
        completer1.complete(right(diagnostics1));
        completer2.complete(right(diagnostics2));

        await future1;
        await future2;

        // Assert - should have diagnostics from second request only
        final count = service.getErrorCount(documentUri: documentUri);
        expect(count, equals(1));
      });
    });

    group('diagnosticsForDocument', () {
      test('should filter updates for specific document', () async {
        // Arrange
        final doc1 = DocumentUri.fromFilePath('/lib/file1.dart');
        final doc2 = DocumentUri.fromFilePath('/lib/file2.dart');

        final events = <DiagnosticUpdate>[];
        final subscription = service.diagnosticsForDocument(documentUri: doc1).listen(events.add);

        // Act
        service.clearDiagnostics(documentUri: doc1);
        service.clearDiagnostics(documentUri: doc2);

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, equals(1));
        expect(events[0].documentUri, equals(doc1));

        await subscription.cancel();
      });
    });

    group('getTotalDiagnosticCount', () {
      test('should return total count across all documents', () async {
        // Arrange
        final doc1 = DocumentUri.fromFilePath('/lib/file1.dart');
        final doc2 = DocumentUri.fromFilePath('/lib/file2.dart');

        final diagnostics1 = [
          Diagnostic(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'Error 1',
          ),
          Diagnostic(
            range: const Range(start: Position(line: 2, character: 0), end: Position(line: 2, character: 5)),
            severity: DiagnosticSeverity.error,
            message: 'Error 2',
          ),
        ];

        final diagnostics2 = [
          Diagnostic(
            range: const Range(start: Position(line: 1, character: 0), end: Position(line: 1, character: 5)),
            severity: DiagnosticSeverity.warning,
            message: 'Warning 1',
          ),
        ];

        when(() => mockLspRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: doc1,
            )).thenAnswer((_) async => right(diagnostics1));

        when(() => mockLspRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: doc2,
            )).thenAnswer((_) async => right(diagnostics2));

        // Act
        await service.getDiagnostics(languageId: LanguageId.dart, documentUri: doc1);
        await service.getDiagnostics(languageId: LanguageId.dart, documentUri: doc2);

        final total = service.getTotalDiagnosticCount();

        // Assert
        expect(total, equals(3));
      });
    });
  });
}
