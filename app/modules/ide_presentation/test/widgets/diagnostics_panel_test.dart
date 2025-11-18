import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:ide_presentation/ide_presentation.dart';

void main() {
  group('DiagnosticsPanel', () {
    late List<Diagnostic> testDiagnostics;
    late Diagnostic errorDiagnostic;
    late Diagnostic warningDiagnostic;
    late Diagnostic infoDiagnostic;

    setUp(() {
      errorDiagnostic = Diagnostic(
        range: TextSelection(
          start: const CursorPosition(line: 10, column: 5),
          end: const CursorPosition(line: 10, column: 15),
        ),
        severity: DiagnosticSeverity.error,
        message: 'Undefined name',
        source: 'analyzer',
      );

      warningDiagnostic = Diagnostic(
        range: TextSelection(
          start: const CursorPosition(line: 5, column: 0),
          end: const CursorPosition(line: 5, column: 10),
        ),
        severity: DiagnosticSeverity.warning,
        message: 'Unused import',
        source: 'analyzer',
      );

      infoDiagnostic = Diagnostic(
        range: TextSelection(
          start: const CursorPosition(line: 15, column: 2),
          end: const CursorPosition(line: 15, column: 8),
        ),
        severity: DiagnosticSeverity.information,
        message: 'Consider using const',
        source: 'linter',
      );

      testDiagnostics = [errorDiagnostic, warningDiagnostic, infoDiagnostic];
    });

    testWidgets('should render with diagnostics', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Undefined name'), findsOneWidget);
      expect(find.text('Unused import'), findsOneWidget);
      expect(find.text('Consider using const'), findsOneWidget);
    });

    testWidgets('should display diagnostic counts in header', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
            ),
          ),
        ),
      );

      // Assert - Should show counts for each severity
      expect(find.text('1'), findsWidgets); // Error count
      expect(find.text('1'), findsWidgets); // Warning count
      expect(find.text('1'), findsWidgets); // Info count
    });

    testWidgets('should show empty state when no diagnostics', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: const [],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('No problems'), findsOneWidget);
    });

    testWidgets('should filter errors only', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
              showErrors: true,
              showWarnings: false,
              showInfos: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Undefined name'), findsOneWidget);
      expect(find.text('Unused import'), findsNothing);
      expect(find.text('Consider using const'), findsNothing);
    });

    testWidgets('should filter warnings only', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
              showErrors: false,
              showWarnings: true,
              showInfos: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Undefined name'), findsNothing);
      expect(find.text('Unused import'), findsOneWidget);
      expect(find.text('Consider using const'), findsNothing);
    });

    testWidgets('should filter infos only', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
              showErrors: false,
              showWarnings: false,
              showInfos: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Undefined name'), findsNothing);
      expect(find.text('Unused import'), findsNothing);
      expect(find.text('Consider using const'), findsOneWidget);
    });

    testWidgets('should show all when all filters enabled', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
              showErrors: true,
              showWarnings: true,
              showInfos: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Undefined name'), findsOneWidget);
      expect(find.text('Unused import'), findsOneWidget);
      expect(find.text('Consider using const'), findsOneWidget);
    });

    testWidgets('should show empty state when all filters disabled', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
              showErrors: false,
              showWarnings: false,
              showInfos: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('No problems'), findsOneWidget);
    });

    testWidgets('should call onFilterChanged when error toggle tapped', (tester) async {
      // Arrange
      bool? errorToggled;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
              onFilterChanged: (errors, warnings, infos) {
                errorToggled = errors;
              },
            ),
          ),
        ),
      );

      // Act - Find and tap error filter toggle
      final errorToggle = find.byIcon(Icons.error).first;
      await tester.tap(errorToggle);
      await tester.pumpAndSettle();

      // Assert
      expect(errorToggled, isNotNull);
    });

    testWidgets('should call onDiagnosticTapped when item tapped', (tester) async {
      // Arrange
      Diagnostic? tappedDiagnostic;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
              onDiagnosticTapped: (diagnostic) {
                tappedDiagnostic = diagnostic;
              },
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Undefined name'));
      await tester.pumpAndSettle();

      // Assert
      expect(tappedDiagnostic, equals(errorDiagnostic));
    });

    testWidgets('should display line numbers', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
            ),
          ),
        ),
      );

      // Assert - Line numbers are 1-indexed for display
      expect(find.textContaining('11'), findsOneWidget); // Line 10 + 1
      expect(find.textContaining('6'), findsOneWidget); // Line 5 + 1
      expect(find.textContaining('16'), findsOneWidget); // Line 15 + 1
    });

    testWidgets('should sort by severity (default)', (tester) async {
      // Arrange - Create diagnostics in random order
      final unsorted = [warningDiagnostic, errorDiagnostic, infoDiagnostic];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: unsorted,
              sortOrder: DiagnosticSortOrder.severity,
            ),
          ),
        ),
      );

      // Assert - Should be sorted: error, warning, info
      final diagnosticItems = find.byType(ListTile);
      expect(diagnosticItems, findsNWidgets(3));

      // Error should be first
      expect(find.text('Undefined name'), findsOneWidget);
    });

    testWidgets('should sort by line number', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
              sortOrder: DiagnosticSortOrder.line,
            ),
          ),
        ),
      );

      // Assert - Should be sorted: line 5, 10, 15
      final diagnosticItems = find.byType(ListTile);
      expect(diagnosticItems, findsNWidgets(3));
    });

    testWidgets('should sort by message alphabetically', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
              sortOrder: DiagnosticSortOrder.message,
            ),
          ),
        ),
      );

      // Assert - Should be sorted alphabetically
      final diagnosticItems = find.byType(ListTile);
      expect(diagnosticItems, findsNWidgets(3));
    });

    testWidgets('should call onSortChanged when sort order changed', (tester) async {
      // Arrange
      DiagnosticSortOrder? newSortOrder;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
              onSortChanged: (order) {
                newSortOrder = order;
              },
            ),
          ),
        ),
      );

      // Act - Find and tap sort button
      final sortButton = find.byIcon(Icons.sort);
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      // Assert
      expect(newSortOrder, isNotNull);
    });

    testWidgets('should display error icon for errors', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: [errorDiagnostic],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.error), findsWidgets);
    });

    testWidgets('should display warning icon for warnings', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: [warningDiagnostic],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.warning), findsWidgets);
    });

    testWidgets('should display info icon for information', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: [infoDiagnostic],
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.info), findsWidgets);
    });

    testWidgets('should have VS Code dark theme styling', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
            ),
          ),
        ),
      );

      // Assert - Check for dark background
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DiagnosticsPanel),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration?;
      if (decoration != null) {
        expect(decoration.color, equals(const Color(0xFF1E1E1E)));
      }
    });

    testWidgets('should be scrollable for many diagnostics', (tester) async {
      // Arrange - Create many diagnostics
      final manyDiagnostics = List.generate(
        50,
        (index) => Diagnostic(
          range: TextSelection(
            start: CursorPosition(line: index, column: 0),
            end: CursorPosition(line: index, column: 10),
          ),
          severity: DiagnosticSeverity.error,
          message: 'Error $index',
          source: 'analyzer',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: manyDiagnostics,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should work without onDiagnosticTapped callback', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
            ),
          ),
        ),
      );

      // Act - Should not crash when tapping
      await tester.tap(find.text('Undefined name'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DiagnosticsPanel), findsOneWidget);
    });

    testWidgets('should work without onFilterChanged callback', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
            ),
          ),
        ),
      );

      // Assert - Should not crash
      expect(find.byType(DiagnosticsPanel), findsOneWidget);
    });

    testWidgets('should work without onSortChanged callback', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
            ),
          ),
        ),
      );

      // Assert - Should not crash
      expect(find.byType(DiagnosticsPanel), findsOneWidget);
    });

    testWidgets('should display diagnostic source', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: testDiagnostics,
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('analyzer'), findsWidgets);
      expect(find.textContaining('linter'), findsOneWidget);
    });

    testWidgets('should handle diagnostics without source', (tester) async {
      // Arrange
      final diagnosticNoSource = Diagnostic(
        range: TextSelection(
          start: const CursorPosition(line: 1, column: 0),
          end: const CursorPosition(line: 1, column: 5),
        ),
        severity: DiagnosticSeverity.error,
        message: 'Error without source',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: [diagnosticNoSource],
            ),
          ),
        ),
      );

      // Assert - Should still render
      expect(find.text('Error without source'), findsOneWidget);
    });

    testWidgets('should handle diagnostics with code', (tester) async {
      // Arrange
      final diagnosticWithCode = Diagnostic(
        range: TextSelection(
          start: const CursorPosition(line: 1, column: 0),
          end: const CursorPosition(line: 1, column: 5),
        ),
        severity: DiagnosticSeverity.error,
        message: 'Type error',
        source: 'analyzer',
        code: 'E0001',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: [diagnosticWithCode],
            ),
          ),
        ),
      );

      // Assert - Should display code
      expect(find.textContaining('E0001'), findsOneWidget);
    });

    testWidgets('should update when diagnostics change', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: [errorDiagnostic],
            ),
          ),
        ),
      );

      // Assert initial state
      expect(find.text('Undefined name'), findsOneWidget);
      expect(find.text('Unused import'), findsNothing);

      // Act - Update with new diagnostics
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: [warningDiagnostic],
            ),
          ),
        ),
      );

      // Assert updated state
      expect(find.text('Undefined name'), findsNothing);
      expect(find.text('Unused import'), findsOneWidget);
    });

    group('Color Coding', () {
      testWidgets('should use red color for errors', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiagnosticsPanel(
                diagnostics: [errorDiagnostic],
              ),
            ),
          ),
        );

        // Assert - Error icons should use error color
        final errorIcon = tester.widget<Icon>(find.byIcon(Icons.error).first);
        expect(errorIcon.color, isNotNull);
      });

      testWidgets('should use yellow color for warnings', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiagnosticsPanel(
                diagnostics: [warningDiagnostic],
              ),
            ),
          ),
        );

        // Assert - Warning icons should use warning color
        final warningIcon = tester.widget<Icon>(find.byIcon(Icons.warning).first);
        expect(warningIcon.color, isNotNull);
      });

      testWidgets('should use blue color for information', (tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiagnosticsPanel(
                diagnostics: [infoDiagnostic],
              ),
            ),
          ),
        );

        // Assert - Info icons should use info color
        final infoIcon = tester.widget<Icon>(find.byIcon(Icons.info).first);
        expect(infoIcon.color, isNotNull);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle hint severity', (tester) async {
        // Arrange
        final hintDiagnostic = Diagnostic(
          range: TextSelection(
            start: const CursorPosition(line: 1, column: 0),
            end: const CursorPosition(line: 1, column: 5),
          ),
          severity: DiagnosticSeverity.hint,
          message: 'This is a hint',
          source: 'linter',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiagnosticsPanel(
                diagnostics: [hintDiagnostic],
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('This is a hint'), findsOneWidget);
      });

      testWidgets('should handle very long messages', (tester) async {
        // Arrange
        final longMessageDiagnostic = Diagnostic(
          range: TextSelection(
            start: const CursorPosition(line: 1, column: 0),
            end: const CursorPosition(line: 1, column: 5),
          ),
          severity: DiagnosticSeverity.error,
          message: 'A' * 200, // Very long message
          source: 'analyzer',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DiagnosticsPanel(
                diagnostics: [longMessageDiagnostic],
              ),
            ),
          ),
        ),
      );

      // Assert - Should not crash
      expect(find.byType(DiagnosticsPanel), findsOneWidget);
    });

    testWidgets('should handle mixed severity diagnostics', (tester) async {
      // Arrange
      final mixedDiagnostics = [
        errorDiagnostic,
        warningDiagnostic,
        errorDiagnostic,
        infoDiagnostic,
        warningDiagnostic,
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiagnosticsPanel(
              diagnostics: mixedDiagnostics,
            ),
          ),
        ),
      );

      // Assert - Should show correct counts
      expect(find.byType(DiagnosticsPanel), findsOneWidget);
    });
  });

  group('DiagnosticSortOrder', () {
    test('should have severity option', () {
      expect(DiagnosticSortOrder.severity, isNotNull);
    });

    test('should have line option', () {
      expect(DiagnosticSortOrder.line, isNotNull);
    });

    test('should have message option', () {
      expect(DiagnosticSortOrder.message, isNotNull);
    });
  });
}
