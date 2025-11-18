import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/src/domain/entities/file_document.dart';

void main() {
  group('FileDocument', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    group('creation', () {
      test('should create file document with required fields', () {
        // Arrange & Act
        final doc = FileDocument(
          id: '123',
          name: 'main.dart',
          folderId: 'folder-1',
          content: 'void main() {}',
          language: 'dart',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(doc.id, equals('123'));
        expect(doc.name, equals('main.dart'));
        expect(doc.folderId, equals('folder-1'));
        expect(doc.content, equals('void main() {}'));
        expect(doc.language, equals('dart'));
        expect(doc.createdAt, equals(now));
        expect(doc.updatedAt, equals(now));
        expect(doc.metadata, isNull);
      });

      test('should create file document with metadata', () {
        // Arrange & Act
        final doc = FileDocument(
          id: '123',
          name: 'main.dart',
          folderId: 'folder-1',
          content: '',
          language: 'dart',
          createdAt: now,
          updatedAt: now,
          metadata: {'readonly': true, 'version': 1},
        );

        // Assert
        expect(doc.metadata, isNotNull);
        expect(doc.metadata!['readonly'], equals(true));
        expect(doc.metadata!['version'], equals(1));
      });

      test('should create empty file document', () {
        // Arrange & Act
        final doc = FileDocument(
          id: '123',
          name: 'new_file.txt',
          folderId: 'folder-1',
          content: '',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(doc.content, equals(''));
        expect(doc.isEmpty, isTrue);
      });
    });

    group('updateContent', () {
      test('should update content', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'main.dart',
          folderId: 'folder-1',
          content: 'old content',
          language: 'dart',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final updated = doc.updateContent('new content');

        // Assert
        expect(updated.content, equals('new content'));
        expect(updated.id, equals(doc.id));
        expect(updated.name, equals(doc.name));
        expect(updated.updatedAt.isAfter(doc.updatedAt), isTrue);
      });

      test('should not modify original document', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'main.dart',
          folderId: 'folder-1',
          content: 'old content',
          language: 'dart',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        doc.updateContent('new content');

        // Assert
        expect(doc.content, equals('old content'));
      });

      test('should update to empty content', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'main.dart',
          folderId: 'folder-1',
          content: 'some content',
          language: 'dart',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final updated = doc.updateContent('');

        // Assert
        expect(updated.content, equals(''));
        expect(updated.isEmpty, isTrue);
      });
    });

    group('rename', () {
      test('should rename file', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'old_name.dart',
          folderId: 'folder-1',
          content: 'content',
          language: 'dart',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final renamed = doc.rename('new_name.dart');

        // Assert
        expect(renamed.name, equals('new_name.dart'));
        expect(renamed.id, equals(doc.id));
        expect(renamed.content, equals(doc.content));
        expect(renamed.updatedAt.isAfter(doc.updatedAt), isTrue);
      });

      test('should not modify original document', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'old_name.dart',
          folderId: 'folder-1',
          content: 'content',
          language: 'dart',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        doc.rename('new_name.dart');

        // Assert
        expect(doc.name, equals('old_name.dart'));
      });
    });

    group('move', () {
      test('should move file to different folder', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'file.dart',
          folderId: 'folder-1',
          content: 'content',
          language: 'dart',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final moved = doc.move('folder-2');

        // Assert
        expect(moved.folderId, equals('folder-2'));
        expect(moved.id, equals(doc.id));
        expect(moved.name, equals(doc.name));
        expect(moved.updatedAt.isAfter(doc.updatedAt), isTrue);
      });

      test('should not modify original document', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'file.dart',
          folderId: 'folder-1',
          content: 'content',
          language: 'dart',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        doc.move('folder-2');

        // Assert
        expect(doc.folderId, equals('folder-1'));
      });
    });

    group('isEmpty', () {
      test('should detect empty content', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: '',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(doc.isEmpty, isTrue);
      });

      test('should detect whitespace-only as empty', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: '   \n\t  ',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(doc.isEmpty, isTrue);
      });

      test('should detect non-empty content', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: 'Hello',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(doc.isEmpty, isFalse);
      });
    });

    group('sizeInBytes', () {
      test('should calculate size for ASCII content', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: 'Hello, World!',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final size = doc.sizeInBytes;

        // Assert
        expect(size, equals(13));
      });

      test('should calculate size for Unicode content', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: 'Привет! 🚀',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final size = doc.sizeInBytes;

        // Assert
        expect(size, greaterThan(8)); // UTF-8 encoded size
      });

      test('should return 0 for empty content', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: '',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final size = doc.sizeInBytes;

        // Assert
        expect(size, equals(0));
      });
    });

    group('extension', () {
      test('should extract extension from name', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'main.dart',
          folderId: 'folder-1',
          content: '',
          language: 'dart',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final extension = doc.extension;

        // Assert
        expect(extension, equals('dart'));
      });

      test('should extract last extension from multiple', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'archive.tar.gz',
          folderId: 'folder-1',
          content: '',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final extension = doc.extension;

        // Assert
        expect(extension, equals('gz'));
      });

      test('should return empty string for no extension', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'README',
          folderId: 'folder-1',
          content: '',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final extension = doc.extension;

        // Assert
        expect(extension, equals(''));
      });

      test('should return empty string for dotfile', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: '.gitignore',
          folderId: 'folder-1',
          content: '',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final extension = doc.extension;

        // Assert
        expect(extension, equals(''));
      });
    });

    group('copyWith', () {
      test('should copy with new content', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: 'old',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final copied = doc.copyWith(content: 'new');

        // Assert
        expect(copied.content, equals('new'));
        expect(copied.id, equals(doc.id));
      });

      test('should copy with new name', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'old.txt',
          folderId: 'folder-1',
          content: 'content',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final copied = doc.copyWith(name: 'new.txt');

        // Assert
        expect(copied.name, equals('new.txt'));
        expect(copied.content, equals(doc.content));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        // Arrange
        final doc1 = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: 'content',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        final doc2 = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: 'content',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(doc1, equals(doc2));
      });

      test('should not be equal with different content', () {
        // Arrange
        final doc1 = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: 'content1',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        final doc2 = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: 'content2',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(doc1, isNot(equals(doc2)));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        // Arrange
        final doc = FileDocument(
          id: '123',
          name: 'file.txt',
          folderId: 'folder-1',
          content: 'content',
          language: 'plaintext',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final json = doc.toJson();

        // Assert
        expect(json['id'], equals('123'));
        expect(json['name'], equals('file.txt'));
        expect(json['folderId'], equals('folder-1'));
        expect(json['content'], equals('content'));
        expect(json['language'], equals('plaintext'));
      });

      test('should deserialize from JSON', () {
        // Arrange
        final json = {
          'id': '123',
          'name': 'file.txt',
          'folderId': 'folder-1',
          'content': 'content',
          'language': 'plaintext',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };

        // Act
        final doc = FileDocument.fromJson(json);

        // Assert
        expect(doc.id, equals('123'));
        expect(doc.name, equals('file.txt'));
        expect(doc.content, equals('content'));
      });
    });

    group('use cases', () {
      test('should represent typical Dart source file', () {
        // Arrange
        const dartCode = '''
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}
''';

        final doc = FileDocument(
          id: 'dart-1',
          name: 'main.dart',
          folderId: 'lib',
          content: dartCode,
          language: 'dart',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(doc.extension, equals('dart'));
        expect(doc.isEmpty, isFalse);
        expect(doc.sizeInBytes, greaterThan(0));
      });

      test('should handle file editing workflow', () {
        // Arrange - Create new file
        final doc = FileDocument(
          id: 'file-1',
          name: 'new_file.dart',
          folderId: 'lib',
          content: '',
          language: 'dart',
          createdAt: now,
          updatedAt: now,
        );

        expect(doc.isEmpty, isTrue);

        // Act - Edit content
        final edited = doc.updateContent('void main() {}');

        // Assert
        expect(edited.isEmpty, isFalse);
        expect(edited.updatedAt.isAfter(doc.updatedAt), isTrue);

        // Act - Rename file
        final renamed = edited.rename('app.dart');

        // Assert
        expect(renamed.name, equals('app.dart'));
        expect(renamed.content, equals(edited.content));

        // Act - Move to different folder
        final moved = renamed.move('src');

        // Assert
        expect(moved.folderId, equals('src'));
        expect(moved.name, equals(renamed.name));
      });
    });
  });
}
