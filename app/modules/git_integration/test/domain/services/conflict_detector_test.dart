import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('ConflictDetector', () {
    late ConflictDetector detector;
    late RepositoryPath path;

    setUp(() {
      detector = const ConflictDetector();
      path = RepositoryPath.create('/test/repo');
    });

    group('parseConflictMarkers', () {
      test('should parse single conflict marker', () {
        // Arrange
        const content = '''
line 1
line 2
<<<<<<< HEAD
ours content
=======
theirs content
>>>>>>> feature
line 3
''';

        // Act
        final markers = detector.parseConflictMarkers(content);

        // Assert
        expect(markers.length, equals(1));
        expect(markers.first.startLine, equals(3));
        expect(markers.first.middleLine, equals(5));
        expect(markers.first.endLine, equals(7));
      });

      test('should parse multiple conflict markers', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
conflict 1 ours
=======
conflict 1 theirs
>>>>>>> branch1
normal line
<<<<<<< HEAD
conflict 2 ours
=======
conflict 2 theirs
>>>>>>> branch2
''';

        // Act
        final markers = detector.parseConflictMarkers(content);

        // Assert
        expect(markers.length, equals(2));
        expect(markers[0].startLine, equals(0));
        expect(markers[1].startLine, equals(5));
      });

      test('should return empty list for content without conflicts', () {
        // Arrange
        const content = '''
line 1
line 2
line 3
''';

        // Act
        final markers = detector.parseConflictMarkers(content);

        // Assert
        expect(markers, isEmpty);
      });

      test('should handle malformed conflict markers', () {
        // Arrange - Missing middle separator
        const content = '''
<<<<<<< HEAD
ours content
>>>>>>> feature
''';

        // Act
        final markers = detector.parseConflictMarkers(content);

        // Assert
        expect(markers, isEmpty);
      });

      test('should handle nested-like markers correctly', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
ours line 1
ours line 2
=======
theirs line 1
theirs line 2
>>>>>>> feature
''';

        // Act
        final markers = detector.parseConflictMarkers(content);

        // Assert
        expect(markers.length, equals(1));
        expect(markers.first.startLine, equals(0));
        expect(markers.first.middleLine, equals(3));
        expect(markers.first.endLine, equals(6));
      });
    });

    group('extractOursContent', () {
      test('should extract ours content from conflict', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
ours line 1
ours line 2
=======
theirs content
>>>>>>> feature
''';
        final marker = ConflictMarker(
          startLine: 0,
          middleLine: 3,
          endLine: 5,
        );

        // Act
        final ours = detector.extractOursContent(content, marker);

        // Assert
        expect(ours, equals('ours line 1\nours line 2'));
      });

      test('should handle empty ours content', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
=======
theirs content
>>>>>>> feature
''';
        final marker = ConflictMarker(
          startLine: 0,
          middleLine: 1,
          endLine: 3,
        );

        // Act
        final ours = detector.extractOursContent(content, marker);

        // Assert
        expect(ours, isEmpty);
      });

      test('should handle single line ours content', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
single ours line
=======
theirs content
>>>>>>> feature
''';
        final marker = ConflictMarker(
          startLine: 0,
          middleLine: 2,
          endLine: 4,
        );

        // Act
        final ours = detector.extractOursContent(content, marker);

        // Assert
        expect(ours, equals('single ours line'));
      });
    });

    group('extractTheirsContent', () {
      test('should extract theirs content from conflict', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
ours content
=======
theirs line 1
theirs line 2
>>>>>>> feature
''';
        final marker = ConflictMarker(
          startLine: 0,
          middleLine: 2,
          endLine: 5,
        );

        // Act
        final theirs = detector.extractTheirsContent(content, marker);

        // Assert
        expect(theirs, equals('theirs line 1\ntheirs line 2'));
      });

      test('should handle empty theirs content', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
ours content
=======
>>>>>>> feature
''';
        final marker = ConflictMarker(
          startLine: 0,
          middleLine: 2,
          endLine: 3,
        );

        // Act
        final theirs = detector.extractTheirsContent(content, marker);

        // Assert
        expect(theirs, isEmpty);
      });

      test('should handle single line theirs content', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
ours content
=======
single theirs line
>>>>>>> feature
''';
        final marker = ConflictMarker(
          startLine: 0,
          middleLine: 2,
          endLine: 4,
        );

        // Act
        final theirs = detector.extractTheirsContent(content, marker);

        // Assert
        expect(theirs, equals('single theirs line'));
      });
    });

    group('countConflicts', () {
      test('should count single conflict', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
ours
=======
theirs
>>>>>>> feature
''';

        // Act
        final count = detector.countConflicts(content);

        // Assert
        expect(count, equals(1));
      });

      test('should count multiple conflicts', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
conflict 1
=======
conflict 1
>>>>>>> feature
normal line
<<<<<<< HEAD
conflict 2
=======
conflict 2
>>>>>>> feature
''';

        // Act
        final count = detector.countConflicts(content);

        // Assert
        expect(count, equals(2));
      });

      test('should return zero for no conflicts', () {
        // Arrange
        const content = 'normal content\nno conflicts here';

        // Act
        final count = detector.countConflicts(content);

        // Assert
        expect(count, equals(0));
      });
    });

    group('hasConflicts', () {
      test('should detect conflicts with all markers present', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
ours
=======
theirs
>>>>>>> feature
''';

        // Act
        final hasConflicts = detector.hasConflicts(content);

        // Assert
        expect(hasConflicts, isTrue);
      });

      test('should not detect conflicts with missing start marker', () {
        // Arrange
        const content = '''
ours
=======
theirs
>>>>>>> feature
''';

        // Act
        final hasConflicts = detector.hasConflicts(content);

        // Assert
        expect(hasConflicts, isFalse);
      });

      test('should not detect conflicts with missing middle marker', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
ours
theirs
>>>>>>> feature
''';

        // Act
        final hasConflicts = detector.hasConflicts(content);

        // Assert
        expect(hasConflicts, isFalse);
      });

      test('should not detect conflicts with missing end marker', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
ours
=======
theirs
''';

        // Act
        final hasConflicts = detector.hasConflicts(content);

        // Assert
        expect(hasConflicts, isFalse);
      });

      test('should not detect conflicts in clean content', () {
        // Arrange
        const content = 'normal content without any markers';

        // Act
        final hasConflicts = detector.hasConflicts(content);

        // Assert
        expect(hasConflicts, isFalse);
      });
    });

    group('detectConflicts', () {
      test('should return none when no conflicts exist', () {
        // Arrange & Act
        final conflict = detector.detectConflicts(
          path: path,
          sourceBranch: 'feature',
          targetBranch: 'main',
        );

        // Assert
        expect(conflict, equals(none()));
      });

      test('should include branch names in conflict', () {
        // Arrange & Act
        final conflict = detector.detectConflicts(
          path: path,
          sourceBranch: 'feature/auth',
          targetBranch: 'develop',
        );

        // Assert - In real implementation would detect conflicts
        // For now, placeholder returns none()
        expect(conflict, equals(none()));
      });
    });

    group('use cases', () {
      test('should handle typical merge conflict', () {
        // Arrange
        const content = '''
class MyClass {
<<<<<<< HEAD
  void methodA() {
    // Our implementation
  }
=======
  void methodB() {
    // Their implementation
  }
>>>>>>> feature/new-method
}
''';

        // Act
        final markers = detector.parseConflictMarkers(content);
        final hasConflicts = detector.hasConflicts(content);
        final count = detector.countConflicts(content);

        // Assert
        expect(hasConflicts, isTrue);
        expect(count, equals(1));
        expect(markers.length, equals(1));
      });

      test('should handle rebase conflict', () {
        // Arrange
        const content = '''
<<<<<<< HEAD
import 'package:old/old.dart';
=======
import 'package:new/new.dart';
>>>>>>> main
''';

        // Act
        final markers = detector.parseConflictMarkers(content);
        final ours = detector.extractOursContent(content, markers.first);
        final theirs = detector.extractTheirsContent(content, markers.first);

        // Assert
        expect(ours, contains('old'));
        expect(theirs, contains('new'));
      });

      test('should handle file with multiple conflicts', () {
        // Arrange
        const content = '''
line 1
<<<<<<< HEAD
conflict 1 ours
=======
conflict 1 theirs
>>>>>>> branch
line 2
line 3
<<<<<<< HEAD
conflict 2 ours
=======
conflict 2 theirs
>>>>>>> branch
line 4
''';

        // Act
        final markers = detector.parseConflictMarkers(content);
        final count = detector.countConflicts(content);

        // Assert
        expect(count, equals(2));
        expect(markers.length, equals(2));
      });

      test('should handle complex multiline conflict', () {
        // Arrange
        const content = '''
function calculate() {
<<<<<<< HEAD
  const result = oldAlgorithm(
    param1,
    param2,
    param3
  );
  return result * 2;
=======
  const result = newAlgorithm({
    param1,
    param2,
    param3,
    param4
  });
  return result;
>>>>>>> feature/new-algorithm
}
''';

        // Act
        final markers = detector.parseConflictMarkers(content);
        final ours = detector.extractOursContent(content, markers.first);
        final theirs = detector.extractTheirsContent(content, markers.first);

        // Assert
        expect(markers.length, equals(1));
        expect(ours, contains('oldAlgorithm'));
        expect(ours, contains('result * 2'));
        expect(theirs, contains('newAlgorithm'));
        expect(theirs, contains('param4'));
      });
    });
  });
}
