import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('Diagnostic', () {
    late TextSelection range;
    late String message;

    setUp(() {
      range = const TextSelection(
        start: CursorPosition(line: 5, column: 10),
        end: CursorPosition(line: 5, column: 20),
      );
      message = 'Undefined name';
    });

    group('creation', () {
      test('should create diagnostic with required fields', () {
        // Act
        final diagnostic = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.error,
          message: message,
        );

        // Assert
        expect(diagnostic.range, equals(range));
        expect(diagnostic.severity, equals(DiagnosticSeverity.error));
        expect(diagnostic.message, equals(message));
        expect(diagnostic.code, isNull);
        expect(diagnostic.source, isNull);
      });

      test('should create diagnostic with all fields', () {
        // Act
        final diagnostic = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.warning,
          message: message,
          code: 'WARN001',
          source: 'dart-analyzer',
          relatedInformation: [
            DiagnosticRelatedInformation(
              uri: const DocumentUri('file:///related.dart'),
              range: range,
              message: 'Related info',
            ),
          ],
        );

        // Assert
        expect(diagnostic.code, equals('WARN001'));
        expect(diagnostic.source, equals('dart-analyzer'));
        expect(diagnostic.relatedInformation, isNotNull);
        expect(diagnostic.relatedInformation!.length, equals(1));
      });
    });

    group('severity checks', () {
      test('isError should return true for error severity', () {
        final diagnostic = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.error,
          message: message,
        );

        expect(diagnostic.isError, isTrue);
        expect(diagnostic.isWarning, isFalse);
        expect(diagnostic.isInfo, isFalse);
        expect(diagnostic.isHint, isFalse);
      });

      test('isWarning should return true for warning severity', () {
        final diagnostic = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.warning,
          message: message,
        );

        expect(diagnostic.isWarning, isTrue);
        expect(diagnostic.isError, isFalse);
        expect(diagnostic.isInfo, isFalse);
        expect(diagnostic.isHint, isFalse);
      });

      test('isInfo should return true for information severity', () {
        final diagnostic = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.information,
          message: message,
        );

        expect(diagnostic.isInfo, isTrue);
        expect(diagnostic.isError, isFalse);
        expect(diagnostic.isWarning, isFalse);
        expect(diagnostic.isHint, isFalse);
      });

      test('isHint should return true for hint severity', () {
        final diagnostic = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.hint,
          message: message,
        );

        expect(diagnostic.isHint, isTrue);
        expect(diagnostic.isError, isFalse);
        expect(diagnostic.isWarning, isFalse);
        expect(diagnostic.isInfo, isFalse);
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        final diagnostic1 = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.error,
          message: message,
        );

        final diagnostic2 = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.error,
          message: message,
        );

        expect(diagnostic1, equals(diagnostic2));
        expect(diagnostic1.hashCode, equals(diagnostic2.hashCode));
      });

      test('should not be equal with different severity', () {
        final diagnostic1 = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.error,
          message: message,
        );

        final diagnostic2 = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.warning,
          message: message,
        );

        expect(diagnostic1, isNot(equals(diagnostic2)));
      });

      test('should not be equal with different message', () {
        final diagnostic1 = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.error,
          message: 'Error 1',
        );

        final diagnostic2 = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.error,
          message: 'Error 2',
        );

        expect(diagnostic1, isNot(equals(diagnostic2)));
      });

      test('should not be equal with different range', () {
        final diagnostic1 = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.error,
          message: message,
        );

        final diagnostic2 = Diagnostic(
          range: const TextSelection(
            start: CursorPosition(line: 10, column: 0),
            end: CursorPosition(line: 10, column: 5),
          ),
          severity: DiagnosticSeverity.error,
          message: message,
        );

        expect(diagnostic1, isNot(equals(diagnostic2)));
      });
    });

    group('copyWith', () {
      test('should copy with new severity', () {
        final diagnostic = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.error,
          message: message,
        );

        final copied = diagnostic.copyWith(
          severity: DiagnosticSeverity.warning,
        );

        expect(copied.severity, equals(DiagnosticSeverity.warning));
        expect(copied.range, equals(diagnostic.range));
        expect(copied.message, equals(diagnostic.message));
      });

      test('should copy with new message', () {
        final diagnostic = Diagnostic(
          range: range,
          severity: DiagnosticSeverity.error,
          message: message,
        );

        final newMessage = 'New error message';
        final copied = diagnostic.copyWith(message: newMessage);

        expect(copied.message, equals(newMessage));
        expect(copied.severity, equals(diagnostic.severity));
      });
    });
  });

  group('DiagnosticRelatedInformation', () {
    test('should create with required fields', () {
      // Arrange
      const uri = DocumentUri('file:///main.dart');
      const range = TextSelection(
        start: CursorPosition(line: 1, column: 0),
        end: CursorPosition(line: 1, column: 10),
      );
      const message = 'See related code';

      // Act
      const info = DiagnosticRelatedInformation(
        uri: uri,
        range: range,
        message: message,
      );

      // Assert
      expect(info.uri, equals(uri));
      expect(info.range, equals(range));
      expect(info.message, equals(message));
    });

    test('should be equal with same data', () {
      const info1 = DiagnosticRelatedInformation(
        uri: DocumentUri('file:///main.dart'),
        range: TextSelection(
          start: CursorPosition(line: 1, column: 0),
          end: CursorPosition(line: 1, column: 10),
        ),
        message: 'Related',
      );

      const info2 = DiagnosticRelatedInformation(
        uri: DocumentUri('file:///main.dart'),
        range: TextSelection(
          start: CursorPosition(line: 1, column: 0),
          end: CursorPosition(line: 1, column: 10),
        ),
        message: 'Related',
      );

      expect(info1, equals(info2));
    });
  });

  group('DiagnosticSeverity', () {
    test('should have all severity levels', () {
      expect(DiagnosticSeverity.values.length, equals(4));
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.error));
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.warning));
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.information));
      expect(DiagnosticSeverity.values, contains(DiagnosticSeverity.hint));
    });
  });
}
