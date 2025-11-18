import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('GetDiagnosticsUseCase', () {
    late MockLspClientRepository mockRepository;
    late GetDiagnosticsUseCase useCase;
    late LspSession session;
    late DocumentUri documentUri;

    setUp(() {
      mockRepository = MockLspClientRepository();
      useCase = GetDiagnosticsUseCase(mockRepository);

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );
      documentUri = DocumentUri.fromFilePath('/test/file.dart');

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(documentUri);
      registerFallbackValue(LanguageId.dart);
    });

    group('call', () {
      test('should get diagnostics successfully', () async {
        // Arrange
        final diagnostics = [
          const Diagnostic(
            range: Range(
              start: Position(line: 0, character: 0),
              end: Position(line: 0, character: 10),
            ),
            message: 'Test error',
            severity: DiagnosticSeverity.error,
          ),
          const Diagnostic(
            range: Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 1, character: 5),
            ),
            message: 'Test warning',
            severity: DiagnosticSeverity.warning,
          ),
        ];

        when(() => mockRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (diags) {
            expect(diags.length, equals(2));
            expect(diags[0].severity, equals(DiagnosticSeverity.error));
            expect(diags[1].severity, equals(DiagnosticSeverity.warning));
          },
        );
      });

      test('should filter diagnostics by severity', () async {
        // Arrange
        final diagnostics = [
          const Diagnostic(
            range: Range(
              start: Position(line: 0, character: 0),
              end: Position(line: 0, character: 10),
            ),
            message: 'Error 1',
            severity: DiagnosticSeverity.error,
          ),
          const Diagnostic(
            range: Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 1, character: 5),
            ),
            message: 'Warning 1',
            severity: DiagnosticSeverity.warning,
          ),
          const Diagnostic(
            range: Range(
              start: Position(line: 2, character: 0),
              end: Position(line: 2, character: 5),
            ),
            message: 'Error 2',
            severity: DiagnosticSeverity.error,
          ),
        ];

        when(() => mockRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
          severityFilter: DiagnosticSeverity.error,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (diags) {
            expect(diags.length, equals(2));
            expect(diags.every((d) => d.severity == DiagnosticSeverity.error), isTrue);
          },
        );
      });

      test('should fail when session not ready', () async {
        // Arrange
        final notReadySession = session.copyWith(state: SessionState.initializing);

        when(() => mockRepository.getSession(any()))
            .thenAnswer((_) async => right(notReadySession));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<_ServerNotResponding>());
          },
          (_) => fail('Should not succeed'),
        );
      });

      test('should fail when session not found', () async {
        // Arrange
        when(() => mockRepository.getSession(any()))
            .thenAnswer((_) async => left(const LspFailure.sessionNotFound()));

        // Act
        final result = await useCase(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('getErrors', () {
      test('should get only errors', () async {
        // Arrange
        final diagnostics = [
          const Diagnostic(
            range: Range(
              start: Position(line: 0, character: 0),
              end: Position(line: 0, character: 10),
            ),
            message: 'Error',
            severity: DiagnosticSeverity.error,
          ),
          const Diagnostic(
            range: Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 1, character: 5),
            ),
            message: 'Warning',
            severity: DiagnosticSeverity.warning,
          ),
        ];

        when(() => mockRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        // Act
        final result = await useCase.getErrors(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (diags) {
            expect(diags.length, equals(1));
            expect(diags[0].severity, equals(DiagnosticSeverity.error));
          },
        );
      });
    });

    group('getWarnings', () {
      test('should get only warnings', () async {
        // Arrange
        final diagnostics = [
          const Diagnostic(
            range: Range(
              start: Position(line: 0, character: 0),
              end: Position(line: 0, character: 10),
            ),
            message: 'Error',
            severity: DiagnosticSeverity.error,
          ),
          const Diagnostic(
            range: Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 1, character: 5),
            ),
            message: 'Warning',
            severity: DiagnosticSeverity.warning,
          ),
        ];

        when(() => mockRepository.getSession(any()))
            .thenAnswer((_) async => right(session));

        when(() => mockRepository.getDiagnostics(
              sessionId: any(named: 'sessionId'),
              documentUri: any(named: 'documentUri'),
            )).thenAnswer((_) async => right(diagnostics));

        // Act
        final result = await useCase.getWarnings(
          languageId: LanguageId.dart,
          documentUri: documentUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (diags) {
            expect(diags.length, equals(1));
            expect(diags[0].severity, equals(DiagnosticSeverity.warning));
          },
        );
      });
    });
  });
}
