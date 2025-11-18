import 'package:flutter_test/flutter_test.dart';
import 'package:multi_editor_core/src/domain/entities/project.dart';

void main() {
  group('Project', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    group('creation', () {
      test('should create project with required fields', () {
        // Arrange & Act
        final project = Project(
          id: 'project-1',
          name: 'My App',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(project.id, equals('project-1'));
        expect(project.name, equals('My App'));
        expect(project.rootFolderId, equals('root-folder'));
        expect(project.description, isNull);
        expect(project.createdAt, equals(now));
        expect(project.updatedAt, equals(now));
        expect(project.settings, isEmpty);
        expect(project.metadata, isEmpty);
      });

      test('should create project with description', () {
        // Arrange & Act
        final project = Project(
          id: 'project-1',
          name: 'My App',
          description: 'A Flutter application',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(project.description, equals('A Flutter application'));
      });

      test('should create project with settings', () {
        // Arrange & Act
        final project = Project(
          id: 'project-1',
          name: 'My App',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
          settings: {
            'theme': 'dark',
            'autoSave': true,
            'tabSize': 2,
          },
        );

        // Assert
        expect(project.settings, isNotEmpty);
        expect(project.settings['theme'], equals('dark'));
        expect(project.settings['autoSave'], equals(true));
        expect(project.settings['tabSize'], equals(2));
      });

      test('should create project with metadata', () {
        // Arrange & Act
        final project = Project(
          id: 'project-1',
          name: 'My App',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
          metadata: {
            'lastOpened': now.toIso8601String(),
            'version': '1.0.0',
          },
        );

        // Assert
        expect(project.metadata, isNotEmpty);
        expect(project.metadata['version'], equals('1.0.0'));
      });
    });

    group('updateName', () {
      test('should update project name', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'Old Name',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final updated = project.updateName('New Name');

        // Assert
        expect(updated.name, equals('New Name'));
        expect(updated.id, equals(project.id));
        expect(updated.rootFolderId, equals(project.rootFolderId));
        expect(updated.updatedAt.isAfter(project.updatedAt), isTrue);
      });

      test('should not modify original project', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'Old Name',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        project.updateName('New Name');

        // Assert
        expect(project.name, equals('Old Name'));
      });

      test('should preserve other properties', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'Old Name',
          description: 'Project description',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
          settings: {'theme': 'dark'},
        );

        // Act
        final updated = project.updateName('New Name');

        // Assert
        expect(updated.description, equals('Project description'));
        expect(updated.settings['theme'], equals('dark'));
      });
    });

    group('updateDescription', () {
      test('should update project description', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'My App',
          description: 'Old description',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final updated = project.updateDescription('New description');

        // Assert
        expect(updated.description, equals('New description'));
        expect(updated.id, equals(project.id));
        expect(updated.name, equals(project.name));
        expect(updated.updatedAt.isAfter(project.updatedAt), isTrue);
      });

      test('should set description to null', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'My App',
          description: 'Some description',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final updated = project.updateDescription(null);

        // Assert
        expect(updated.description, isNull);
      });

      test('should not modify original project', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'My App',
          description: 'Old description',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        project.updateDescription('New description');

        // Assert
        expect(project.description, equals('Old description'));
      });
    });

    group('updateSettings', () {
      test('should update project settings', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'My App',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
          settings: {'theme': 'dark'},
        );

        // Act
        final updated = project.updateSettings({
          'theme': 'light',
          'fontSize': 14,
        });

        // Assert
        expect(updated.settings['theme'], equals('light'));
        expect(updated.settings['fontSize'], equals(14));
        expect(updated.updatedAt.isAfter(project.updatedAt), isTrue);
      });

      test('should replace all settings', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'My App',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
          settings: {'theme': 'dark', 'autoSave': true},
        );

        // Act
        final updated = project.updateSettings({'fontSize': 16});

        // Assert
        expect(updated.settings, equals({'fontSize': 16}));
        expect(updated.settings.containsKey('theme'), isFalse);
      });

      test('should not modify original project', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'My App',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
          settings: {'theme': 'dark'},
        );

        // Act
        project.updateSettings({'theme': 'light'});

        // Assert
        expect(project.settings['theme'], equals('dark'));
      });
    });

    group('copyWith', () {
      test('should copy with new name', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'Old Name',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final copied = project.copyWith(name: 'New Name');

        // Assert
        expect(copied.name, equals('New Name'));
        expect(copied.id, equals(project.id));
      });

      test('should copy with new metadata', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'My App',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Act
        final copied = project.copyWith(metadata: {'version': '2.0.0'});

        // Assert
        expect(copied.metadata['version'], equals('2.0.0'));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        // Arrange
        final project1 = Project(
          id: 'project-1',
          name: 'My App',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        final project2 = Project(
          id: 'project-1',
          name: 'My App',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(project1, equals(project2));
      });

      test('should not be equal with different IDs', () {
        // Arrange
        final project1 = Project(
          id: 'project-1',
          name: 'My App',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        final project2 = Project(
          id: 'project-2',
          name: 'My App',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(project1, isNot(equals(project2)));
      });

      test('should not be equal with different names', () {
        // Arrange
        final project1 = Project(
          id: 'project-1',
          name: 'App 1',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        final project2 = Project(
          id: 'project-1',
          name: 'App 2',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(project1, isNot(equals(project2)));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'My App',
          description: 'A Flutter app',
          rootFolderId: 'root-folder',
          createdAt: now,
          updatedAt: now,
          settings: {'theme': 'dark'},
        );

        // Act
        final json = project.toJson();

        // Assert
        expect(json['id'], equals('project-1'));
        expect(json['name'], equals('My App'));
        expect(json['description'], equals('A Flutter app'));
        expect(json['rootFolderId'], equals('root-folder'));
        expect(json['settings'], isA<Map>());
      });

      test('should deserialize from JSON', () {
        // Arrange
        final json = {
          'id': 'project-1',
          'name': 'My App',
          'description': 'A Flutter app',
          'rootFolderId': 'root-folder',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'settings': {'theme': 'dark'},
          'metadata': {},
        };

        // Act
        final project = Project.fromJson(json);

        // Assert
        expect(project.id, equals('project-1'));
        expect(project.name, equals('My App'));
        expect(project.description, equals('A Flutter app'));
        expect(project.settings['theme'], equals('dark'));
      });
    });

    group('use cases', () {
      test('should represent typical Flutter project', () {
        // Arrange
        final project = Project(
          id: 'flutter-app',
          name: 'my_flutter_app',
          description: 'A new Flutter project',
          rootFolderId: 'root',
          createdAt: now,
          updatedAt: now,
          settings: {
            'sdk': '>=3.0.0 <4.0.0',
            'formatter': 'dart_style',
            'linter': 'flutter_lints',
          },
          metadata: {
            'type': 'flutter',
            'platform': ['ios', 'android', 'web'],
          },
        );

        // Assert
        expect(project.name, equals('my_flutter_app'));
        expect(project.settings['sdk'], equals('>=3.0.0 <4.0.0'));
        expect(project.metadata['type'], equals('flutter'));
      });

      test('should handle project lifecycle', () {
        // Arrange - Create new project
        var project = Project(
          id: 'project-1',
          name: 'new_project',
          rootFolderId: 'root',
          createdAt: now,
          updatedAt: now,
        );

        expect(project.description, isNull);
        expect(project.settings, isEmpty);

        // Act - Update name
        project = project.updateName('renamed_project');
        expect(project.name, equals('renamed_project'));

        // Act - Add description
        project = project.updateDescription('Project for testing');
        expect(project.description, equals('Project for testing'));

        // Act - Configure settings
        project = project.updateSettings({
          'theme': 'dark',
          'autoSave': true,
          'tabSize': 2,
        });
        expect(project.settings['theme'], equals('dark'));
        expect(project.settings['autoSave'], equals(true));

        // Act - Update settings
        project = project.updateSettings({
          'theme': 'light',
          'autoSave': false,
        });
        expect(project.settings['theme'], equals('light'));
        expect(project.settings.containsKey('tabSize'), isFalse);
      });

      test('should track modification times', () {
        // Arrange
        final project = Project(
          id: 'project-1',
          name: 'My App',
          rootFolderId: 'root',
          createdAt: now,
          updatedAt: now,
        );

        final originalUpdatedAt = project.updatedAt;

        // Act - Wait and update
        Future.delayed(const Duration(milliseconds: 10));
        final renamed = project.updateName('New Name');

        // Assert
        expect(renamed.updatedAt.isAfter(originalUpdatedAt), isTrue);
        expect(renamed.createdAt, equals(project.createdAt));
      });
    });
  });
}
