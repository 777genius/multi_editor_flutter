import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';

void main() {
  group('GitAuthor', () {
    group('creation with validation', () {
      test('should create valid author', () {
        // Act
        final author = GitAuthor.create(
          name: 'John Doe',
          email: 'john@example.com',
        );

        // Assert
        expect(author.name, equals('John Doe'));
        expect(author.email, equals('john@example.com'));
      });

      test('should trim whitespace from name', () {
        final author = GitAuthor.create(
          name: '  John Doe  ',
          email: 'john@example.com',
        );

        expect(author.name, equals('John Doe'));
      });

      test('should trim whitespace from email', () {
        final author = GitAuthor.create(
          name: 'John Doe',
          email: '  john@example.com  ',
        );

        expect(author.email, equals('john@example.com'));
      });
    });

    group('validation errors', () {
      test('should throw error for empty name', () {
        expect(
          () => GitAuthor.create(
            name: '',
            email: 'john@example.com',
          ),
          throwsA(isA<GitAuthorValidationException>()),
        );
      });

      test('should throw error for whitespace-only name', () {
        expect(
          () => GitAuthor.create(
            name: '   ',
            email: 'john@example.com',
          ),
          throwsA(isA<GitAuthorValidationException>()),
        );
      });

      test('should throw error for empty email', () {
        expect(
          () => GitAuthor.create(
            name: 'John Doe',
            email: '',
          ),
          throwsA(isA<GitAuthorValidationException>()),
        );
      });

      test('should throw error for whitespace-only email', () {
        expect(
          () => GitAuthor.create(
            name: 'John Doe',
            email: '   ',
          ),
          throwsA(isA<GitAuthorValidationException>()),
        );
      });

      test('should throw error for email without @', () {
        expect(
          () => GitAuthor.create(
            name: 'John Doe',
            email: 'johnexample.com',
          ),
          throwsA(isA<GitAuthorValidationException>()),
        );
      });

      test('should throw error for email without domain', () {
        expect(
          () => GitAuthor.create(
            name: 'John Doe',
            email: 'john@example',
          ),
          throwsA(isA<GitAuthorValidationException>()),
        );
      });

      test('should throw error with descriptive message', () {
        try {
          GitAuthor.create(
            name: 'John Doe',
            email: 'invalid-email',
          );
          fail('Should have thrown exception');
        } catch (e) {
          expect(e, isA<GitAuthorValidationException>());
          expect(e.toString(), contains('Invalid email format'));
        }
      });
    });

    group('parse from git format', () {
      test('should parse standard git format', () {
        // Act
        final author = GitAuthor.parse('John Doe <john@example.com>');

        // Assert
        expect(author.name, equals('John Doe'));
        expect(author.email, equals('john@example.com'));
      });

      test('should parse with extra whitespace', () {
        final author = GitAuthor.parse('  John Doe  <  john@example.com  >');

        expect(author.name, equals('John Doe'));
        expect(author.email, equals('john@example.com'));
      });

      test('should parse name with multiple words', () {
        final author = GitAuthor.parse('John Michael Doe <john@example.com>');

        expect(author.name, equals('John Michael Doe'));
      });

      test('should throw error for invalid format', () {
        expect(
          () => GitAuthor.parse('Invalid Format'),
          throwsA(isA<GitAuthorValidationException>()),
        );
      });

      test('should throw error for missing email brackets', () {
        expect(
          () => GitAuthor.parse('John Doe john@example.com'),
          throwsA(isA<GitAuthorValidationException>()),
        );
      });

      test('should throw error with descriptive message for invalid format', () {
        try {
          GitAuthor.parse('Not A Valid Format');
          fail('Should have thrown exception');
        } catch (e) {
          expect(e, isA<GitAuthorValidationException>());
          expect(e.toString(), contains('Invalid git author format'));
        }
      });
    });

    group('toGitFormat', () {
      test('should format as git standard', () {
        final author = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        expect(author.toGitFormat(), equals('John Doe <john@example.com>'));
      });

      test('should match display property', () {
        final author = const GitAuthor(
          name: 'Jane Smith',
          email: 'jane@example.com',
        );

        expect(author.display, equals(author.toGitFormat()));
      });
    });

    group('initials', () {
      test('should extract initials from two-word name', () {
        final author = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        expect(author.initials, equals('JD'));
      });

      test('should extract initial from single-word name', () {
        final author = const GitAuthor(
          name: 'John',
          email: 'john@example.com',
        );

        expect(author.initials, equals('J'));
      });

      test('should extract initials from multi-word name (first two)', () {
        final author = const GitAuthor(
          name: 'John Michael Doe',
          email: 'john@example.com',
        );

        expect(author.initials, equals('JM'));
      });

      test('should uppercase initials', () {
        final author = const GitAuthor(
          name: 'john doe',
          email: 'john@example.com',
        );

        expect(author.initials, equals('JD'));
      });

      test('should handle empty name gracefully', () {
        final author = const GitAuthor(
          name: '',
          email: 'john@example.com',
        );

        expect(author.initials, isEmpty);
      });
    });

    group('emailDomain', () {
      test('should extract domain from email', () {
        final author = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        expect(author.emailDomain, equals('example.com'));
      });

      test('should extract domain from corporate email', () {
        final author = const GitAuthor(
          name: 'John Doe',
          email: 'john.doe@company.org',
        );

        expect(author.emailDomain, equals('company.org'));
      });

      test('should extract subdomain', () {
        final author = const GitAuthor(
          name: 'John Doe',
          email: 'john@mail.example.com',
        );

        expect(author.emailDomain, equals('mail.example.com'));
      });

      test('should return empty for malformed email', () {
        final author = const GitAuthor(
          name: 'John Doe',
          email: 'invalid-email',
        );

        expect(author.emailDomain, isEmpty);
      });
    });

    group('isSamePerson', () {
      test('should match same person with identical email', () {
        final author1 = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final author2 = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        expect(author1.isSamePerson(author2), isTrue);
      });

      test('should match same person with case-insensitive email', () {
        final author1 = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final author2 = const GitAuthor(
          name: 'John Doe',
          email: 'JOHN@EXAMPLE.COM',
        );

        expect(author1.isSamePerson(author2), isTrue);
      });

      test('should match same person despite different name', () {
        final author1 = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final author2 = const GitAuthor(
          name: 'J. Doe',
          email: 'john@example.com',
        );

        expect(author1.isSamePerson(author2), isTrue);
      });

      test('should not match different people', () {
        final author1 = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final author2 = const GitAuthor(
          name: 'Jane Smith',
          email: 'jane@example.com',
        );

        expect(author1.isSamePerson(author2), isFalse);
      });
    });

    group('equality', () {
      test('should be equal with same name and email', () {
        final author1 = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final author2 = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        expect(author1, equals(author2));
      });

      test('should not be equal with different name', () {
        final author1 = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final author2 = const GitAuthor(
          name: 'Jane Doe',
          email: 'john@example.com',
        );

        expect(author1, isNot(equals(author2)));
      });

      test('should not be equal with different email', () {
        final author1 = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final author2 = const GitAuthor(
          name: 'John Doe',
          email: 'john@other.com',
        );

        expect(author1, isNot(equals(author2)));
      });

      test('should have same hashCode for equal authors', () {
        final author1 = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final author2 = const GitAuthor(
          name: 'John Doe',
          email: 'john@example.com',
        );

        expect(author1.hashCode, equals(author2.hashCode));
      });
    });

    group('roundtrip', () {
      test('should roundtrip through git format', () {
        final original = GitAuthor.create(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final gitFormat = original.toGitFormat();
        final parsed = GitAuthor.parse(gitFormat);

        expect(parsed, equals(original));
      });

      test('should roundtrip with complex name', () {
        final original = GitAuthor.create(
          name: 'Dr. John Michael Doe Jr.',
          email: 'john.doe@university.edu',
        );

        final gitFormat = original.toGitFormat();
        final parsed = GitAuthor.parse(gitFormat);

        expect(parsed.name, equals(original.name));
        expect(parsed.email, equals(original.email));
      });
    });

    group('use cases', () {
      test('should represent typical developer', () {
        final author = GitAuthor.create(
          name: 'Alice Johnson',
          email: 'alice@company.com',
        );

        expect(author.initials, equals('AJ'));
        expect(author.emailDomain, equals('company.com'));
        expect(author.display, equals('Alice Johnson <alice@company.com>'));
      });

      test('should handle commit author from git log', () {
        final gitLogAuthor = 'Bob Smith <bob.smith@github.com>';

        final author = GitAuthor.parse(gitLogAuthor);

        expect(author.name, equals('Bob Smith'));
        expect(author.email, equals('bob.smith@github.com'));
        expect(author.initials, equals('BS'));
      });

      test('should identify same contributor across commits', () {
        final commit1Author = GitAuthor.parse('John <john@example.com>');
        final commit2Author = GitAuthor.parse('John Doe <john@example.com>');

        expect(commit1Author.isSamePerson(commit2Author), isTrue);
      });

      test('should work with corporate email conventions', () {
        final author = GitAuthor.create(
          name: 'Jane Smith',
          email: 'jane.smith@company.corp.com',
        );

        expect(author.emailDomain, equals('company.corp.com'));
      });
    });

    group('GitAuthorValidationException', () {
      test('should have descriptive string representation', () {
        final exception = GitAuthorValidationException('Test error');

        expect(exception.toString(), contains('GitAuthorValidationException'));
        expect(exception.toString(), contains('Test error'));
      });

      test('should preserve error message', () {
        final message = 'Invalid author data';
        final exception = GitAuthorValidationException(message);

        expect(exception.message, equals(message));
      });
    });
  });
}
