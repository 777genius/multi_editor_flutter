import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';

void main() {
  group('CodeLens', () {
    late TextSelection range;

    setUp(() {
      range = const TextSelection(
        start: CursorPosition(line: 10, column: 0),
        end: CursorPosition(line: 10, column: 20),
      );
    });

    group('creation', () {
      test('should create code lens with range only', () {
        // Act
        final codeLens = CodeLens(range: range);

        // Assert
        expect(codeLens.range, equals(range));
        expect(codeLens.command, isNull);
        expect(codeLens.data, isNull);
      });

      test('should create code lens with command', () {
        // Arrange
        const command = Command(
          title: '5 references',
          command: 'editor.action.showReferences',
        );

        // Act
        final codeLens = CodeLens(
          range: range,
          command: command,
        );

        // Assert
        expect(codeLens.range, equals(range));
        expect(codeLens.command, equals(command));
      });

      test('should create code lens with data', () {
        // Arrange
        final data = {'uri': 'file:///test.dart', 'line': 10};

        // Act
        final codeLens = CodeLens(
          range: range,
          data: data,
        );

        // Assert
        expect(codeLens.data, equals(data));
      });
    });

    group('equality', () {
      test('should be equal with same range and command', () {
        const command = Command(title: 'Test', command: 'test.command');

        final lens1 = CodeLens(range: range, command: command);
        final lens2 = CodeLens(range: range, command: command);

        expect(lens1, equals(lens2));
      });

      test('should not be equal with different range', () {
        const command = Command(title: 'Test', command: 'test.command');

        final lens1 = CodeLens(range: range, command: command);
        final lens2 = CodeLens(
          range: const TextSelection(
            start: CursorPosition(line: 20, column: 0),
            end: CursorPosition(line: 20, column: 20),
          ),
          command: command,
        );

        expect(lens1, isNot(equals(lens2)));
      });
    });

    group('common use cases', () {
      test('should represent references code lens', () {
        const command = Command(
          title: '5 references',
          command: 'editor.action.showReferences',
          arguments: ['file:///test.dart', 10, 5],
        );

        final codeLens = CodeLens(
          range: range,
          command: command,
        );

        expect(codeLens.command!.title, contains('references'));
        expect(codeLens.command!.arguments, isNotNull);
        expect(codeLens.command!.arguments!.length, equals(3));
      });

      test('should represent test runner code lens', () {
        const command = Command(
          title: 'Run Test',
          command: 'dart.runTest',
        );

        final codeLens = CodeLens(
          range: range,
          command: command,
        );

        expect(codeLens.command!.title, equals('Run Test'));
        expect(codeLens.command!.command, equals('dart.runTest'));
      });

      test('should represent debug code lens', () {
        const command = Command(
          title: 'Debug',
          command: 'dart.debugTest',
        );

        final codeLens = CodeLens(
          range: range,
          command: command,
        );

        expect(codeLens.command!.title, equals('Debug'));
      });
    });
  });

  group('Command', () {
    group('creation', () {
      test('should create command with title and command', () {
        // Act
        const command = Command(
          title: 'Show References',
          command: 'editor.action.showReferences',
        );

        // Assert
        expect(command.title, equals('Show References'));
        expect(command.command, equals('editor.action.showReferences'));
        expect(command.arguments, isNull);
      });

      test('should create command with arguments', () {
        // Act
        const command = Command(
          title: 'Rename',
          command: 'editor.action.rename',
          arguments: ['newName'],
        );

        // Assert
        expect(command.arguments, isNotNull);
        expect(command.arguments!.length, equals(1));
        expect(command.arguments![0], equals('newName'));
      });

      test('should handle various argument types', () {
        const command = Command(
          title: 'Complex Command',
          command: 'test.command',
          arguments: [
            'string',
            42,
            true,
            {'key': 'value'},
          ],
        );

        expect(command.arguments!.length, equals(4));
        expect(command.arguments![0], isA<String>());
        expect(command.arguments![1], isA<int>());
        expect(command.arguments![2], isA<bool>());
        expect(command.arguments![3], isA<Map>());
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        const cmd1 = Command(
          title: 'Test',
          command: 'test.command',
          arguments: ['arg1'],
        );

        const cmd2 = Command(
          title: 'Test',
          command: 'test.command',
          arguments: ['arg1'],
        );

        expect(cmd1, equals(cmd2));
      });

      test('should not be equal with different command', () {
        const cmd1 = Command(title: 'Test', command: 'command1');
        const cmd2 = Command(title: 'Test', command: 'command2');

        expect(cmd1, isNot(equals(cmd2)));
      });

      test('should not be equal with different arguments', () {
        const cmd1 = Command(
          title: 'Test',
          command: 'test',
          arguments: ['arg1'],
        );

        const cmd2 = Command(
          title: 'Test',
          command: 'test',
          arguments: ['arg2'],
        );

        expect(cmd1, isNot(equals(cmd2)));
      });
    });

    group('copyWith', () {
      test('should copy with new title', () {
        const command = Command(
          title: 'Original',
          command: 'test.command',
        );

        final copied = command.copyWith(title: 'Updated');

        expect(copied.title, equals('Updated'));
        expect(copied.command, equals(command.command));
      });

      test('should copy with new arguments', () {
        const command = Command(
          title: 'Test',
          command: 'test.command',
          arguments: ['old'],
        );

        final copied = command.copyWith(arguments: ['new']);

        expect(copied.arguments, equals(['new']));
        expect(command.arguments, equals(['old']));
      });
    });
  });
}
