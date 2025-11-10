import 'package:dartz/dartz.dart';
import 'package:editor_core/editor_core.dart';
import 'package:lsp_domain/lsp_domain.dart';

/// Use Case: Rename symbol across entire codebase.
///
/// This use case orchestrates symbol renaming through LSP server.
/// LSP handles finding all references and preparing workspace edits.
///
/// Flow:
/// 1. Validates that LSP session exists for the language
/// 2. Gets current cursor position from editor
/// 3. Requests rename from LSP server
/// 4. Applies workspace edits to all affected files
///
/// Example:
/// ```dart
/// final useCase = RenameSymbolUseCase(lspRepository, editorRepository);
///
/// final result = await useCase(
///   languageId: LanguageId.dart,
///   documentUri: DocumentUri.fromFilePath('/path/to/file.dart'),
///   position: CursorPosition.create(line: 10, column: 5),
///   newName: 'newVariableName',
/// );
///
/// result.fold(
///   (failure) => showError(failure),
///   (result) => showSuccess('Renamed ${result.changedFiles} files'),
/// );
/// ```
class RenameSymbolUseCase {
  final ILspClientRepository _lspRepository;
  final ICodeEditorRepository _editorRepository;

  const RenameSymbolUseCase(
    this._lspRepository,
    this._editorRepository,
  );

  /// Executes the use case.
  ///
  /// Parameters:
  /// - [languageId]: The programming language
  /// - [documentUri]: URI of the document
  /// - [position]: Position of the symbol to rename
  /// - [newName]: New name for the symbol
  ///
  /// Returns:
  /// - Right(RenameResult) on success
  /// - Left(LspFailure) on failure
  Future<Either<LspFailure, RenameResult>> call({
    required LanguageId languageId,
    required DocumentUri documentUri,
    required CursorPosition position,
    required String newName,
  }) async {
    // Validate new name
    if (newName.isEmpty || !_isValidIdentifier(newName)) {
      return left(const LspFailure.invalidParams(
        message: 'Invalid new name for symbol',
      ));
    }

    // Get LSP session
    final sessionResult = await _lspRepository.getSession(languageId);

    return sessionResult.fold(
      (failure) => left(failure),
      (session) async {
        // Validate session can handle requests
        if (!session.canHandleRequests) {
          return left(LspFailure.serverNotResponding(
            message: 'LSP session is not ready (state: ${session.state})',
          ));
        }

        // Get current document content and sync with LSP
        final contentResult = await _editorRepository.getContent();

        return contentResult.fold(
          (failure) => left(const LspFailure.unexpected(
            message: 'Failed to get document content from editor',
          )),
          (content) async {
            // Notify LSP about current document state
            await _lspRepository.notifyDocumentChanged(
              sessionId: session.id,
              documentUri: documentUri,
              content: content,
            );

            // Request rename from LSP
            final renameResult = await _lspRepository.rename(
              sessionId: session.id,
              documentUri: documentUri,
              position: position,
              newName: newName,
            );

            // Process workspace edits
            return renameResult.map((workspaceEdit) {
              // Count affected files
              final changedFiles = workspaceEdit.changes.length;
              final totalEdits = workspaceEdit.changes.values
                  .fold(0, (sum, edits) => sum + edits.length);

              return RenameResult(
                changedFiles: changedFiles,
                totalEdits: totalEdits,
                workspaceEdit: workspaceEdit,
              );
            });
          },
        );
      },
    );
  }

  /// Validates if a string is a valid identifier.
  ///
  /// Basic validation - LSP server will do full validation.
  bool _isValidIdentifier(String name) {
    // Allow letters, numbers, underscores
    // Must start with letter or underscore
    final regex = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
    return regex.hasMatch(name);
  }
}

/// Result of rename operation.
class RenameResult {
  final int changedFiles;
  final int totalEdits;
  final WorkspaceEdit workspaceEdit;

  const RenameResult({
    required this.changedFiles,
    required this.totalEdits,
    required this.workspaceEdit,
  });
}
