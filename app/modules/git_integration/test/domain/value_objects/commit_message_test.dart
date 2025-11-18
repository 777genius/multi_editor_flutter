import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('CommitMessage', () {
    group('creation with validation', () {
      test('should create valid commit message', () {
        // Arrange & Act
        final message = CommitMessage.create('Add new feature');

        // Assert
        expect(message.value, equals('Add new feature'));
      });

      test('should trim whitespace', () {
        // Arrange & Act
        final message = CommitMessage.create('  Add new feature  ');

        // Assert
        expect(message.value, equals('Add new feature'));
      });

      test('should normalize line endings', () {
        // Arrange & Act
        final message = CommitMessage.create('Subject\r\n\r\nBody text');

        // Assert
        expect(message.value, equals('Subject\n\nBody text'));
      });

      test('should create message with body', () {
        // Arrange & Act
        final message = CommitMessage.create(
          'feat: add authentication\n\nImplemented OAuth2 login flow',
        );

        // Assert
        expect(message.subject, equals('feat: add authentication'));
        expect(message.hasBody, isTrue);
      });
    });

    group('validation errors', () {
      test('should throw error for empty message', () {
        // Act & Assert
        expect(
          () => CommitMessage.create(''),
          throwsA(isA<CommitMessageValidationException>()),
        );
      });

      test('should throw error for whitespace-only message', () {
        // Act & Assert
        expect(
          () => CommitMessage.create('   '),
          throwsA(isA<CommitMessageValidationException>()),
        );
      });

      test('should throw error for message with only newlines', () {
        // Act & Assert
        expect(
          () => CommitMessage.create('\n\n'),
          throwsA(isA<CommitMessageValidationException>()),
        );
      });
    });

    group('subject', () {
      test('should extract subject from single-line message', () {
        // Arrange
        final message = CommitMessage.create('Add new feature');

        // Act
        final subject = message.subject;

        // Assert
        expect(subject, equals('Add new feature'));
      });

      test('should extract subject from multi-line message', () {
        // Arrange
        final message = CommitMessage.create(
          'feat: add authentication\n\nDetailed body text',
        );

        // Act
        final subject = message.subject;

        // Assert
        expect(subject, equals('feat: add authentication'));
      });

      test('should trim whitespace from subject', () {
        // Arrange
        final message = CommitMessage.create('  Subject  \n\nBody');

        // Act
        final subject = message.subject;

        // Assert
        expect(subject, equals('Subject'));
      });
    });

    group('body', () {
      test('should return none for single-line message', () {
        // Arrange
        final message = CommitMessage.create('Add new feature');

        // Act
        final body = message.body;

        // Assert
        expect(body, equals(none()));
      });

      test('should extract body from multi-line message', () {
        // Arrange
        final message = CommitMessage.create(
          'Subject\n\nThis is the body text',
        );

        // Act
        final body = message.body;

        // Assert
        expect(body, equals(some('This is the body text')));
      });

      test('should handle body with multiple paragraphs', () {
        // Arrange
        final message = CommitMessage.create(
          'Subject\n\nFirst paragraph\n\nSecond paragraph',
        );

        // Act
        final body = message.body;

        // Assert
        expect(body, equals(some('First paragraph\n\nSecond paragraph')));
      });

      test('should return none when only blank lines after subject', () {
        // Arrange
        final message = CommitMessage.create('Subject\n\n   \n\n');

        // Act
        final body = message.body;

        // Assert
        expect(body, equals(none()));
      });

      test('should trim body text', () {
        // Arrange
        final message = CommitMessage.create(
          'Subject\n\n  Body text  \n\n',
        );

        // Act
        final body = message.body;

        // Assert
        expect(body, equals(some('Body text')));
      });
    });

    group('isConventional', () {
      test('should detect feat conventional commit', () {
        // Arrange
        final message = CommitMessage.create('feat: add new feature');

        // Act & Assert
        expect(message.isConventional, isTrue);
      });

      test('should detect fix conventional commit', () {
        // Arrange
        final message = CommitMessage.create('fix: resolve bug');

        // Act & Assert
        expect(message.isConventional, isTrue);
      });

      test('should detect docs conventional commit', () {
        // Arrange
        final message = CommitMessage.create('docs: update README');

        // Act & Assert
        expect(message.isConventional, isTrue);
      });

      test('should detect conventional commit with scope', () {
        // Arrange
        final message = CommitMessage.create('feat(auth): add login');

        // Act & Assert
        expect(message.isConventional, isTrue);
      });

      test('should detect refactor conventional commit', () {
        // Arrange
        final message = CommitMessage.create('refactor: improve code structure');

        // Act & Assert
        expect(message.isConventional, isTrue);
      });

      test('should detect test conventional commit', () {
        // Arrange
        final message = CommitMessage.create('test: add unit tests');

        // Act & Assert
        expect(message.isConventional, isTrue);
      });

      test('should detect chore conventional commit', () {
        // Arrange
        final message = CommitMessage.create('chore: update dependencies');

        // Act & Assert
        expect(message.isConventional, isTrue);
      });

      test('should not detect non-conventional commit', () {
        // Arrange
        final message = CommitMessage.create('Add new feature');

        // Act & Assert
        expect(message.isConventional, isFalse);
      });

      test('should not detect malformed conventional commit', () {
        // Arrange
        final message = CommitMessage.create('feat add feature');

        // Act & Assert
        expect(message.isConventional, isFalse);
      });
    });

    group('conventionalType', () {
      test('should extract type from conventional commit', () {
        // Arrange
        final message = CommitMessage.create('feat: add feature');

        // Act
        final type = message.conventionalType;

        // Assert
        expect(type, equals(some('feat')));
      });

      test('should extract type from commit with scope', () {
        // Arrange
        final message = CommitMessage.create('fix(auth): resolve bug');

        // Act
        final type = message.conventionalType;

        // Assert
        expect(type, equals(some('fix')));
      });

      test('should return none for non-conventional commit', () {
        // Arrange
        final message = CommitMessage.create('Add new feature');

        // Act
        final type = message.conventionalType;

        // Assert
        expect(type, equals(none()));
      });
    });

    group('conventionalScope', () {
      test('should extract scope from conventional commit', () {
        // Arrange
        final message = CommitMessage.create('feat(auth): add login');

        // Act
        final scope = message.conventionalScope;

        // Assert
        expect(scope, equals(some('auth')));
      });

      test('should return none for commit without scope', () {
        // Arrange
        final message = CommitMessage.create('feat: add feature');

        // Act
        final scope = message.conventionalScope;

        // Assert
        expect(scope, equals(none()));
      });

      test('should extract complex scope', () {
        // Arrange
        final message = CommitMessage.create('fix(user-auth): resolve issue');

        // Act
        final scope = message.conventionalScope;

        // Assert
        expect(scope, equals(some('user-auth')));
      });

      test('should return none for non-conventional commit', () {
        // Arrange
        final message = CommitMessage.create('Add feature');

        // Act
        final scope = message.conventionalScope;

        // Assert
        expect(scope, equals(none()));
      });
    });

    group('subjectLength', () {
      test('should return correct subject length', () {
        // Arrange
        final message = CommitMessage.create('Add new feature');

        // Act
        final length = message.subjectLength;

        // Assert
        expect(length, equals(15));
      });

      test('should not include body in length', () {
        // Arrange
        final message = CommitMessage.create('Subject\n\nVery long body text');

        // Act
        final length = message.subjectLength;

        // Assert
        expect(length, equals(7));
      });
    });

    group('isSubjectTooLong', () {
      test('should detect short subject as not too long', () {
        // Arrange
        final message = CommitMessage.create('Short subject');

        // Act & Assert
        expect(message.isSubjectTooLong, isFalse);
      });

      test('should detect exact 72 chars as not too long', () {
        // Arrange
        final subject = 'a' * 72;
        final message = CommitMessage.create(subject);

        // Act & Assert
        expect(message.isSubjectTooLong, isFalse);
      });

      test('should detect 73 chars as too long', () {
        // Arrange
        final subject = 'a' * 73;
        final message = CommitMessage.create(subject);

        // Act & Assert
        expect(message.isSubjectTooLong, isTrue);
      });

      test('should detect very long subject as too long', () {
        // Arrange
        final subject = 'a' * 100;
        final message = CommitMessage.create(subject);

        // Act & Assert
        expect(message.isSubjectTooLong, isTrue);
      });
    });

    group('hasBody', () {
      test('should return false for single-line message', () {
        // Arrange
        final message = CommitMessage.create('Subject');

        // Act & Assert
        expect(message.hasBody, isFalse);
      });

      test('should return true for message with body', () {
        // Arrange
        final message = CommitMessage.create('Subject\n\nBody');

        // Act & Assert
        expect(message.hasBody, isTrue);
      });
    });

    group('formatForDisplay', () {
      test('should not truncate short subject', () {
        // Arrange
        final message = CommitMessage.create('Short subject');

        // Act
        final formatted = message.formatForDisplay();

        // Assert
        expect(formatted, equals('Short subject'));
      });

      test('should truncate long subject at default 72 chars', () {
        // Arrange
        final subject = 'a' * 80;
        final message = CommitMessage.create(subject);

        // Act
        final formatted = message.formatForDisplay();

        // Assert
        expect(formatted.length, equals(72));
        expect(formatted, endsWith('...'));
      });

      test('should truncate at custom max length', () {
        // Arrange
        final subject = 'This is a very long subject that should be truncated';
        final message = CommitMessage.create(subject);

        // Act
        final formatted = message.formatForDisplay(maxLength: 20);

        // Assert
        expect(formatted.length, equals(20));
        expect(formatted, endsWith('...'));
      });

      test('should preserve subject at exact max length', () {
        // Arrange
        final subject = 'a' * 50;
        final message = CommitMessage.create(subject);

        // Act
        final formatted = message.formatForDisplay(maxLength: 50);

        // Assert
        expect(formatted, equals(subject));
      });
    });

    group('equality', () {
      test('should be equal with same value', () {
        // Arrange
        final message1 = CommitMessage.create('Add feature');
        final message2 = CommitMessage.create('Add feature');

        // Act & Assert
        expect(message1, equals(message2));
      });

      test('should not be equal with different values', () {
        // Arrange
        final message1 = CommitMessage.create('Add feature');
        final message2 = CommitMessage.create('Fix bug');

        // Act & Assert
        expect(message1, isNot(equals(message2)));
      });
    });

    group('use cases', () {
      test('should handle typical feature commit', () {
        // Arrange & Act
        final message = CommitMessage.create(
          'feat(auth): add OAuth2 authentication\n\nImplemented login flow with Google and GitHub providers',
        );

        // Assert
        expect(message.isConventional, isTrue);
        expect(message.conventionalType, equals(some('feat')));
        expect(message.conventionalScope, equals(some('auth')));
        expect(message.hasBody, isTrue);
        expect(message.isSubjectTooLong, isFalse);
      });

      test('should handle simple commit without body', () {
        // Arrange & Act
        final message = CommitMessage.create('Fix typo in README');

        // Assert
        expect(message.isConventional, isFalse);
        expect(message.hasBody, isFalse);
        expect(message.subject, equals('Fix typo in README'));
      });

      test('should handle conventional commit without scope', () {
        // Arrange & Act
        final message = CommitMessage.create('docs: update installation guide');

        // Assert
        expect(message.isConventional, isTrue);
        expect(message.conventionalType, equals(some('docs')));
        expect(message.conventionalScope, equals(none()));
      });

      test('should handle breaking change commit', () {
        // Arrange & Act
        final message = CommitMessage.create(
          'feat!: redesign API\n\nBREAKING CHANGE: API endpoints have changed',
        );

        // Assert
        expect(message.isConventional, isFalse); // '!' makes it non-standard
        expect(message.hasBody, isTrue);
      });

      test('should handle merge commit message', () {
        // Arrange & Act
        final message = CommitMessage.create(
          'Merge branch feature/auth into main',
        );

        // Assert
        expect(message.isConventional, isFalse);
        expect(message.subject, contains('Merge'));
      });
    });

    group('CommitMessageValidationException', () {
      test('should have descriptive string representation', () {
        // Arrange
        final exception = CommitMessageValidationException('Test error');

        // Act & Assert
        expect(
          exception.toString(),
          contains('CommitMessageValidationException'),
        );
        expect(exception.toString(), contains('Test error'));
      });

      test('should preserve error message', () {
        // Arrange
        final message = 'Invalid commit message';
        final exception = CommitMessageValidationException(message);

        // Act & Assert
        expect(exception.message, equals(message));
      });
    });
  });
}
