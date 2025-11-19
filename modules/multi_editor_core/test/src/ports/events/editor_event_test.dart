import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/src/ports/events/editor_event.dart';
import 'package:multi_editor_core/src/domain/entities/file_document.dart';
import 'package:multi_editor_core/src/domain/entities/folder.dart';

void main() {
  group('EditorEvent', () {
    late FileDocument testFile;
    late Folder testFolder;

    setUp(() {
      testFile = FileDocument(
        id: 'file-123',
        name: 'test.dart',
        folderId: 'folder-1',
        path: '/project/test.dart',
        content: 'void main() {}',
      );

      testFolder = Folder(
        id: 'folder-1',
        name: 'src',
        path: '/project/src',
      );
    });

    group('FileOpened', () {
      test('should create file opened event', () {
        // Act
        final event = EditorEvent.fileOpened(file: testFile);

        // Assert
        expect(event, isA<FileOpened>());
        event.when(
          fileOpened: (file) => expect(file.id, 'file-123'),
          fileClosed: (_) => fail('Wrong event type'),
          fileContentChanged: (_, __) => fail('Wrong event type'),
          fileSaved: (_) => fail('Wrong event type'),
          fileCreated: (_) => fail('Wrong event type'),
          fileDeleted: (_) => fail('Wrong event type'),
          fileRenamed: (_, __, ___) => fail('Wrong event type'),
          fileMoved: (_, __, ___) => fail('Wrong event type'),
          folderCreated: (_) => fail('Wrong event type'),
          folderDeleted: (_) => fail('Wrong event type'),
          folderRenamed: (_, __, ___) => fail('Wrong event type'),
          folderMoved: (_, __, ___) => fail('Wrong event type'),
          projectChanged: (_) => fail('Wrong event type'),
        );
      });

      test('should provide access to file data', () {
        // Arrange
        final event = EditorEvent.fileOpened(file: testFile);

        // Act & Assert
        expect((event as FileOpened).file.id, 'file-123');
        expect(event.file.name, 'test.dart');
        expect(event.file.content, 'void main() {}');
      });
    });

    group('FileClosed', () {
      test('should create file closed event', () {
        // Act
        final event = EditorEvent.fileClosed(fileId: 'file-123');

        // Assert
        expect(event, isA<FileClosed>());
        event.when(
          fileOpened: (_) => fail('Wrong event type'),
          fileClosed: (fileId) => expect(fileId, 'file-123'),
          fileContentChanged: (_, __) => fail('Wrong event type'),
          fileSaved: (_) => fail('Wrong event type'),
          fileCreated: (_) => fail('Wrong event type'),
          fileDeleted: (_) => fail('Wrong event type'),
          fileRenamed: (_, __, ___) => fail('Wrong event type'),
          fileMoved: (_, __, ___) => fail('Wrong event type'),
          folderCreated: (_) => fail('Wrong event type'),
          folderDeleted: (_) => fail('Wrong event type'),
          folderRenamed: (_, __, ___) => fail('Wrong event type'),
          folderMoved: (_, __, ___) => fail('Wrong event type'),
          projectChanged: (_) => fail('Wrong event type'),
        );
      });

      test('should provide access to file ID', () {
        // Arrange
        final event = EditorEvent.fileClosed(fileId: 'file-abc');

        // Act & Assert
        expect((event as FileClosed).fileId, 'file-abc');
      });
    });

    group('FileContentChanged', () {
      test('should create file content changed event', () {
        // Act
        final event = EditorEvent.fileContentChanged(
          fileId: 'file-123',
          content: 'new content',
        );

        // Assert
        expect(event, isA<FileContentChanged>());
        event.when(
          fileOpened: (_) => fail('Wrong event type'),
          fileClosed: (_) => fail('Wrong event type'),
          fileContentChanged: (fileId, content) {
            expect(fileId, 'file-123');
            expect(content, 'new content');
          },
          fileSaved: (_) => fail('Wrong event type'),
          fileCreated: (_) => fail('Wrong event type'),
          fileDeleted: (_) => fail('Wrong event type'),
          fileRenamed: (_, __, ___) => fail('Wrong event type'),
          fileMoved: (_, __, ___) => fail('Wrong event type'),
          folderCreated: (_) => fail('Wrong event type'),
          folderDeleted: (_) => fail('Wrong event type'),
          folderRenamed: (_, __, ___) => fail('Wrong event type'),
          folderMoved: (_, __, ___) => fail('Wrong event type'),
          projectChanged: (_) => fail('Wrong event type'),
        );
      });

      test('should handle empty content', () {
        // Arrange
        final event = EditorEvent.fileContentChanged(
          fileId: 'file-123',
          content: '',
        );

        // Act & Assert
        expect((event as FileContentChanged).content, '');
      });
    });

    group('FileSaved', () {
      test('should create file saved event', () {
        // Act
        final event = EditorEvent.fileSaved(file: testFile);

        // Assert
        expect(event, isA<FileSaved>());
        event.when(
          fileOpened: (_) => fail('Wrong event type'),
          fileClosed: (_) => fail('Wrong event type'),
          fileContentChanged: (_, __) => fail('Wrong event type'),
          fileSaved: (file) => expect(file.id, 'file-123'),
          fileCreated: (_) => fail('Wrong event type'),
          fileDeleted: (_) => fail('Wrong event type'),
          fileRenamed: (_, __, ___) => fail('Wrong event type'),
          fileMoved: (_, __, ___) => fail('Wrong event type'),
          folderCreated: (_) => fail('Wrong event type'),
          folderDeleted: (_) => fail('Wrong event type'),
          folderRenamed: (_, __, ___) => fail('Wrong event type'),
          folderMoved: (_, __, ___) => fail('Wrong event type'),
          projectChanged: (_) => fail('Wrong event type'),
        );
      });
    });

    group('FileCreated', () {
      test('should create file created event', () {
        // Act
        final event = EditorEvent.fileCreated(file: testFile);

        // Assert
        expect(event, isA<FileCreated>());
        expect((event as FileCreated).file.id, 'file-123');
      });
    });

    group('FileDeleted', () {
      test('should create file deleted event', () {
        // Act
        final event = EditorEvent.fileDeleted(fileId: 'file-123');

        // Assert
        expect(event, isA<FileDeleted>());
        expect((event as FileDeleted).fileId, 'file-123');
      });
    });

    group('FileRenamed', () {
      test('should create file renamed event', () {
        // Act
        final event = EditorEvent.fileRenamed(
          fileId: 'file-123',
          oldName: 'old.dart',
          newName: 'new.dart',
        );

        // Assert
        expect(event, isA<FileRenamed>());
        event.when(
          fileOpened: (_) => fail('Wrong event type'),
          fileClosed: (_) => fail('Wrong event type'),
          fileContentChanged: (_, __) => fail('Wrong event type'),
          fileSaved: (_) => fail('Wrong event type'),
          fileCreated: (_) => fail('Wrong event type'),
          fileDeleted: (_) => fail('Wrong event type'),
          fileRenamed: (fileId, oldName, newName) {
            expect(fileId, 'file-123');
            expect(oldName, 'old.dart');
            expect(newName, 'new.dart');
          },
          fileMoved: (_, __, ___) => fail('Wrong event type'),
          folderCreated: (_) => fail('Wrong event type'),
          folderDeleted: (_) => fail('Wrong event type'),
          folderRenamed: (_, __, ___) => fail('Wrong event type'),
          folderMoved: (_, __, ___) => fail('Wrong event type'),
          projectChanged: (_) => fail('Wrong event type'),
        );
      });

      test('should provide access to all rename fields', () {
        // Arrange
        final event = EditorEvent.fileRenamed(
          fileId: 'file-abc',
          oldName: 'before.txt',
          newName: 'after.txt',
        );

        // Act
        final renamed = event as FileRenamed;

        // Assert
        expect(renamed.fileId, 'file-abc');
        expect(renamed.oldName, 'before.txt');
        expect(renamed.newName, 'after.txt');
      });
    });

    group('FileMoved', () {
      test('should create file moved event', () {
        // Act
        final event = EditorEvent.fileMoved(
          fileId: 'file-123',
          oldFolderId: 'folder-1',
          newFolderId: 'folder-2',
        );

        // Assert
        expect(event, isA<FileMoved>());
        event.when(
          fileOpened: (_) => fail('Wrong event type'),
          fileClosed: (_) => fail('Wrong event type'),
          fileContentChanged: (_, __) => fail('Wrong event type'),
          fileSaved: (_) => fail('Wrong event type'),
          fileCreated: (_) => fail('Wrong event type'),
          fileDeleted: (_) => fail('Wrong event type'),
          fileRenamed: (_, __, ___) => fail('Wrong event type'),
          fileMoved: (fileId, oldFolderId, newFolderId) {
            expect(fileId, 'file-123');
            expect(oldFolderId, 'folder-1');
            expect(newFolderId, 'folder-2');
          },
          folderCreated: (_) => fail('Wrong event type'),
          folderDeleted: (_) => fail('Wrong event type'),
          folderRenamed: (_, __, ___) => fail('Wrong event type'),
          folderMoved: (_, __, ___) => fail('Wrong event type'),
          projectChanged: (_) => fail('Wrong event type'),
        );
      });
    });

    group('FolderCreated', () {
      test('should create folder created event', () {
        // Act
        final event = EditorEvent.folderCreated(folder: testFolder);

        // Assert
        expect(event, isA<FolderCreated>());
        expect((event as FolderCreated).folder.id, 'folder-1');
        expect(event.folder.name, 'src');
      });
    });

    group('FolderDeleted', () {
      test('should create folder deleted event', () {
        // Act
        final event = EditorEvent.folderDeleted(folderId: 'folder-1');

        // Assert
        expect(event, isA<FolderDeleted>());
        expect((event as FolderDeleted).folderId, 'folder-1');
      });
    });

    group('FolderRenamed', () {
      test('should create folder renamed event', () {
        // Act
        final event = EditorEvent.folderRenamed(
          folderId: 'folder-1',
          oldName: 'old-folder',
          newName: 'new-folder',
        );

        // Assert
        expect(event, isA<FolderRenamed>());
        final renamed = event as FolderRenamed;
        expect(renamed.folderId, 'folder-1');
        expect(renamed.oldName, 'old-folder');
        expect(renamed.newName, 'new-folder');
      });
    });

    group('FolderMoved', () {
      test('should create folder moved event with both parent IDs', () {
        // Act
        final event = EditorEvent.folderMoved(
          folderId: 'folder-1',
          oldParentId: 'parent-1',
          newParentId: 'parent-2',
        );

        // Assert
        expect(event, isA<FolderMoved>());
        final moved = event as FolderMoved;
        expect(moved.folderId, 'folder-1');
        expect(moved.oldParentId, 'parent-1');
        expect(moved.newParentId, 'parent-2');
      });

      test('should handle null old parent ID', () {
        // Act
        final event = EditorEvent.folderMoved(
          folderId: 'folder-1',
          oldParentId: null,
          newParentId: 'parent-2',
        );

        // Assert
        final moved = event as FolderMoved;
        expect(moved.oldParentId, null);
        expect(moved.newParentId, 'parent-2');
      });

      test('should handle null new parent ID', () {
        // Act
        final event = EditorEvent.folderMoved(
          folderId: 'folder-1',
          oldParentId: 'parent-1',
          newParentId: null,
        );

        // Assert
        final moved = event as FolderMoved;
        expect(moved.oldParentId, 'parent-1');
        expect(moved.newParentId, null);
      });

      test('should handle both parents as null', () {
        // Act
        final event = EditorEvent.folderMoved(
          folderId: 'folder-1',
          oldParentId: null,
          newParentId: null,
        );

        // Assert
        final moved = event as FolderMoved;
        expect(moved.oldParentId, null);
        expect(moved.newParentId, null);
      });
    });

    group('ProjectChanged', () {
      test('should create project changed event', () {
        // Act
        final event = EditorEvent.projectChanged(projectId: 'project-123');

        // Assert
        expect(event, isA<ProjectChanged>());
        expect((event as ProjectChanged).projectId, 'project-123');
      });
    });

    group('pattern matching', () {
      test('should support map pattern matching', () {
        // Arrange
        final event = EditorEvent.fileOpened(file: testFile);

        // Act
        final result = event.map(
          fileOpened: (e) => 'opened: ${e.file.name}',
          fileClosed: (e) => 'closed: ${e.fileId}',
          fileContentChanged: (e) => 'changed: ${e.fileId}',
          fileSaved: (e) => 'saved: ${e.file.name}',
          fileCreated: (e) => 'created: ${e.file.name}',
          fileDeleted: (e) => 'deleted: ${e.fileId}',
          fileRenamed: (e) => 'renamed: ${e.oldName} -> ${e.newName}',
          fileMoved: (e) => 'moved: ${e.fileId}',
          folderCreated: (e) => 'folder created: ${e.folder.name}',
          folderDeleted: (e) => 'folder deleted: ${e.folderId}',
          folderRenamed: (e) => 'folder renamed: ${e.oldName} -> ${e.newName}',
          folderMoved: (e) => 'folder moved: ${e.folderId}',
          projectChanged: (e) => 'project changed: ${e.projectId}',
        );

        // Assert
        expect(result, 'opened: test.dart');
      });

      test('should support maybeMap pattern matching', () {
        // Arrange
        final event = EditorEvent.fileClosed(fileId: 'file-123');

        // Act
        final result = event.maybeMap(
          fileClosed: (e) => 'file closed',
          orElse: () => 'other event',
        );

        // Assert
        expect(result, 'file closed');
      });

      test('should use orElse in maybeMap when event does not match', () {
        // Arrange
        final event = EditorEvent.fileOpened(file: testFile);

        // Act
        final result = event.maybeMap(
          fileClosed: (e) => 'file closed',
          orElse: () => 'other event',
        );

        // Assert
        expect(result, 'other event');
      });
    });

    group('equality', () {
      test('should be equal when same event and data', () {
        // Arrange
        final event1 = EditorEvent.fileOpened(file: testFile);
        final event2 = EditorEvent.fileOpened(file: testFile);

        // Act & Assert
        expect(event1, equals(event2));
      });

      test('should not be equal when different event types', () {
        // Arrange
        final event1 = EditorEvent.fileOpened(file: testFile);
        final event2 = EditorEvent.fileClosed(fileId: testFile.id);

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal when same type but different data', () {
        // Arrange
        final file2 = FileDocument(
          id: 'file-456',
          name: 'other.dart',
          folderId: 'folder-1',
          path: '/project/other.dart',
          content: '',
        );
        final event1 = EditorEvent.fileOpened(file: testFile);
        final event2 = EditorEvent.fileOpened(file: file2);

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });
    });

    group('toString', () {
      test('should provide readable string representation', () {
        // Arrange
        final event = EditorEvent.fileOpened(file: testFile);

        // Act
        final str = event.toString();

        // Assert
        expect(str, contains('FileOpened'));
      });

      test('should include data in string representation', () {
        // Arrange
        final event = EditorEvent.fileRenamed(
          fileId: 'file-123',
          oldName: 'old.dart',
          newName: 'new.dart',
        );

        // Act
        final str = event.toString();

        // Assert
        expect(str, contains('FileRenamed'));
      });
    });

    group('copyWith', () {
      test('should create copy of FileContentChanged with new content', () {
        // Arrange
        final original = EditorEvent.fileContentChanged(
          fileId: 'file-123',
          content: 'original content',
        );

        // Act
        final copy = (original as FileContentChanged).copyWith(
          content: 'new content',
        );

        // Assert
        expect(copy.fileId, 'file-123');
        expect(copy.content, 'new content');
      });

      test('should create copy of FileRenamed with new names', () {
        // Arrange
        final original = EditorEvent.fileRenamed(
          fileId: 'file-123',
          oldName: 'old.dart',
          newName: 'new.dart',
        );

        // Act
        final copy = (original as FileRenamed).copyWith(
          newName: 'newest.dart',
        );

        // Assert
        expect(copy.fileId, 'file-123');
        expect(copy.oldName, 'old.dart');
        expect(copy.newName, 'newest.dart');
      });
    });

    group('edge cases', () {
      test('should handle empty file IDs', () {
        // Act
        final event = EditorEvent.fileClosed(fileId: '');

        // Assert
        expect((event as FileClosed).fileId, '');
      });

      test('should handle special characters in IDs', () {
        // Act
        final event = EditorEvent.fileClosed(
            fileId: 'file-with-special_chars.123');

        // Assert
        expect((event as FileClosed).fileId, 'file-with-special_chars.123');
      });

      test('should handle very long content strings', () {
        // Arrange
        final longContent = 'a' * 100000;

        // Act
        final event = EditorEvent.fileContentChanged(
          fileId: 'file-123',
          content: longContent,
        );

        // Assert
        expect((event as FileContentChanged).content.length, 100000);
      });

      test('should handle unicode in file names', () {
        // Act
        final event = EditorEvent.fileRenamed(
          fileId: 'file-123',
          oldName: 'файл.dart',
          newName: '文件.dart',
        );

        // Assert
        final renamed = event as FileRenamed;
        expect(renamed.oldName, 'файл.dart');
        expect(renamed.newName, '文件.dart');
      });

      test('should handle newlines in content', () {
        // Act
        final event = EditorEvent.fileContentChanged(
          fileId: 'file-123',
          content: 'line1\nline2\nline3',
        );

        // Assert
        expect((event as FileContentChanged).content, contains('\n'));
      });

      test('should handle file with complex document', () {
        // Arrange
        final complexFile = FileDocument(
          id: 'complex-123',
          name: 'complex-file.dart',
          folderId: 'folder-1',
          path: '/very/deep/nested/path/to/file.dart',
          content: 'a' * 10000,
        );

        // Act
        final event = EditorEvent.fileOpened(file: complexFile);

        // Assert
        expect((event as FileOpened).file.content.length, 10000);
        expect(event.file.path, contains('/very/deep/nested/'));
      });
    });

    group('type checking', () {
      test('should correctly identify event type with is operator', () {
        // Arrange
        final event = EditorEvent.fileOpened(file: testFile);

        // Act & Assert
        expect(event is FileOpened, true);
        expect(event is FileClosed, false);
        expect(event is FileContentChanged, false);
      });

      test('should work with runtime type checks', () {
        // Arrange
        EditorEvent event = EditorEvent.fileClosed(fileId: 'file-123');

        // Act
        if (event is FileClosed) {
          expect(event.fileId, 'file-123');
        } else {
          fail('Expected FileClosed event');
        }
      });
    });

    group('collection of events', () {
      test('should handle list of different event types', () {
        // Arrange
        final events = <EditorEvent>[
          EditorEvent.fileOpened(file: testFile),
          EditorEvent.fileClosed(fileId: 'file-123'),
          EditorEvent.fileContentChanged(
              fileId: 'file-123', content: 'new content'),
          EditorEvent.folderCreated(folder: testFolder),
        ];

        // Act
        final fileEvents =
            events.whereType<FileOpened>().toList();
        final folderEvents =
            events.whereType<FolderCreated>().toList();

        // Assert
        expect(fileEvents.length, 1);
        expect(folderEvents.length, 1);
        expect(events.length, 4);
      });

      test('should filter events by type', () {
        // Arrange
        final events = <EditorEvent>[
          EditorEvent.fileOpened(file: testFile),
          EditorEvent.fileOpened(file: testFile),
          EditorEvent.fileClosed(fileId: 'file-123'),
        ];

        // Act
        final openedEvents = events.where((e) => e is FileOpened).toList();

        // Assert
        expect(openedEvents.length, 2);
      });
    });
  });
}
