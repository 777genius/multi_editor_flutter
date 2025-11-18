import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  group('ExecuteCodeActionUseCase', () {
    late MockLspClientRepository mockRepository;
    late ExecuteCodeActionUseCase useCase;
    late LspSession session;

    setUp(() {
      mockRepository = MockLspClientRepository();
      useCase = ExecuteCodeActionUseCase(mockRepository);

      session = LspSession(
        id: SessionId.generate(),
        languageId: LanguageId.dart,
        state: SessionState.ready,
        createdAt: DateTime.now(),
      );

      registerFallbackValue(SessionId.generate());
      registerFallbackValue(const CodeAction(
        title: 'Test action',
        kind: CodeActionKind.quickfix,
      ));
      registerFallbackValue(LanguageId.dart);
    });

    test('should execute code action successfully', () async {
      // Arrange
      const codeAction = CodeAction(
        title: 'Add import',
        kind: CodeActionKind.quickfix,
        edit: WorkspaceEdit(
          changes: {
            '/test/file.dart': [
              TextEdit(
                range: Range(
                  start: Position(line: 0, character: 0),
                  end: Position(line: 0, character: 0),
                ),
                newText: "import 'package:test/test.dart';\n",
              ),
            ],
          },
        ),
      );

      when(() => mockRepository.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockRepository.executeCodeAction(
            sessionId: any(named: 'sessionId'),
            codeAction: any(named: 'codeAction'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        codeAction: codeAction,
      );

      // Assert
      expect(result.isRight(), isTrue);

      verify(() => mockRepository.executeCodeAction(
            sessionId: session.id,
            codeAction: codeAction,
          )).called(1);
    });

    test('should handle different code action kinds', () async {
      // Arrange
      const refactorAction = CodeAction(
        title: 'Extract method',
        kind: CodeActionKind.refactor,
      );

      when(() => mockRepository.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockRepository.executeCodeAction(
            sessionId: any(named: 'sessionId'),
            codeAction: any(named: 'codeAction'),
          )).thenAnswer((_) async => right(unit));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        codeAction: refactorAction,
      );

      // Assert
      expect(result.isRight(), isTrue);
      verify(() => mockRepository.executeCodeAction(
            sessionId: session.id,
            codeAction: refactorAction,
          )).called(1);
    });

    test('should fail when session not ready', () async {
      // Arrange
      final notReadySession = session.copyWith(state: SessionState.initializing);

      const codeAction = CodeAction(
        title: 'Test action',
        kind: CodeActionKind.quickfix,
      );

      when(() => mockRepository.getSession(any()))
          .thenAnswer((_) async => right(notReadySession));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        codeAction: codeAction,
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

    test('should fail when execution fails', () async {
      // Arrange
      const codeAction = CodeAction(
        title: 'Invalid action',
        kind: CodeActionKind.quickfix,
      );

      when(() => mockRepository.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockRepository.executeCodeAction(
            sessionId: any(named: 'sessionId'),
            codeAction: any(named: 'codeAction'),
          )).thenAnswer(
        (_) async => left(const LspFailure.unexpected(
          message: 'Failed to apply edit',
        )),
      );

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        codeAction: codeAction,
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<_Unexpected>());
        },
        (_) => fail('Should not succeed'),
      );
    });
  });
}
