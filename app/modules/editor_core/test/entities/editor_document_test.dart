import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('EditorDocument', () {
    late DocumentUri uri;
    late LanguageId languageId;
    late String content;
    late DateTime lastModified;

    setUp(() {
      uri = const DocumentUri('file:///test/main.dart');
      languageId = const LanguageId('dart');
      content = 'void main() {\n  print("Hello");\n}';
      lastModified = DateTime.now();
    });

    group('creation', () {
      test('should create document with required fields', () {
        // Act
        final document = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
        );

        // Assert
        expect(document.uri, equals(uri));
        expect(document.content, equals(content));
        expect(document.languageId, equals(languageId));
        expect(document.lastModified, equals(lastModified));
        expect(document.isDirty, isFalse);
        expect(document.isReadOnly, isFalse);
      });

      test('should create dirty document', () {
        // Act
        final document = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
          isDirty: true,
        );

        // Assert
        expect(document.isDirty, isTrue);
      });

      test('should create read-only document', () {
        // Act
        final document = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
          isReadOnly: true,
        );

        // Assert
        expect(document.isReadOnly, isTrue);
      });
    });

    group('updateContent', () {
      test('should update content and mark as dirty', () {
        // Arrange
        final document = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
          isDirty: false,
        );

        // Act
        final updatedDocument = document.updateContent('new content');

        // Assert
        expect(updatedDocument.content, equals('new content'));
        expect(updatedDocument.isDirty, isTrue);
        expect(updatedDocument.lastModified.isAfter(lastModified), isTrue);
        expect(document.content, equals(content)); // immutability
      });

      test('should update lastModified timestamp', () {
        // Arrange
        final document = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
        );

        // Act
        final before = DateTime.now();
        final updatedDocument = document.updateContent('new');
        final after = DateTime.now();

        // Assert
        expect(
          updatedDocument.lastModified.isAfter(before) ||
          updatedDocument.lastModified.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          updatedDocument.lastModified.isBefore(after) ||
          updatedDocument.lastModified.isAtSameMomentAs(after),
          isTrue,
        );
      });

      test('should preserve other properties', () {
        // Arrange
        final document = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
          isReadOnly: true,
        );

        // Act
        final updated = document.updateContent('new');

        // Assert
        expect(updated.uri, equals(document.uri));
        expect(updated.languageId, equals(document.languageId));
        expect(updated.isReadOnly, equals(document.isReadOnly));
      });
    });

    group('markAsSaved', () {
      test('should mark document as not dirty', () {
        // Arrange
        final document = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
          isDirty: true,
        );

        // Act
        final savedDocument = document.markAsSaved();

        // Assert
        expect(savedDocument.isDirty, isFalse);
        expect(document.isDirty, isTrue); // immutability
      });

      test('should update lastModified timestamp', () {
        // Arrange
        final document = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
          isDirty: true,
        );

        // Act
        final savedDocument = document.markAsSaved();

        // Assert
        expect(savedDocument.lastModified.isAfter(lastModified), isTrue);
      });
    });

    group('lineCount', () {
      test('should count lines correctly', () {
        expect(
          EditorDocument(
            uri: uri,
            content: 'line 1\nline 2\nline 3',
            languageId: languageId,
            lastModified: lastModified,
          ).lineCount,
          equals(3),
        );
      });

      test('should return 1 for empty content', () {
        expect(
          EditorDocument(
            uri: uri,
            content: '',
            languageId: languageId,
            lastModified: lastModified,
          ).lineCount,
          equals(1),
        );
      });

      test('should return 1 for single line', () {
        expect(
          EditorDocument(
            uri: uri,
            content: 'single line',
            languageId: languageId,
            lastModified: lastModified,
          ).lineCount,
          equals(1),
        );
      });

      test('should handle trailing newline', () {
        expect(
          EditorDocument(
            uri: uri,
            content: 'line 1\nline 2\n',
            languageId: languageId,
            lastModified: lastModified,
          ).lineCount,
          equals(3), // Counts empty line after trailing newline
        );
      });

      test('should handle multiple consecutive newlines', () {
        expect(
          EditorDocument(
            uri: uri,
            content: 'line 1\n\n\nline 4',
            languageId: languageId,
            lastModified: lastModified,
          ).lineCount,
          equals(4),
        );
      });
    });

    group('characterCount', () {
      test('should count characters correctly', () {
        expect(
          EditorDocument(
            uri: uri,
            content: 'hello',
            languageId: languageId,
            lastModified: lastModified,
          ).characterCount,
          equals(5),
        );
      });

      test('should return 0 for empty content', () {
        expect(
          EditorDocument(
            uri: uri,
            content: '',
            languageId: languageId,
            lastModified: lastModified,
          ).characterCount,
          equals(0),
        );
      });

      test('should count newlines', () {
        expect(
          EditorDocument(
            uri: uri,
            content: 'a\nb\nc',
            languageId: languageId,
            lastModified: lastModified,
          ).characterCount,
          equals(5), // 'a', '\n', 'b', '\n', 'c'
        );
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        final doc1 = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
        );

        final doc2 = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
        );

        expect(doc1, equals(doc2));
      });

      test('should not be equal with different content', () {
        final doc1 = EditorDocument(
          uri: uri,
          content: 'content 1',
          languageId: languageId,
          lastModified: lastModified,
        );

        final doc2 = EditorDocument(
          uri: uri,
          content: 'content 2',
          languageId: languageId,
          lastModified: lastModified,
        );

        expect(doc1, isNot(equals(doc2)));
      });

      test('should not be equal with different dirty state', () {
        final doc1 = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
          isDirty: false,
        );

        final doc2 = EditorDocument(
          uri: uri,
          content: content,
          languageId: languageId,
          lastModified: lastModified,
          isDirty: true,
        );

        expect(doc1, isNot(equals(doc2)));
      });
    });

    group('workflow', () {
      test('should support edit and save workflow', () {
        // Create new document
        final document = EditorDocument(
          uri: uri,
          content: 'original',
          languageId: languageId,
          lastModified: lastModified,
        );

        expect(document.isDirty, isFalse);

        // Edit document
        final edited = document.updateContent('modified');
        expect(edited.isDirty, isTrue);
        expect(edited.content, equals('modified'));

        // Save document
        final saved = edited.markAsSaved();
        expect(saved.isDirty, isFalse);
        expect(saved.content, equals('modified'));
      });

      test('should support multiple edits', () {
        var document = EditorDocument(
          uri: uri,
          content: 'version 1',
          languageId: languageId,
          lastModified: lastModified,
        );

        document = document.updateContent('version 2');
        expect(document.content, equals('version 2'));

        document = document.updateContent('version 3');
        expect(document.content, equals('version 3'));

        document = document.updateContent('version 4');
        expect(document.content, equals('version 4'));

        expect(document.isDirty, isTrue);
      });
    });
  });
}
