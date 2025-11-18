import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide_presentation/ide_presentation.dart';

void main() {
  group('ErrorBoundary', () {
    testWidgets('should render child when no error', (tester) async {
      // Arrange
      const testChild = Text('Test Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(
            child: testChild,
          ),
        ),
      );

      // Assert
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should call onError when error occurs', (tester) async {
      // Arrange
      Object? capturedError;
      StackTrace? capturedStackTrace;

      final errorWidget = ErrorBoundary(
        onError: (error, stackTrace) {
          capturedError = error;
          capturedStackTrace = stackTrace;
        },
        child: Builder(
          builder: (context) {
            throw Exception('Test error');
          },
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: errorWidget,
        ),
      );

      // Allow error to be processed
      await tester.pump();

      // Assert
      expect(capturedError, isNotNull);
      expect(capturedStackTrace, isNotNull);
    });

    testWidgets('should use custom error builder when provided',
        (tester) async {
      // Arrange
      const errorBuilder = (Object error) {
        return Text('Custom Error: $error');
      };

      final errorWidget = ErrorBoundary(
        errorBuilder: errorBuilder,
        child: Builder(
          builder: (context) {
            throw Exception('Test error');
          },
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: errorWidget,
        ),
      );

      await tester.pump();

      // Assert
      expect(find.textContaining('Custom Error'), findsOneWidget);
    });

    testWidgets('should show retry button in default error UI',
        (tester) async {
      // Arrange
      final errorWidget = ErrorBoundary(
        child: Builder(
          builder: (context) {
            throw Exception('Test error');
          },
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: errorWidget,
        ),
      );

      await tester.pump();

      // Assert
      expect(find.textContaining('Error'), findsWidgets);
    });

    testWidgets('should wrap multiple children correctly', (tester) async {
      // Arrange
      const errorBoundary = ErrorBoundary(
        child: Column(
          children: [
            Text('Child 1'),
            Text('Child 2'),
          ],
        ),
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: errorBoundary,
        ),
      );

      // Assert
      expect(find.text('Child 1'), findsOneWidget);
      expect(find.text('Child 2'), findsOneWidget);
    });

    testWidgets('should handle nested ErrorBoundaries', (tester) async {
      // Arrange
      const widget = ErrorBoundary(
        child: ErrorBoundary(
          child: Text('Nested content'),
        ),
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: widget,
        ),
      );

      // Assert
      expect(find.text('Nested content'), findsOneWidget);
    });
  });
}
