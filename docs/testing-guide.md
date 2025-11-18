# Testing Guide - VS Code Runtime Management System

Comprehensive testing documentation for all layers of the VS Code runtime management system.

## Table of Contents

1. [Testing Philosophy](#testing-philosophy)
2. [Test Structure](#test-structure)
3. [Running Tests](#running-tests)
4. [Domain Layer Tests](#domain-layer-tests)
5. [Application Layer Tests](#application-layer-tests)
6. [Presentation Layer Tests](#presentation-layer-tests)
7. [Integration Tests](#integration-tests)
8. [Test Utilities](#test-utilities)
9. [Mocking Strategy](#mocking-strategy)
10. [Coverage](#coverage)

---

## Testing Philosophy

This project follows a comprehensive testing strategy that covers:

- **Unit Tests**: Testing individual components in isolation
- **Integration Tests**: Testing interactions between layers
- **Widget Tests**: Testing UI components and state management
- **End-to-End Tests**: Testing complete user flows

### Key Principles

✅ **Test Behavior, Not Implementation**: Focus on what the code does, not how it does it
✅ **Arrange-Act-Assert Pattern**: Structure tests for clarity
✅ **Independent Tests**: Each test should be able to run independently
✅ **Fast Execution**: Tests should run quickly to enable TDD
✅ **Meaningful Names**: Test names should describe what they test

---

## Test Structure

```
packages/
├── vscode_runtime_core/
│   └── test/
│       ├── domain/
│       │   ├── aggregates/
│       │   │   └── runtime_installation_test.dart
│       │   └── value_objects/
│       │       └── runtime_version_test.dart
│       └── helpers/
│           └── test_fixtures.dart
│
├── vscode_runtime_application/
│   └── test/
│       ├── handlers/
│       │   ├── install_runtime_command_handler_test.dart
│       │   ├── cancel_installation_command_handler_test.dart
│       │   └── get_runtime_status_query_handler_test.dart
│       ├── mocks/
│       │   ├── mock_repositories.dart
│       │   └── mock_services.dart
│       └── test_all.dart
│
└── vscode_runtime_presentation/
    └── test/
        ├── stores/
        │   └── runtime_installation_store_test.dart
        └── widgets/
            └── (widget tests)
```

---

## Running Tests

### Run All Tests

```bash
# From project root
flutter test

# Or for specific package
cd packages/vscode_runtime_core
dart test
```

### Run Specific Test File

```bash
dart test test/domain/aggregates/runtime_installation_test.dart
```

### Run Tests with Coverage

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Tests in Watch Mode

```bash
dart test --reporter=compact --watch
```

---

## Domain Layer Tests

### What We Test

Domain layer tests focus on **business logic and domain rules**:

- ✅ Value Object validation and immutability
- ✅ Entity creation and lifecycle
- ✅ Aggregate invariants and consistency
- ✅ Domain event generation
- ✅ Specification pattern
- ✅ Domain services

### Example: Testing RuntimeVersion

```dart
import 'package:test/test.dart';
import 'package:vscode_runtime_core/vscode_runtime_core.dart';

void main() {
  group('RuntimeVersion', () {
    test('should create version from valid semantic version', () {
      final version = RuntimeVersion.fromString('1.2.3');

      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
    });

    test('should throw on invalid format', () {
      expect(
        () => RuntimeVersion.fromString('invalid'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should compare versions correctly', () {
      final v1 = RuntimeVersion.fromString('1.0.0');
      final v2 = RuntimeVersion.fromString('2.0.0');

      expect(v1 < v2, isTrue);
      expect(v1.isNewerThan(v2), isFalse);
    });
  });
}
```

### Example: Testing RuntimeInstallation Aggregate

```dart
test('should complete installation when all modules installed', () {
  final module = TestFixtures.createModule();
  final installation = RuntimeInstallation.create(
    modules: [module],
    platform: TestFixtures.windowsX64,
  ).start();

  final completed = installation
      .markModuleDownloaded(module.id)
      .markModuleVerified(module.id)
      .markModuleInstalled(module.id);

  expect(completed.status, InstallationStatus.completed);
  expect(completed.progress, 1.0);
  expect(
    completed.uncommittedEvents.any((e) => e is InstallationCompleted),
    isTrue,
  );
});
```

### Test Fixtures

We provide `TestFixtures` helper class for creating test data:

```dart
// Create a simple module
final module = TestFixtures.createModule();

// Create module with dependencies
final moduleWithDeps = TestFixtures.createModuleWithDependencies(
  id: ModuleId.openVSCodeServer,
  dependencies: [ModuleId.nodejs],
);

// Create complete installation
final installation = TestFixtures.createMultiModuleInstallation();
```

---

## Application Layer Tests

### What We Test

Application layer tests focus on **use case orchestration**:

- ✅ Command handler logic
- ✅ Query handler logic
- ✅ Error handling with Either
- ✅ Service coordination
- ✅ Repository interactions
- ✅ Event publishing

### Mock Strategy

We use custom mock implementations (not mocking frameworks) for better control:

```dart
class MockRuntimeRepository implements IRuntimeRepository {
  final Map<InstallationId, RuntimeInstallation> _installations = {};

  @override
  Future<Either<DomainException, Unit>> saveInstallation(
    RuntimeInstallation installation,
  ) async {
    _installations[installation.id] = installation;
    return right(unit);
  }

  // Helper for testing
  void reset() {
    _installations.clear();
  }
}
```

### Example: Testing InstallRuntimeCommandHandler

```dart
test('should install single module successfully', () async {
  // Arrange
  manifestRepository.mockModules([nodejsModule]);

  final command = InstallRuntimeCommand(
    moduleIds: [ModuleId.nodejs],
    trigger: InstallationTrigger.manual,
  );

  // Act
  final result = await handler.handle(command);

  // Assert
  expect(result.isRight(), isTrue);

  // Verify installation was saved
  final installations = await runtimeRepository.getAllInstallations();
  final installation = installations.getOrElse(() => []).first;

  expect(installation.status, InstallationStatus.completed);
  expect(installation.progress, 1.0);

  // Verify events were published
  expect(
    eventBus.getEventsOfType<InstallationCompleted>(),
    hasLength(1),
  );
});
```

### Testing Error Scenarios

```dart
test('should fail when download fails', () async {
  // Arrange
  manifestRepository.mockModules([nodejsModule]);
  downloadService.mockFailure('Network timeout');

  final command = InstallRuntimeCommand(
    moduleIds: [ModuleId.nodejs],
  );

  // Act
  final result = await handler.handle(command);

  // Assert
  expect(result.isLeft(), isTrue);
  result.fold(
    (error) => expect(error.message, contains('Network timeout')),
    (_) => fail('Should have failed'),
  );

  // Verify failure was recorded
  final installations = await runtimeRepository.getAllInstallations();
  final installation = installations.getOrElse(() => []).first;
  expect(installation.status, InstallationStatus.failed);
});
```

---

## Presentation Layer Tests

### What We Test

Presentation layer tests focus on **state management and UI**:

- ✅ MobX store observables and computed values
- ✅ Store actions and side effects
- ✅ Reactive behavior (reactions, autorun)
- ✅ Widget rendering
- ✅ User interactions

### Example: Testing MobX Store

```dart
test('should update status during installation', () async {
  // Track status changes
  final statusChanges = <InstallationStatus>[];
  reaction(
    (_) => store.status,
    (InstallationStatus status) => statusChanges.add(status),
  );

  // Act
  await store.install(
    moduleIds: [ModuleId.nodejs],
  );

  // Assert
  expect(statusChanges, contains(InstallationStatus.inProgress));
  expect(store.status, InstallationStatus.completed);
  expect(store.isCompleted, isTrue);
});
```

### Testing Computed Values

```dart
test('progressText should format correctly', () {
  // Initial state
  expect(store.progressText, 'Preparing...');

  // Set some module counts
  store.installedModuleCount = 1;
  store.totalModuleCount = 3;

  expect(store.progressText, '1 / 3 modules');
});
```

### Testing Reactive Behavior

```dart
test('should trigger reactions on state changes', () async {
  var reactionCount = 0;

  // Setup reaction
  reaction(
    (_) => store.status,
    (_) => reactionCount++,
  );

  // Act
  await store.install(moduleIds: [ModuleId.nodejs]);

  // Assert
  expect(reactionCount, greaterThan(0));
});
```

---

## Integration Tests

### Full Installation Flow Test

```dart
test('full successful installation workflow', () async {
  // Arrange
  manifestRepository.mockModules([nodejsModule, vscodeModule]);

  // Act - Install multiple modules
  final result = await installHandler.handle(
    InstallRuntimeCommand(
      moduleIds: [ModuleId.nodejs, ModuleId.openVSCodeServer],
    ),
  );

  // Assert - Should install in dependency order
  expect(result.isRight(), isTrue);

  final installations = await runtimeRepository.getAllInstallations();
  final installation = installations.getOrElse(() => []).first;

  // Nodejs should be installed first (dependency)
  expect(installation.installedModules.first, ModuleId.nodejs);
  expect(installation.installedModules.last, ModuleId.openVSCodeServer);

  // All events should be published in order
  expect(eventBus.publishedEvents, hasLength(greaterThan(5)));
  expect(eventBus.publishedEvents.first, isA<InstallationStarted>());
  expect(eventBus.publishedEvents.last, isA<InstallationCompleted>());
});
```

---

## Test Utilities

### TestFixtures

Helper class for creating test data:

```dart
// Platform identifiers
TestFixtures.windowsX64
TestFixtures.linuxX64
TestFixtures.macOSArm64

// Module IDs
TestFixtures.nodejsId
TestFixtures.vscodeServerId
TestFixtures.baseExtensionsId

// Create artifacts
TestFixtures.createArtifact(
  url: DownloadUrl('...'),
  hash: SHA256Hash.fromString('a' * 64),
  size: ByteSize.fromMB(30),
)

// Create modules
TestFixtures.createModule(...)
TestFixtures.createModuleWithDependencies(...)
TestFixtures.createMultiPlatformModule()

// Create installations
TestFixtures.createInstallation(...)
TestFixtures.createMultiModuleInstallation()

// Create dependency scenarios
TestFixtures.createValidDependencyChain()
TestFixtures.createCircularDependency()
```

### Mock Implementations

We provide complete mock implementations for all interfaces:

```dart
// Repositories
MockRuntimeRepository
MockManifestRepository

// Services
MockDownloadService
MockVerificationService
MockExtractionService
MockPlatformService
MockFileSystemService
MockEventBus
```

Each mock has helper methods for testing:

```dart
downloadService.mockFailure('Network timeout');
verificationService.mockSuccess();
platformService.mockPlatform(PlatformIdentifier.windowsX64);
eventBus.getEventsOfType<InstallationCompleted>();
```

---

## Mocking Strategy

### When to Use Mocks

✅ **External Dependencies**: Network, file system, platform APIs
✅ **Cross-Layer Dependencies**: When testing one layer, mock the layer below
✅ **Time-Dependent Code**: Mock time to make tests deterministic
✅ **Resource-Intensive Operations**: Mock slow operations

### When NOT to Use Mocks

❌ **Domain Logic**: Never mock domain entities or value objects
❌ **Simple Data Structures**: Don't mock DTOs or simple data classes
❌ **Test Utilities**: Don't mock test fixtures or helpers

### Custom Mocks vs Mocking Framework

We use **custom mock implementations** because:

1. ✅ Better type safety
2. ✅ Easier to debug
3. ✅ More control over behavior
4. ✅ Helper methods for testing
5. ✅ No dependency on mocking frameworks

---

## Coverage

### Coverage Goals

- **Domain Layer**: 90%+ (business logic is critical)
- **Application Layer**: 85%+ (orchestration and error handling)
- **Presentation Layer**: 80%+ (UI and state management)
- **Integration Tests**: Key user flows covered

### Measuring Coverage

```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# View report
open coverage/html/index.html
```

### What to Cover

✅ **Happy Paths**: Normal execution flows
✅ **Error Paths**: All error scenarios
✅ **Edge Cases**: Boundary conditions
✅ **Business Rules**: Domain invariants
✅ **State Transitions**: Aggregate lifecycle

### What NOT to Cover

❌ **Generated Code**: .g.dart, .freezed.dart files
❌ **Third-Party Code**: Framework code, libraries
❌ **Trivial Code**: Simple getters, setters
❌ **UI Constants**: Color definitions, strings

---

## Best Practices

### 1. Test Naming

```dart
// Good ✅
test('should install module successfully when all dependencies are met')
test('should throw ValidationException when version format is invalid')
test('should publish InstallationCompleted event when all modules installed')

// Bad ❌
test('test installation')
test('version test 1')
test('events')
```

### 2. Arrange-Act-Assert

```dart
test('should complete installation when all modules installed', () {
  // Arrange - Set up test data and preconditions
  final module = TestFixtures.createModule();
  final installation = RuntimeInstallation.create(
    modules: [module],
    platform: TestFixtures.windowsX64,
  ).start();

  // Act - Execute the behavior being tested
  final completed = installation.markModuleInstalled(module.id);

  // Assert - Verify the expected outcome
  expect(completed.status, InstallationStatus.completed);
  expect(completed.progress, 1.0);
});
```

### 3. One Assertion Per Concept

```dart
// Good ✅
group('installation completion', () {
  test('should set status to completed', () {
    final completed = installation.markModuleInstalled(module.id);
    expect(completed.status, InstallationStatus.completed);
  });

  test('should set progress to 100%', () {
    final completed = installation.markModuleInstalled(module.id);
    expect(completed.progress, 1.0);
  });

  test('should publish completion event', () {
    final completed = installation.markModuleInstalled(module.id);
    expect(
      completed.uncommittedEvents.any((e) => e is InstallationCompleted),
      isTrue,
    );
  });
});
```

### 4. Test Independence

```dart
setUp(() {
  // Reset state before each test
  runtimeRepository.reset();
  downloadService.reset();
  eventBus.reset();
});

tearDown(() {
  // Clean up after each test if needed
});
```

### 5. Async Testing

```dart
test('should handle async operations correctly', () async {
  // Always await async operations
  final result = await handler.handle(command);

  // Use expectAsync for callbacks
  final completer = Completer();
  store.install(
    onProgress: expectAsync2((moduleId, progress) {
      expect(progress, inInclusiveRange(0.0, 1.0));
      if (progress >= 1.0) completer.complete();
    }, count: greaterThan(0)),
  );

  await completer.future;
});
```

---

## Troubleshooting

### Tests Failing Intermittently

**Problem**: Tests pass sometimes but fail other times

**Solution**:
- Check for timing issues with async code
- Ensure proper cleanup in tearDown
- Use `await` for all async operations
- Avoid test dependencies

### Mocks Not Working

**Problem**: Mock methods not being called

**Solution**:
- Verify mock is properly injected
- Check method signature matches interface
- Add debug logging in mock methods
- Verify test setup is correct

### Coverage Not Updating

**Problem**: Coverage report doesn't reflect recent changes

**Solution**:
```bash
# Clean coverage data
rm -rf coverage

# Re-run tests
flutter test --coverage

# Regenerate report
genhtml coverage/lcov.info -o coverage/html
```

---

## Examples

See the following files for complete examples:

- **Domain Tests**: `packages/vscode_runtime_core/test/domain/aggregates/runtime_installation_test.dart`
- **Application Tests**: `packages/vscode_runtime_application/test/handlers/install_runtime_command_handler_test.dart`
- **Presentation Tests**: `packages/vscode_runtime_presentation/test/stores/runtime_installation_store_test.dart`
- **Test Fixtures**: `packages/vscode_runtime_core/test/helpers/test_fixtures.dart`
- **Mock Implementations**: `packages/vscode_runtime_application/test/mocks/`

---

## Continuous Integration

### Running Tests in CI

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart test --coverage
      - run: dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
      - uses: codecov/codecov-action@v3
```

### Pre-commit Hooks

```bash
# .git/hooks/pre-commit
#!/bin/sh
flutter test
if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi
```

---

## Conclusion

Comprehensive testing ensures the VS Code runtime management system is:

✅ **Reliable**: Bugs are caught early
✅ **Maintainable**: Refactoring is safe
✅ **Documented**: Tests serve as living documentation
✅ **Confident**: Changes can be made with confidence

**Remember**: Good tests are an investment that pays dividends over time!

---

*For questions or improvements to this testing guide, please open an issue.*
