import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('EditorEvent', () {
    late DocumentUri uri;

    setUp(() {
      uri = const DocumentUri('file:///test.dart');
    });

    group('contentChanged', () {
      test('should create content changed event', () {
        // Act
        final event = EditorEvent.contentChanged(
          documentUri: uri,
          newContent: 'new content',
        );

        // Assert
        event.when(
          contentChanged: (docUri, content) {
            expect(docUri, equals(uri));
            expect(content, equals('new content'));
          },
          cursorPositionChanged: (_, __) => fail('Wrong type'),
          selectionChanged: (_, __) => fail('Wrong type'),
          focusChanged: (_, __) => fail('Wrong type'),
          documentOpened: (_) => fail('Wrong type'),
          documentClosed: (_) => fail('Wrong type'),
          documentSaved: (_) => fail('Wrong type'),
        );
      });
    });

    group('cursorPositionChanged', () {
      test('should create cursor position changed event', () {
        // Arrange
        const position = CursorPosition(line: 5, column: 10);

        // Act
        final event = EditorEvent.cursorPositionChanged(
          documentUri: uri,
          position: position,
        );

        // Assert
        event.when(
          contentChanged: (_, __) => fail('Wrong type'),
          cursorPositionChanged: (docUri, pos) {
            expect(docUri, equals(uri));
            expect(pos, equals(position));
          },
          selectionChanged: (_, __) => fail('Wrong type'),
          focusChanged: (_, __) => fail('Wrong type'),
          documentOpened: (_) => fail('Wrong type'),
          documentClosed: (_) => fail('Wrong type'),
          documentSaved: (_) => fail('Wrong type'),
        );
      });
    });

    group('selectionChanged', () {
      test('should create selection changed event', () {
        // Arrange
        const selection = TextSelection(
          start: CursorPosition(line: 1, column: 0),
          end: CursorPosition(line: 5, column: 10),
        );

        // Act
        final event = EditorEvent.selectionChanged(
          documentUri: uri,
          selection: selection,
        );

        // Assert
        event.when(
          contentChanged: (_, __) => fail('Wrong type'),
          cursorPositionChanged: (_, __) => fail('Wrong type'),
          selectionChanged: (docUri, sel) {
            expect(docUri, equals(uri));
            expect(sel, equals(selection));
          },
          focusChanged: (_, __) => fail('Wrong type'),
          documentOpened: (_) => fail('Wrong type'),
          documentClosed: (_) => fail('Wrong type'),
          documentSaved: (_) => fail('Wrong type'),
        );
      });
    });

    group('focusChanged', () {
      test('should create focus changed event with focus gained', () {
        // Act
        final event = EditorEvent.focusChanged(
          documentUri: uri,
          hasFocus: true,
        );

        // Assert
        event.when(
          contentChanged: (_, __) => fail('Wrong type'),
          cursorPositionChanged: (_, __) => fail('Wrong type'),
          selectionChanged: (_, __) => fail('Wrong type'),
          focusChanged: (docUri, hasFocus) {
            expect(docUri, equals(uri));
            expect(hasFocus, isTrue);
          },
          documentOpened: (_) => fail('Wrong type'),
          documentClosed: (_) => fail('Wrong type'),
          documentSaved: (_) => fail('Wrong type'),
        );
      });

      test('should create focus changed event with focus lost', () {
        // Act
        final event = EditorEvent.focusChanged(
          documentUri: uri,
          hasFocus: false,
        );

        // Assert
        event.when(
          contentChanged: (_, __) => fail('Wrong type'),
          cursorPositionChanged: (_, __) => fail('Wrong type'),
          selectionChanged: (_, __) => fail('Wrong type'),
          focusChanged: (docUri, hasFocus) {
            expect(hasFocus, isFalse);
          },
          documentOpened: (_) => fail('Wrong type'),
          documentClosed: (_) => fail('Wrong type'),
          documentSaved: (_) => fail('Wrong type'),
        );
      });
    });

    group('documentOpened', () {
      test('should create document opened event', () {
        // Act
        final event = EditorEvent.documentOpened(documentUri: uri);

        // Assert
        event.when(
          contentChanged: (_, __) => fail('Wrong type'),
          cursorPositionChanged: (_, __) => fail('Wrong type'),
          selectionChanged: (_, __) => fail('Wrong type'),
          focusChanged: (_, __) => fail('Wrong type'),
          documentOpened: (docUri) {
            expect(docUri, equals(uri));
          },
          documentClosed: (_) => fail('Wrong type'),
          documentSaved: (_) => fail('Wrong type'),
        );
      });
    });

    group('documentClosed', () {
      test('should create document closed event', () {
        // Act
        final event = EditorEvent.documentClosed(documentUri: uri);

        // Assert
        event.when(
          contentChanged: (_, __) => fail('Wrong type'),
          cursorPositionChanged: (_, __) => fail('Wrong type'),
          selectionChanged: (_, __) => fail('Wrong type'),
          focusChanged: (_, __) => fail('Wrong type'),
          documentOpened: (_) => fail('Wrong type'),
          documentClosed: (docUri) {
            expect(docUri, equals(uri));
          },
          documentSaved: (_) => fail('Wrong type'),
        );
      });
    });

    group('documentSaved', () {
      test('should create document saved event', () {
        // Act
        final event = EditorEvent.documentSaved(documentUri: uri);

        // Assert
        event.when(
          contentChanged: (_, __) => fail('Wrong type'),
          cursorPositionChanged: (_, __) => fail('Wrong type'),
          selectionChanged: (_, __) => fail('Wrong type'),
          focusChanged: (_, __) => fail('Wrong type'),
          documentOpened: (_) => fail('Wrong type'),
          documentClosed: (_) => fail('Wrong type'),
          documentSaved: (docUri) {
            expect(docUri, equals(uri));
          },
        );
      });
    });

    group('equality', () {
      test('should be equal with same type and data', () {
        final event1 = EditorEvent.documentOpened(documentUri: uri);
        final event2 = EditorEvent.documentOpened(documentUri: uri);

        expect(event1, equals(event2));
      });

      test('should not be equal with different types', () {
        final event1 = EditorEvent.documentOpened(documentUri: uri);
        final event2 = EditorEvent.documentClosed(documentUri: uri);

        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal with different data', () {
        final event1 = EditorEvent.contentChanged(
          documentUri: uri,
          newContent: 'content 1',
        );

        final event2 = EditorEvent.contentChanged(
          documentUri: uri,
          newContent: 'content 2',
        );

        expect(event1, isNot(equals(event2)));
      });
    });

    group('pattern matching', () {
      test('should support maybeWhen', () {
        final event = EditorEvent.documentSaved(documentUri: uri);

        final result = event.maybeWhen(
          documentSaved: (docUri) => 'saved: ${docUri.fileName}',
          orElse: () => 'other',
        );

        expect(result, contains('saved'));
      });

      test('should call orElse for unhandled cases', () {
        final event = EditorEvent.documentOpened(documentUri: uri);

        final result = event.maybeWhen(
          documentSaved: (_) => 'saved',
          orElse: () => 'default',
        );

        expect(result, equals('default'));
      });
    });

    group('use cases', () {
      test('should represent editing workflow events', () {
        final events = [
          EditorEvent.documentOpened(documentUri: uri),
          EditorEvent.contentChanged(documentUri: uri, newContent: 'new'),
          EditorEvent.cursorPositionChanged(
            documentUri: uri,
            position: const CursorPosition(line: 0, column: 0),
          ),
          EditorEvent.documentSaved(documentUri: uri),
          EditorEvent.documentClosed(documentUri: uri),
        ];

        expect(events.length, equals(5));
      });

      test('should represent selection workflow', () {
        final events = [
          EditorEvent.focusChanged(documentUri: uri, hasFocus: true),
          EditorEvent.selectionChanged(
            documentUri: uri,
            selection: const TextSelection(
              start: CursorPosition(line: 0, column: 0),
              end: CursorPosition(line: 5, column: 10),
            ),
          ),
          EditorEvent.contentChanged(documentUri: uri, newContent: 'replaced'),
        ];

        expect(events.length, equals(3));
      });
    });
  });
}
