import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_plugin_recent_files/src/domain/entities/recent_files_list.dart';
import 'package:multi_editor_plugin_recent_files/src/domain/value_objects/recent_file_entry.dart';

void main() {
  group('RecentFilesList - Creation', () {
    test('should create with default max entries of 10', () {
      // Arrange & Act
      final list = RecentFilesList.create();

      // Assert
      expect(list.maxEntries, 10);
      expect(list.entries, isEmpty);
    });

    test('should create with custom max entries', () {
      // Arrange & Act
      final list = RecentFilesList.create(maxEntries: 20);

      // Assert
      expect(list.maxEntries, 20);
      expect(list.entries, isEmpty);
    });

    test('should throw ArgumentError for maxEntries below 1', () {
      // Arrange, Act & Assert
      expect(
        () => RecentFilesList.create(maxEntries: 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw ArgumentError for maxEntries above 50', () {
      // Arrange, Act & Assert
      expect(
        () => RecentFilesList.create(maxEntries: 51),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should accept boundary values for maxEntries', () {
      // Arrange, Act & Assert
      expect(() => RecentFilesList.create(maxEntries: 1), returnsNormally);
      expect(() => RecentFilesList.create(maxEntries: 50), returnsNormally);
    });
  });

  group('RecentFilesList - Adding Files', () {
    test('should add new file to list', () {
      // Arrange
      final list = RecentFilesList.create();
      final entry = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test.dart',
        filePath: '/path/test.dart',
      );

      // Act
      final updated = list.addFile(entry);

      // Assert
      expect(updated.count, 1);
      expect(updated.entries.first.fileId, 'file-1');
    });

    test('should add file to beginning of list', () {
      // Arrange
      var list = RecentFilesList.create();
      final entry1 = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test1.dart',
        filePath: '/path/test1.dart',
      );
      final entry2 = RecentFileEntry.create(
        fileId: 'file-2',
        fileName: 'test2.dart',
        filePath: '/path/test2.dart',
      );

      // Act
      list = list.addFile(entry1);
      list = list.addFile(entry2);

      // Assert
      expect(list.count, 2);
      expect(list.entries[0].fileId, 'file-2'); // Most recent first
      expect(list.entries[1].fileId, 'file-1');
    });

    test('should update existing file timestamp and move to top', () {
      // Arrange
      var list = RecentFilesList.create();
      final entry1 = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test1.dart',
        filePath: '/path/test1.dart',
      );
      final entry2 = RecentFileEntry.create(
        fileId: 'file-2',
        fileName: 'test2.dart',
        filePath: '/path/test2.dart',
      );

      list = list.addFile(entry1);
      list = list.addFile(entry2);

      // Act - Re-add file-1
      final updatedEntry1 = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test1.dart',
        filePath: '/path/test1.dart',
      );
      list = list.addFile(updatedEntry1);

      // Assert
      expect(list.count, 2);
      expect(list.entries[0].fileId, 'file-1'); // Should be first now
      expect(list.entries[1].fileId, 'file-2');
    });

    test('should respect max entries limit', () {
      // Arrange
      var list = RecentFilesList.create(maxEntries: 3);

      // Act - Add 5 files
      for (int i = 0; i < 5; i++) {
        final entry = RecentFileEntry.create(
          fileId: 'file-$i',
          fileName: 'test$i.dart',
          filePath: '/path/test$i.dart',
        );
        list = list.addFile(entry);
      }

      // Assert
      expect(list.count, 3);
      expect(list.entries[0].fileId, 'file-4'); // Most recent
      expect(list.entries[1].fileId, 'file-3');
      expect(list.entries[2].fileId, 'file-2');
      expect(list.isFull, true);
    });

    test('should remove oldest entry when exceeding max', () {
      // Arrange
      var list = RecentFilesList.create(maxEntries: 2);
      final entry1 = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test1.dart',
        filePath: '/path/test1.dart',
      );
      final entry2 = RecentFileEntry.create(
        fileId: 'file-2',
        fileName: 'test2.dart',
        filePath: '/path/test2.dart',
      );
      final entry3 = RecentFileEntry.create(
        fileId: 'file-3',
        fileName: 'test3.dart',
        filePath: '/path/test3.dart',
      );

      // Act
      list = list.addFile(entry1);
      list = list.addFile(entry2);
      list = list.addFile(entry3);

      // Assert
      expect(list.count, 2);
      expect(list.contains('file-1'), false); // Oldest removed
      expect(list.contains('file-2'), true);
      expect(list.contains('file-3'), true);
    });
  });

  group('RecentFilesList - Removing Files', () {
    test('should remove file by ID', () {
      // Arrange
      var list = RecentFilesList.create();
      final entry1 = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test1.dart',
        filePath: '/path/test1.dart',
      );
      final entry2 = RecentFileEntry.create(
        fileId: 'file-2',
        fileName: 'test2.dart',
        filePath: '/path/test2.dart',
      );

      list = list.addFile(entry1);
      list = list.addFile(entry2);

      // Act
      list = list.removeFile('file-1');

      // Assert
      expect(list.count, 1);
      expect(list.contains('file-1'), false);
      expect(list.contains('file-2'), true);
    });

    test('should handle removing non-existent file', () {
      // Arrange
      var list = RecentFilesList.create();
      final entry = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test.dart',
        filePath: '/path/test.dart',
      );
      list = list.addFile(entry);

      // Act
      list = list.removeFile('non-existent');

      // Assert
      expect(list.count, 1);
      expect(list.contains('file-1'), true);
    });

    test('should remove all entries with clear', () {
      // Arrange
      var list = RecentFilesList.create();
      for (int i = 0; i < 5; i++) {
        final entry = RecentFileEntry.create(
          fileId: 'file-$i',
          fileName: 'test$i.dart',
          filePath: '/path/test$i.dart',
        );
        list = list.addFile(entry);
      }

      // Act
      list = list.clear();

      // Assert
      expect(list.isEmpty, true);
      expect(list.count, 0);
    });
  });

  group('RecentFilesList - Queries', () {
    test('should check if contains file by ID', () {
      // Arrange
      var list = RecentFilesList.create();
      final entry = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test.dart',
        filePath: '/path/test.dart',
      );
      list = list.addFile(entry);

      // Act & Assert
      expect(list.contains('file-1'), true);
      expect(list.contains('non-existent'), false);
    });

    test('should return correct count', () {
      // Arrange
      var list = RecentFilesList.create();

      // Act & Assert
      expect(list.count, 0);

      final entry1 = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test1.dart',
        filePath: '/path/test1.dart',
      );
      list = list.addFile(entry1);
      expect(list.count, 1);

      final entry2 = RecentFileEntry.create(
        fileId: 'file-2',
        fileName: 'test2.dart',
        filePath: '/path/test2.dart',
      );
      list = list.addFile(entry2);
      expect(list.count, 2);
    });

    test('should report isEmpty correctly', () {
      // Arrange
      var list = RecentFilesList.create();

      // Act & Assert
      expect(list.isEmpty, true);
      expect(list.isNotEmpty, false);

      final entry = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test.dart',
        filePath: '/path/test.dart',
      );
      list = list.addFile(entry);

      expect(list.isEmpty, false);
      expect(list.isNotEmpty, true);
    });

    test('should report isFull correctly', () {
      // Arrange
      var list = RecentFilesList.create(maxEntries: 2);

      // Act & Assert
      expect(list.isFull, false);

      final entry1 = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test1.dart',
        filePath: '/path/test1.dart',
      );
      list = list.addFile(entry1);
      expect(list.isFull, false);

      final entry2 = RecentFileEntry.create(
        fileId: 'file-2',
        fileName: 'test2.dart',
        filePath: '/path/test2.dart',
      );
      list = list.addFile(entry2);
      expect(list.isFull, true);
    });

    test('should return entries sorted by recency', () {
      // Arrange
      var list = RecentFilesList.create();

      for (int i = 0; i < 3; i++) {
        final entry = RecentFileEntry.create(
          fileId: 'file-$i',
          fileName: 'test$i.dart',
          filePath: '/path/test$i.dart',
        );
        list = list.addFile(entry);
      }

      // Act
      final sorted = list.sortedByRecent;

      // Assert
      expect(sorted[0].fileId, 'file-2'); // Most recent
      expect(sorted[1].fileId, 'file-1');
      expect(sorted[2].fileId, 'file-0');
    });
  });

  group('RecentFilesList - JSON Serialization', () {
    test('should serialize to JSON', () {
      // Arrange
      var list = RecentFilesList.create(maxEntries: 5);
      final entry = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test.dart',
        filePath: '/path/test.dart',
      );
      list = list.addFile(entry);

      // Act
      final json = list.toJson();

      // Assert
      expect(json['maxEntries'], 5);
      expect(json['entries'], isA<List>());
      expect((json['entries'] as List).length, 1);
    });

    test('should deserialize from JSON', () {
      // Arrange
      final json = {
        'maxEntries': 15,
        'entries': [
          {
            'fileId': 'file-1',
            'fileName': 'test.dart',
            'filePath': '/path/test.dart',
            'lastOpened': DateTime.now().toIso8601String(),
          },
        ],
      };

      // Act
      final list = RecentFilesList.fromJson(json);

      // Assert
      expect(list.maxEntries, 15);
      expect(list.count, 1);
      expect(list.entries.first.fileId, 'file-1');
    });

    test('should roundtrip through JSON', () {
      // Arrange
      var original = RecentFilesList.create(maxEntries: 7);
      for (int i = 0; i < 3; i++) {
        final entry = RecentFileEntry.create(
          fileId: 'file-$i',
          fileName: 'test$i.dart',
          filePath: '/path/test$i.dart',
        );
        original = original.addFile(entry);
      }

      // Act
      final json = original.toJson();
      final restored = RecentFilesList.fromJson(json);

      // Assert
      expect(restored.maxEntries, original.maxEntries);
      expect(restored.count, original.count);
      expect(restored.entries.length, original.entries.length);
    });
  });

  group('RecentFilesList - Equality', () {
    test('should be equal for same values', () {
      // Arrange
      final entry = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test.dart',
        filePath: '/path/test.dart',
      );

      final list1 = RecentFilesList.create().addFile(entry);
      final list2 = RecentFilesList.create().addFile(entry);

      // Act & Assert
      expect(list1, equals(list2));
    });

    test('should not be equal for different entries', () {
      // Arrange
      final entry1 = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test1.dart',
        filePath: '/path/test1.dart',
      );
      final entry2 = RecentFileEntry.create(
        fileId: 'file-2',
        fileName: 'test2.dart',
        filePath: '/path/test2.dart',
      );

      final list1 = RecentFilesList.create().addFile(entry1);
      final list2 = RecentFilesList.create().addFile(entry2);

      // Act & Assert
      expect(list1, isNot(equals(list2)));
    });
  });

  group('RecentFilesList - Immutability', () {
    test('should create new instance when adding file', () {
      // Arrange
      final original = RecentFilesList.create();
      final entry = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test.dart',
        filePath: '/path/test.dart',
      );

      // Act
      final updated = original.addFile(entry);

      // Assert
      expect(original.count, 0);
      expect(updated.count, 1);
    });

    test('should create new instance when removing file', () {
      // Arrange
      var original = RecentFilesList.create();
      final entry = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test.dart',
        filePath: '/path/test.dart',
      );
      original = original.addFile(entry);

      // Act
      final updated = original.removeFile('file-1');

      // Assert
      expect(original.count, 1);
      expect(updated.count, 0);
    });

    test('should create new instance when clearing', () {
      // Arrange
      var original = RecentFilesList.create();
      final entry = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test.dart',
        filePath: '/path/test.dart',
      );
      original = original.addFile(entry);

      // Act
      final cleared = original.clear();

      // Assert
      expect(original.count, 1);
      expect(cleared.count, 0);
    });
  });

  group('RecentFilesList - Use Cases', () {
    test('Use Case: Track recently edited files in editor', () {
      // Arrange
      var list = RecentFilesList.create(maxEntries: 5);

      final files = [
        ('main.dart', '/lib/main.dart'),
        ('app.dart', '/lib/app.dart'),
        ('home.dart', '/lib/screens/home.dart'),
        ('profile.dart', '/lib/screens/profile.dart'),
      ];

      // Act - User opens files in sequence
      for (int i = 0; i < files.length; i++) {
        final entry = RecentFileEntry.create(
          fileId: 'file-$i',
          fileName: files[i].$1,
          filePath: files[i].$2,
        );
        list = list.addFile(entry);
      }

      // Assert - Most recent first
      expect(list.count, 4);
      expect(list.sortedByRecent[0].fileName, 'profile.dart');
      expect(list.sortedByRecent[3].fileName, 'main.dart');
    });

    test('Use Case: User returns to previously opened file', () {
      // Arrange
      var list = RecentFilesList.create();

      final file1 = RecentFileEntry.create(
        fileId: '1',
        fileName: 'main.dart',
        filePath: '/lib/main.dart',
      );
      final file2 = RecentFileEntry.create(
        fileId: '2',
        fileName: 'test.dart',
        filePath: '/test/test.dart',
      );

      list = list.addFile(file1);
      list = list.addFile(file2);

      // Act - User reopens main.dart
      final reopenedFile1 = RecentFileEntry.create(
        fileId: '1',
        fileName: 'main.dart',
        filePath: '/lib/main.dart',
      );
      list = list.addFile(reopenedFile1);

      // Assert - main.dart should be first
      expect(list.sortedByRecent[0].fileId, '1');
      expect(list.count, 2);
    });

    test('Use Case: Limit visible recent files to 10', () {
      // Arrange
      var list = RecentFilesList.create(maxEntries: 10);

      // Act - User opens 20 files
      for (int i = 0; i < 20; i++) {
        final entry = RecentFileEntry.create(
          fileId: 'file-$i',
          fileName: 'test$i.dart',
          filePath: '/path/test$i.dart',
        );
        list = list.addFile(entry);
      }

      // Assert - Only last 10 are kept
      expect(list.count, 10);
      expect(list.isFull, true);
      expect(list.sortedByRecent[0].fileId, 'file-19');
      expect(list.sortedByRecent[9].fileId, 'file-10');
    });

    test('Use Case: Remove deleted file from recent list', () {
      // Arrange
      var list = RecentFilesList.create();

      for (int i = 0; i < 5; i++) {
        final entry = RecentFileEntry.create(
          fileId: 'file-$i',
          fileName: 'test$i.dart',
          filePath: '/path/test$i.dart',
        );
        list = list.addFile(entry);
      }

      // Act - File gets deleted
      list = list.removeFile('file-2');

      // Assert
      expect(list.count, 4);
      expect(list.contains('file-2'), false);
    });

    test('Use Case: Clear recent files when switching projects', () {
      // Arrange
      var list = RecentFilesList.create();

      for (int i = 0; i < 10; i++) {
        final entry = RecentFileEntry.create(
          fileId: 'old-project-$i',
          fileName: 'file$i.dart',
          filePath: '/old/file$i.dart',
        );
        list = list.addFile(entry);
      }

      // Act - User switches projects
      list = list.clear();

      // Assert
      expect(list.isEmpty, true);
    });
  });

  group('RecentFilesList - Edge Cases', () {
    test('should handle minimum max entries (1)', () {
      // Arrange
      var list = RecentFilesList.create(maxEntries: 1);

      final entry1 = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test1.dart',
        filePath: '/path/test1.dart',
      );
      final entry2 = RecentFileEntry.create(
        fileId: 'file-2',
        fileName: 'test2.dart',
        filePath: '/path/test2.dart',
      );

      // Act
      list = list.addFile(entry1);
      list = list.addFile(entry2);

      // Assert
      expect(list.count, 1);
      expect(list.contains('file-2'), true);
      expect(list.contains('file-1'), false);
    });

    test('should handle maximum max entries (50)', () {
      // Arrange
      var list = RecentFilesList.create(maxEntries: 50);

      // Act
      for (int i = 0; i < 100; i++) {
        final entry = RecentFileEntry.create(
          fileId: 'file-$i',
          fileName: 'test$i.dart',
          filePath: '/path/test$i.dart',
        );
        list = list.addFile(entry);
      }

      // Assert
      expect(list.count, 50);
      expect(list.contains('file-99'), true);
      expect(list.contains('file-49'), false);
    });

    test('should handle adding same file multiple times rapidly', () {
      // Arrange
      var list = RecentFilesList.create();
      final entry = RecentFileEntry.create(
        fileId: 'file-1',
        fileName: 'test.dart',
        filePath: '/path/test.dart',
      );

      // Act
      for (int i = 0; i < 10; i++) {
        list = list.addFile(entry);
      }

      // Assert
      expect(list.count, 1);
    });

    test('should handle empty list operations', () {
      // Arrange
      final list = RecentFilesList.create();

      // Act & Assert
      expect(list.removeFile('any-id').count, 0);
      expect(list.clear().count, 0);
      expect(list.contains('any-id'), false);
      expect(list.sortedByRecent, isEmpty);
    });
  });
}
