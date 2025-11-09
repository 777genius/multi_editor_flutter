import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:lsp_application/lsp_application.dart';

class MockLspClientRepository extends Mock implements ILspClientRepository {}

void main() {
  late MockLspClientRepository mockLspRepo;
  late GetSignatureHelpUseCase useCase;

  setUp(() {
    mockLspRepo = MockLspClientRepository();
    useCase = GetSignatureHelpUseCase(mockLspRepo);
  });

  setUpAll(() {
    registerFallbackValue(LanguageId.dart);
    registerFallbackValue(DocumentUri.fromFilePath('/test.dart'));
    registerFallbackValue(SessionId.fromString('test-session'));
    registerFallbackValue(CursorPosition.create(line: 0, column: 0));
  });

  group('GetSignatureHelpUseCase', () {
    test('should return signature help successfully', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      final signatureHelp = SignatureHelp(
        signatures: [
          SignatureInformation(
            label: 'void print(Object? object)',
            documentation: 'Prints an object to the console',
            parameters: [
              ParameterInformation(
                label: 'object',
                documentation: 'The object to print',
              ),
            ],
          ),
        ],
        activeSignature: 0,
        activeParameter: 0,
      );

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getSignatureHelp(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            triggerCharacter: any(named: 'triggerCharacter'),
          )).thenAnswer((_) async => right(signatureHelp));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 10, column: 15),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (help) {
          expect(help.signatures.length, 1);
          expect(help.signatures.first.label, 'void print(Object? object)');
          expect(help.activeParameter, 0);
        },
      );
    });

    test('should pass trigger character when provided', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      final signatureHelp = SignatureHelp(
        signatures: [
          SignatureInformation(
            label: 'void foo(int a, String b)',
            parameters: [
              ParameterInformation(label: 'a'),
              ParameterInformation(label: 'b'),
            ],
          ),
        ],
        activeSignature: 0,
        activeParameter: 0,
      );

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getSignatureHelp(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            triggerCharacter: any(named: 'triggerCharacter'),
          )).thenAnswer((_) async => right(signatureHelp));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 10, column: 15),
        triggerCharacter: '(',
      );

      // Assert
      expect(result.isRight(), true);
      verify(() => mockLspRepo.getSignatureHelp(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            triggerCharacter: '(',
          )).called(1);
    });

    test('should handle multiple overloads', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      final signatureHelp = SignatureHelp(
        signatures: [
          SignatureInformation(
            label: 'int parseInt(String source)',
            parameters: [ParameterInformation(label: 'source')],
          ),
          SignatureInformation(
            label: 'int parseInt(String source, {int? radix})',
            parameters: [
              ParameterInformation(label: 'source'),
              ParameterInformation(label: 'radix'),
            ],
          ),
        ],
        activeSignature: 1,
        activeParameter: 1,
      );

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getSignatureHelp(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            triggerCharacter: any(named: 'triggerCharacter'),
          )).thenAnswer((_) async => right(signatureHelp));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 10, column: 15),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (help) {
          expect(help.signatures.length, 2);
          expect(help.activeSignature, 1);
          expect(help.activeParameter, 1);
        },
      );
    });

    test('should return empty when no signature help available', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      final emptySignatureHelp = SignatureHelp(
        signatures: [],
        activeSignature: 0,
        activeParameter: 0,
      );

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getSignatureHelp(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            triggerCharacter: any(named: 'triggerCharacter'),
          )).thenAnswer((_) async => right(emptySignatureHelp));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 10, column: 15),
      );

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (help) => expect(help.signatures.isEmpty, true),
      );
    });

    test('should return failure when session not found', () async {
      // Arrange
      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => left(LspFailure.sessionNotFound(
                message: 'Session not found',
              )));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 10, column: 15),
      );

      // Assert
      expect(result.isLeft(), true);
      verifyNever(() => mockLspRepo.getSignatureHelp(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            triggerCharacter: any(named: 'triggerCharacter'),
          ));
    });

    test('should handle LSP server error', () async {
      // Arrange
      final session = LspSession(
        id: SessionId.fromString('test-session'),
        languageId: LanguageId.dart,
        state: SessionState.initialized,
        rootUri: DocumentUri.fromFilePath('/project'),
        createdAt: DateTime.now(),
        initializedAt: DateTime.now(),
      );

      when(() => mockLspRepo.getSession(any()))
          .thenAnswer((_) async => right(session));

      when(() => mockLspRepo.getSignatureHelp(
            sessionId: any(named: 'sessionId'),
            documentUri: any(named: 'documentUri'),
            position: any(named: 'position'),
            triggerCharacter: any(named: 'triggerCharacter'),
          )).thenAnswer((_) async => left(const LspFailure.serverError(
                message: 'LSP server error',
              )));

      // Act
      final result = await useCase(
        languageId: LanguageId.dart,
        documentUri: DocumentUri.fromFilePath('/test.dart'),
        position: CursorPosition.create(line: 10, column: 15),
      );

      // Assert
      expect(result.isLeft(), true);
    });
  });
}
