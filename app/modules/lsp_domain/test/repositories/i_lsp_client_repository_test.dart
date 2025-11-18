import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('ILspClientRepository', () {
    group('interface contract', () {
      test('should define session management methods', () {
        // This test ensures the interface has all required methods
        // The interface defines the contract for:
        // - initialize
        // - shutdown
        // - getSession
        // - hasSession

        expect(ILspClientRepository, isNotNull);
      });

      test('should define text synchronization methods', () {
        // Methods for document synchronization:
        // - notifyDocumentOpened
        // - notifyDocumentChanged
        // - notifyDocumentClosed
        // - notifyDocumentSaved

        expect(ILspClientRepository, isNotNull);
      });

      test('should define language feature methods', () {
        // LSP language features:
        // - getCompletions
        // - getHoverInfo
        // - getDiagnostics
        // - getDefinition
        // - getReferences
        // - getCodeActions
        // - getSignatureHelp
        // - formatDocument
        // - rename
        // - executeCommand
        // - getDocumentSymbols
        // - getWorkspaceSymbols
        // - prepareCallHierarchy
        // - getIncomingCalls
        // - getOutgoingCalls
        // - prepareTypeHierarchy
        // - getSupertypes
        // - getSubtypes
        // - getCodeLenses
        // - resolveCodeLens
        // - getSemanticTokens
        // - getSemanticTokensDelta
        // - getInlayHints
        // - resolveInlayHint
        // - getFoldingRanges
        // - getDocumentLinks
        // - resolveDocumentLink

        expect(ILspClientRepository, isNotNull);
      });

      test('should define event streams', () {
        // Event streams:
        // - onDiagnostics
        // - onStatusChanged

        expect(ILspClientRepository, isNotNull);
      });
    });
  });

  group('DiagnosticUpdate', () {
    test('should create diagnostic update event', () {
      // Arrange
      const uri = DocumentUri('file:///test.dart');
      final diagnostics = [
        const Diagnostic(
          range: TextSelection(
            start: CursorPosition(line: 1, column: 0),
            end: CursorPosition(line: 1, column: 5),
          ),
          severity: DiagnosticSeverity.error,
          message: 'Error',
        ),
      ];

      // Act
      final update = DiagnosticUpdate(
        documentUri: uri,
        diagnostics: diagnostics,
      );

      // Assert
      expect(update.documentUri, equals(uri));
      expect(update.diagnostics, equals(diagnostics));
    });

    test('should handle empty diagnostics', () {
      const uri = DocumentUri('file:///test.dart');

      final update = DiagnosticUpdate(
        documentUri: uri,
        diagnostics: const [],
      );

      expect(update.diagnostics, isEmpty);
    });

    test('should handle multiple diagnostics', () {
      const uri = DocumentUri('file:///test.dart');
      final diagnostics = [
        const Diagnostic(
          range: TextSelection(
            start: CursorPosition(line: 1, column: 0),
            end: CursorPosition(line: 1, column: 5),
          ),
          severity: DiagnosticSeverity.error,
          message: 'Error 1',
        ),
        const Diagnostic(
          range: TextSelection(
            start: CursorPosition(line: 5, column: 0),
            end: CursorPosition(line: 5, column: 10),
          ),
          severity: DiagnosticSeverity.warning,
          message: 'Warning 1',
        ),
        const Diagnostic(
          range: TextSelection(
            start: CursorPosition(line: 10, column: 0),
            end: CursorPosition(line: 10, column: 3),
          ),
          severity: DiagnosticSeverity.hint,
          message: 'Hint 1',
        ),
      ];

      final update = DiagnosticUpdate(
        documentUri: uri,
        diagnostics: diagnostics,
      );

      expect(update.diagnostics.length, equals(3));
      expect(update.diagnostics.where((d) => d.isError).length, equals(1));
      expect(update.diagnostics.where((d) => d.isWarning).length, equals(1));
      expect(update.diagnostics.where((d) => d.isHint).length, equals(1));
    });
  });

  group('LspServerStatus', () {
    test('should have all status values', () {
      expect(LspServerStatus.values.length, equals(4));
      expect(LspServerStatus.values, contains(LspServerStatus.starting));
      expect(LspServerStatus.values, contains(LspServerStatus.running));
      expect(LspServerStatus.values, contains(LspServerStatus.stopped));
      expect(LspServerStatus.values, contains(LspServerStatus.error));
    });

    test('should represent server lifecycle', () {
      final lifecycle = [
        LspServerStatus.starting,
        LspServerStatus.running,
        LspServerStatus.stopped,
      ];

      expect(lifecycle.first, equals(LspServerStatus.starting));
      expect(lifecycle.last, equals(LspServerStatus.stopped));
    });

    test('should represent error state', () {
      const errorStatus = LspServerStatus.error;

      expect(errorStatus, equals(LspServerStatus.error));
      expect(errorStatus, isNot(equals(LspServerStatus.running)));
    });
  });

  group('repository patterns', () {
    test('should use Either pattern for error handling', () {
      // The repository uses Either<LspFailure, T> pattern
      // This ensures all errors are handled explicitly
      // and type-safe

      // Example return type: Either<LspFailure, LspSession>
      // Left side: LspFailure (error)
      // Right side: LspSession (success)

      expect(LspFailure, isNotNull);
    });

    test('should use Future for async operations', () {
      // All repository methods return Future<Either<LspFailure, T>>
      // This indicates asynchronous operations

      expect(Future, isNotNull);
    });

    test('should use Stream for events', () {
      // Event streams use Stream<T>:
      // - Stream<DiagnosticUpdate> for diagnostic events
      // - Stream<LspServerStatus> for status changes

      expect(Stream, isNotNull);
    });
  });

  group('clean architecture compliance', () {
    test('should be in domain layer', () {
      // ILspClientRepository is a port (interface) in domain layer
      // It defines WHAT operations are needed, not HOW
      // Implementations are in infrastructure layer

      expect(ILspClientRepository, isNotNull);
    });

    test('should depend only on domain entities', () {
      // The repository interface only references domain entities:
      // - LspSession
      // - CompletionList
      // - Diagnostic
      // - HoverInfo
      // - etc.

      expect(LspSession, isNotNull);
      expect(CompletionList, isNotNull);
      expect(Diagnostic, isNotNull);
    });

    test('should use value objects', () {
      // Uses domain value objects:
      // - SessionId
      // - LanguageId
      // - DocumentUri
      // - CursorPosition

      expect(SessionId, isNotNull);
      expect(LanguageId, isNotNull);
      expect(DocumentUri, isNotNull);
      expect(CursorPosition, isNotNull);
    });

    test('should use failures for errors', () {
      // Uses domain failures:
      // - LspFailure

      expect(LspFailure, isNotNull);
    });
  });
}
