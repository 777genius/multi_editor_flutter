import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('Location', () {
    late DocumentUri uri;
    late TextSelection range;

    setUp(() {
      uri = const DocumentUri('file:///test/main.dart');
      range = const TextSelection(
        start: CursorPosition(line: 10, column: 5),
        end: CursorPosition(line: 10, column: 15),
      );
    });

    group('creation', () {
      test('should create location with uri and range', () {
        // Act
        final location = Location(uri: uri, range: range);

        // Assert
        expect(location.uri, equals(uri));
        expect(location.range, equals(range));
      });

      test('should require both uri and range', () {
        // This test ensures both parameters are required (compile-time check)
        final location = Location(uri: uri, range: range);

        expect(location.uri, isNotNull);
        expect(location.range, isNotNull);
      });
    });

    group('equality', () {
      test('should be equal with same uri and range', () {
        final loc1 = Location(uri: uri, range: range);
        final loc2 = Location(uri: uri, range: range);

        expect(loc1, equals(loc2));
        expect(loc1.hashCode, equals(loc2.hashCode));
      });

      test('should not be equal with different uri', () {
        final loc1 = Location(uri: uri, range: range);
        final loc2 = Location(
          uri: const DocumentUri('file:///other/file.dart'),
          range: range,
        );

        expect(loc1, isNot(equals(loc2)));
      });

      test('should not be equal with different range', () {
        final loc1 = Location(uri: uri, range: range);
        final loc2 = Location(
          uri: uri,
          range: const TextSelection(
            start: CursorPosition(line: 20, column: 0),
            end: CursorPosition(line: 20, column: 10),
          ),
        );

        expect(loc1, isNot(equals(loc2)));
      });
    });

    group('copyWith', () {
      test('should copy with new uri', () {
        final location = Location(uri: uri, range: range);
        const newUri = DocumentUri('file:///new/file.dart');

        final copied = location.copyWith(uri: newUri);

        expect(copied.uri, equals(newUri));
        expect(copied.range, equals(location.range));
        expect(location.uri, equals(uri)); // immutability
      });

      test('should copy with new range', () {
        final location = Location(uri: uri, range: range);
        const newRange = TextSelection(
          start: CursorPosition(line: 100, column: 0),
          end: CursorPosition(line: 100, column: 20),
        );

        final copied = location.copyWith(range: newRange);

        expect(copied.range, equals(newRange));
        expect(copied.uri, equals(location.uri));
      });
    });

    group('use cases', () {
      test('should represent go to definition result', () {
        final location = Location(
          uri: const DocumentUri('file:///lib/utils.dart'),
          range: const TextSelection(
            start: CursorPosition(line: 45, column: 6),
            end: CursorPosition(line: 45, column: 16),
          ),
        );

        expect(location.uri.value, contains('utils.dart'));
        expect(location.range.start.line, equals(45));
      });

      test('should represent find references result', () {
        final location = Location(
          uri: const DocumentUri('file:///lib/main.dart'),
          range: const TextSelection(
            start: CursorPosition(line: 10, column: 2),
            end: CursorPosition(line: 10, column: 12),
          ),
        );

        expect(location.uri.value, contains('main.dart'));
      });

      test('should support same file locations', () {
        const sameFile = DocumentUri('file:///test.dart');

        final loc1 = Location(
          uri: sameFile,
          range: const TextSelection(
            start: CursorPosition(line: 5, column: 0),
            end: CursorPosition(line: 5, column: 10),
          ),
        );

        final loc2 = Location(
          uri: sameFile,
          range: const TextSelection(
            start: CursorPosition(line: 15, column: 0),
            end: CursorPosition(line: 15, column: 10),
          ),
        );

        expect(loc1.uri, equals(loc2.uri));
        expect(loc1.range, isNot(equals(loc2.range)));
      });

      test('should support cross-file references', () {
        final locations = [
          Location(
            uri: const DocumentUri('file:///lib/a.dart'),
            range: const TextSelection(
              start: CursorPosition(line: 1, column: 0),
              end: CursorPosition(line: 1, column: 5),
            ),
          ),
          Location(
            uri: const DocumentUri('file:///lib/b.dart'),
            range: const TextSelection(
              start: CursorPosition(line: 10, column: 0),
              end: CursorPosition(line: 10, column: 5),
            ),
          ),
          Location(
            uri: const DocumentUri('file:///lib/c.dart'),
            range: const TextSelection(
              start: CursorPosition(line: 20, column: 0),
              end: CursorPosition(line: 20, column: 5),
            ),
          ),
        ];

        expect(locations.length, equals(3));
        expect(locations.map((l) => l.uri).toSet().length, equals(3));
      });
    });

    group('comparison', () {
      test('should be sortable by line number', () {
        final loc1 = Location(
          uri: uri,
          range: const TextSelection(
            start: CursorPosition(line: 5, column: 0),
            end: CursorPosition(line: 5, column: 10),
          ),
        );

        final loc2 = Location(
          uri: uri,
          range: const TextSelection(
            start: CursorPosition(line: 10, column: 0),
            end: CursorPosition(line: 10, column: 10),
          ),
        );

        final loc3 = Location(
          uri: uri,
          range: const TextSelection(
            start: CursorPosition(line: 1, column: 0),
            end: CursorPosition(line: 1, column: 10),
          ),
        );

        final locations = [loc1, loc2, loc3];
        locations.sort((a, b) =>
          a.range.start.line.compareTo(b.range.start.line));

        expect(locations[0].range.start.line, equals(1));
        expect(locations[1].range.start.line, equals(5));
        expect(locations[2].range.start.line, equals(10));
      });
    });
  });
}
