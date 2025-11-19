# Example Tests - Patterns and Best Practices

This document shows example test patterns used in the comprehensive test suite.

## AAA Pattern Examples

### Basic CRUD Test
```dart
test('should create a new file with all parameters', () async {
  // Arrange
  const folderId = 'folder_1';
  const name = 'test.dart';
  const content = 'void main() {}';
  const language = 'dart';
  final metadata = {'author': 'test'};

  // Act
  final result = await repository.create(
    folderId: folderId,
    name: name,
    initialContent: content,
    language: language,
    metadata: metadata,
  );

  // Assert
  expect(result.isRight(), isTrue);
  result.fold(
    (failure) => fail('Expected Right but got Left: $failure'),
    (file) {
      expect(file.id, isNotEmpty);
      expect(file.name, equals(name));
      expect(file.folderId, equals(folderId));
      expect(file.content, equals(content));
      expect(file.language, equals(language));
      expect(file.metadata, equals(metadata));
    },
  );
});
```

### Error Handling Test
```dart
test('should return not found failure for non-existent file', () async {
  // Arrange
  const nonExistentId = 'file_999';

  // Act
  final result = await repository.load(nonExistentId);

  // Assert
  expect(result.isLeft(), isTrue);
  result.fold(
    (failure) {
      expect(failure, isA<DomainFailure>());
      expect(failure.type, equals(FailureType.notFound));
      expect(failure.entityType, equals('FileDocument'));
      expect(failure.entityId, equals(nonExistentId));
    },
    (file) => fail('Expected Left but got Right'),
  );
});
```

### Stream/Watcher Test
```dart
test('should notify watchers when file is saved', () async {
  // Arrange
  final created = await repository.create(
    folderId: 'folder_1',
    name: 'test.txt',
    initialContent: 'old',
  );
  var file = created.getOrElse(() => throw Exception());

  final stream = repository.watch(file.id);
  final events = <Either<DomainFailure, FileDocument>>[];
  final subscription = stream.listen(events.add);

  await Future.delayed(const Duration(milliseconds: 100));
  events.clear(); // Clear initial event

  // Act
  final updated = file.updateContent('new');
  await repository.save(updated);
  await Future.delayed(const Duration(milliseconds: 100));

  // Assert
  expect(events.length, greaterThan(0));
  events.last.fold(
    (failure) => fail('Expected Right but got Left'),
    (file) {
      expect(file.content, equals('new'));
    },
  );

  await subscription.cancel();
});
```

### Concurrent Operations Test
```dart
test('should handle concurrent creates', () async {
  // Arrange & Act
  final futures = List.generate(
    10,
    (i) => repository.create(
      folderId: 'folder_1',
      name: 'file_$i.txt',
    ),
  );

  final results = await Future.wait(futures);

  // Assert
  expect(results.every((r) => r.isRight()), isTrue);
  final ids = results
      .map((r) => r.getOrElse(() => throw Exception()).id)
      .toSet();
  expect(ids.length, equals(10)); // All IDs should be unique
});
```

### Validation Test
```dart
test('should reject name longer than 255 characters', () {
  // Arrange
  final name = 'a' * 256;

  // Act
  final result = service.validateFileName(name);

  // Assert
  expect(result.isLeft(), isTrue);
  result.fold(
    (failure) {
      expect(failure.type, equals(FailureType.validationError));
      expect(failure.reason, contains('too long'));
      expect(failure.reason, contains('255'));
    },
    (_) => fail('Expected Left but got Right'),
  );
});
```

## Test Organization Patterns

### Grouped by Feature
```dart
group('MockFileRepository', () {
  late MockFileRepository repository;

  setUp(() {
    repository = MockFileRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  group('create', () {
    // All create-related tests
  });

  group('load', () {
    // All load-related tests
  });

  // ... more groups
});
```

### Valid vs Invalid Inputs
```dart
group('validateFileName', () {
  group('valid file names', () {
    test('should accept simple alphanumeric name', () { /* ... */ });
    test('should accept name with dots', () { /* ... */ });
    // More valid cases...
  });

  group('invalid file names', () {
    test('should reject empty name', () { /* ... */ });
    test('should reject name with spaces', () { /* ... */ });
    // More invalid cases...
  });
});
```

## Best Practices Demonstrated

### 1. Clear Test Names
```dart
// ✅ Good - describes what and why
test('should return not found failure for non-existent project')

// ❌ Bad - unclear intent
test('test load')
```

### 2. Single Assertion Focus
```dart
// ✅ Good - tests one thing
test('should generate unique IDs for multiple files', () {
  // Only tests ID uniqueness
});

test('should create file with all properties', () {
  // Only tests property assignment
});

// ❌ Bad - tests multiple unrelated things
test('should create and delete and update', () {
  // Tests too many things
});
```

### 3. Proper Cleanup
```dart
group('Repository Tests', () {
  late Repository repository;

  setUp(() {
    repository = Repository(); // Fresh instance each test
  });

  tearDown(() {
    repository.dispose(); // Cleanup after each test
  });
});
```

### 4. Using Either Pattern
```dart
// ✅ Good - properly handles Either
result.fold(
  (failure) {
    // Check failure details
    expect(failure.type, equals(FailureType.notFound));
  },
  (value) => fail('Expected Left but got Right'),
);

// Or for success case
result.fold(
  (failure) => fail('Expected Right but got Left'),
  (value) {
    // Check success value
    expect(value.id, isNotEmpty);
  },
);
```

### 5. Testing Async Operations
```dart
test('should handle async delays', () async {
  // Arrange
  final stopwatch = Stopwatch()..start();

  // Act
  await repository.create(name: 'test');
  stopwatch.stop();

  // Assert
  expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
});
```

### 6. Testing Streams
```dart
test('should emit multiple events', () async {
  // Arrange
  final stream = repository.watch(id);
  final events = <Event>[];
  final subscription = stream.listen(events.add);

  // Act
  await performOperations();
  await Future.delayed(const Duration(milliseconds: 100));

  // Assert
  expect(events.length, greaterThan(0));

  // Cleanup
  await subscription.cancel();
});
```

### 7. Edge Case Testing
```dart
test('should handle boundary values', () {
  // Test exactly at limit
  final atLimit = 'a' * 255;
  expect(service.validate(atLimit).isRight(), isTrue);

  // Test one over limit
  final overLimit = 'a' * 256;
  expect(service.validate(overLimit).isLeft(), isTrue);
});
```

## Integration Test Example

```dart
test('should validate complete file creation workflow', () {
  // Arrange
  const fileName = 'test_file.dart';
  const filePath = '/project/src/test_file.dart';
  const fileContent = 'void main() {}';

  // Act & Assert - validate each step
  expect(service.validateFileName(fileName).isRight(), isTrue);
  expect(service.validateFilePath(filePath).isRight(), isTrue);
  expect(service.validateFileContent(fileContent).isRight(), isTrue);
  expect(service.hasValidExtension(fileName), isTrue);
  expect(service.isValidLanguage('dart'), isTrue);
});
```

## Parametrized Test Pattern

```dart
test('should reject all special characters', () {
  // Arrange
  final invalidChars = ['@', '#', '\$', '%', '^', '&', '*'];

  // Act & Assert
  for (final char in invalidChars) {
    final name = 'test${char}file';
    final result = service.validateFileName(name);

    expect(result.isLeft(), isTrue,
        reason: 'Should reject "$char"');
  }
});
```

## Summary

The test suite demonstrates:
- ✅ AAA pattern for clarity
- ✅ Proper async handling
- ✅ Stream testing techniques
- ✅ Error path verification
- ✅ Edge case coverage
- ✅ Concurrent operation testing
- ✅ Resource cleanup
- ✅ Integration testing
- ✅ Parametrized testing
- ✅ Clear naming conventions

All patterns are production-ready and follow Flutter/Dart testing best practices.
