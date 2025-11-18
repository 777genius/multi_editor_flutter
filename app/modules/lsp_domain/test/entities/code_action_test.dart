import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('CodeAction', () {
    group('creation', () {
      test('should create code action with required fields', () {
        // Act
        const action = CodeAction(
          title: 'Quick fix',
          kind: CodeActionKind.quickFix,
        );

        // Assert
        expect(action.title, equals('Quick fix'));
        expect(action.kind, equals(CodeActionKind.quickFix));
        expect(action.diagnostics, isNull);
        expect(action.edit, isNull);
        expect(action.command, isNull);
        expect(action.isPreferred, isFalse);
      });

      test('should create code action with diagnostics', () {
        // Arrange
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
        final action = CodeAction(
          title: 'Fix error',
          kind: CodeActionKind.quickFix,
          diagnostics: diagnostics,
        );

        // Assert
        expect(action.diagnostics, isNotNull);
        expect(action.diagnostics!.length, equals(1));
      });

      test('should create code action with workspace edit', () {
        // Arrange
        const edit = WorkspaceEdit(
          changes: {
            DocumentUri('file:///test.dart'): [
              TextEdit(
                range: TextSelection(
                  start: CursorPosition(line: 1, column: 0),
                  end: CursorPosition(line: 1, column: 5),
                ),
                newText: 'fixed',
              ),
            ],
          },
        );

        // Act
        const action = CodeAction(
          title: 'Apply fix',
          kind: CodeActionKind.quickFix,
          edit: edit,
        );

        // Assert
        expect(action.edit, isNotNull);
        expect(action.edit!.changes.length, equals(1));
      });

      test('should create preferred code action', () {
        // Act
        const action = CodeAction(
          title: 'Preferred fix',
          kind: CodeActionKind.quickFix,
          isPreferred: true,
        );

        // Assert
        expect(action.isPreferred, isTrue);
      });
    });

    group('CodeActionKind', () {
      test('should have quick fix kind', () {
        expect(CodeActionKind.values, contains(CodeActionKind.quickFix));
      });

      test('should have refactoring kinds', () {
        expect(CodeActionKind.values, contains(CodeActionKind.refactor));
        expect(CodeActionKind.values, contains(CodeActionKind.refactorExtract));
        expect(CodeActionKind.values, contains(CodeActionKind.refactorInline));
        expect(CodeActionKind.values, contains(CodeActionKind.refactorRewrite));
      });

      test('should have source action kinds', () {
        expect(CodeActionKind.values, contains(CodeActionKind.source));
        expect(CodeActionKind.values, contains(CodeActionKind.sourceOrganizeImports));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        const action1 = CodeAction(
          title: 'Fix',
          kind: CodeActionKind.quickFix,
        );

        const action2 = CodeAction(
          title: 'Fix',
          kind: CodeActionKind.quickFix,
        );

        expect(action1, equals(action2));
      });

      test('should not be equal with different kind', () {
        const action1 = CodeAction(
          title: 'Action',
          kind: CodeActionKind.quickFix,
        );

        const action2 = CodeAction(
          title: 'Action',
          kind: CodeActionKind.refactor,
        );

        expect(action1, isNot(equals(action2)));
      });
    });

    group('common use cases', () {
      test('should represent organize imports action', () {
        const action = CodeAction(
          title: 'Organize Imports',
          kind: CodeActionKind.sourceOrganizeImports,
        );

        expect(action.kind, equals(CodeActionKind.sourceOrganizeImports));
        expect(action.title, contains('Organize'));
      });

      test('should represent extract method refactoring', () {
        const action = CodeAction(
          title: 'Extract Method',
          kind: CodeActionKind.refactorExtract,
        );

        expect(action.kind, equals(CodeActionKind.refactorExtract));
      });

      test('should represent inline refactoring', () {
        const action = CodeAction(
          title: 'Inline Variable',
          kind: CodeActionKind.refactorInline,
        );

        expect(action.kind, equals(CodeActionKind.refactorInline));
      });
    });
  });

  group('WorkspaceEdit', () {
    group('creation', () {
      test('should create empty workspace edit', () {
        // Act
        const edit = WorkspaceEdit();

        // Assert
        expect(edit.changes, isEmpty);
      });

      test('should create workspace edit with changes', () {
        // Act
        const edit = WorkspaceEdit(
          changes: {
            DocumentUri('file:///test1.dart'): [
              TextEdit(
                range: TextSelection(
                  start: CursorPosition(line: 1, column: 0),
                  end: CursorPosition(line: 1, column: 5),
                ),
                newText: 'new',
              ),
            ],
            DocumentUri('file:///test2.dart'): [
              TextEdit(
                range: TextSelection(
                  start: CursorPosition(line: 2, column: 0),
                  end: CursorPosition(line: 2, column: 10),
                ),
                newText: 'text',
              ),
            ],
          },
        );

        // Assert
        expect(edit.changes.length, equals(2));
        expect(edit.changes.keys, contains(const DocumentUri('file:///test1.dart')));
        expect(edit.changes.keys, contains(const DocumentUri('file:///test2.dart')));
      });
    });

    group('equality', () {
      test('should be equal with same changes', () {
        const edit1 = WorkspaceEdit(
          changes: {
            DocumentUri('file:///test.dart'): [
              TextEdit(
                range: TextSelection(
                  start: CursorPosition(line: 1, column: 0),
                  end: CursorPosition(line: 1, column: 5),
                ),
                newText: 'text',
              ),
            ],
          },
        );

        const edit2 = WorkspaceEdit(
          changes: {
            DocumentUri('file:///test.dart'): [
              TextEdit(
                range: TextSelection(
                  start: CursorPosition(line: 1, column: 0),
                  end: CursorPosition(line: 1, column: 5),
                ),
                newText: 'text',
              ),
            ],
          },
        );

        expect(edit1, equals(edit2));
      });

      test('should not be equal with different changes', () {
        const edit1 = WorkspaceEdit(
          changes: {
            DocumentUri('file:///test1.dart'): [],
          },
        );

        const edit2 = WorkspaceEdit(
          changes: {
            DocumentUri('file:///test2.dart'): [],
          },
        );

        expect(edit1, isNot(equals(edit2)));
      });
    });

    group('multi-file editing', () {
      test('should support edits across multiple files', () {
        const edit = WorkspaceEdit(
          changes: {
            DocumentUri('file:///file1.dart'): [
              TextEdit(
                range: TextSelection(
                  start: CursorPosition(line: 1, column: 0),
                  end: CursorPosition(line: 1, column: 0),
                ),
                newText: 'import \'package:test/test.dart\';\n',
              ),
            ],
            DocumentUri('file:///file2.dart'): [
              TextEdit(
                range: TextSelection(
                  start: CursorPosition(line: 5, column: 0),
                  end: CursorPosition(line: 5, column: 10),
                ),
                newText: 'newMethod',
              ),
            ],
            DocumentUri('file:///file3.dart'): [
              TextEdit(
                range: TextSelection(
                  start: CursorPosition(line: 10, column: 0),
                  end: CursorPosition(line: 15, column: 0),
                ),
                newText: '',
              ),
            ],
          },
        );

        expect(edit.changes.length, equals(3));
      });

      test('should support multiple edits per file', () {
        const edit = WorkspaceEdit(
          changes: {
            DocumentUri('file:///test.dart'): [
              TextEdit(
                range: TextSelection(
                  start: CursorPosition(line: 1, column: 0),
                  end: CursorPosition(line: 1, column: 0),
                ),
                newText: 'line 1\n',
              ),
              TextEdit(
                range: TextSelection(
                  start: CursorPosition(line: 5, column: 0),
                  end: CursorPosition(line: 5, column: 0),
                ),
                newText: 'line 5\n',
              ),
              TextEdit(
                range: TextSelection(
                  start: CursorPosition(line: 10, column: 0),
                  end: CursorPosition(line: 10, column: 0),
                ),
                newText: 'line 10\n',
              ),
            ],
          },
        );

        final editsForFile = edit.changes[const DocumentUri('file:///test.dart')]!;
        expect(editsForFile.length, equals(3));
      });
    });
  });
}
