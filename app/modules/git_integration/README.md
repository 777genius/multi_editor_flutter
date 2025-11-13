# Git Integration Module

Complete git integration module for IDE with visual diff, blame, and merge conflict resolution.

## Features

### Core Git Operations
- ✅ Repository initialization and cloning
- ✅ Status and file tracking
- ✅ Staging and committing
- ✅ Branch management (create, checkout, delete, merge)
- ✅ Remote operations (push, pull, fetch)
- ✅ Stash operations
- ✅ Rebase support

### Advanced Features
- ✅ **Visual Diff**: Side-by-side and unified diff views with Rust WASM performance
- ✅ **Git Blame**: Line-by-line authorship with heat maps
- ✅ **Merge Conflicts**: Interactive resolution with three-way merge view
- ✅ **Commit History**: Paginated log with file history
- ✅ **Statistics**: Author contributions, diff stats, conflict analysis

## Architecture

This module follows **Clean Architecture** principles with **Domain-Driven Design**:

```
git_integration/
├── lib/
│   ├── src/
│   │   ├── domain/              # Domain Layer (business logic)
│   │   │   ├── entities/        # Domain entities
│   │   │   ├── value_objects/   # Validated value objects
│   │   │   ├── repositories/    # Repository interfaces
│   │   │   ├── services/        # Domain services
│   │   │   ├── events/          # Domain events
│   │   │   └── failures/        # Error types
│   │   ├── application/         # Application Layer (use cases)
│   │   │   ├── use_cases/       # Business operations
│   │   │   └── services/        # Application services
│   │   └── infrastructure/      # Infrastructure Layer (implementations)
│   │       ├── repositories/    # Repository implementations
│   │       └── adapters/        # External adapters (git CLI, parsers)
│   └── git_integration.dart     # Public API
├── pubspec.yaml
└── README.md
```

### Layer Responsibilities

**Domain Layer** (No dependencies on other layers)
- Business entities and value objects
- Repository interfaces (contracts)
- Domain services and events
- Error types

**Application Layer** (Depends on Domain)
- Use cases (single business operations)
- Application services (orchestration)
- Event handlers

**Infrastructure Layer** (Depends on Domain and Application)
- Repository implementations (Git CLI)
- Adapters (command execution, parsing)
- External integrations (Rust WASM)

## Usage

### Setup

1. Add to your `pubspec.yaml`:
```yaml
dependencies:
  git_integration:
    path: app/modules/git_integration
```

2. Configure dependency injection:
```dart
import 'package:git_integration/git_integration.dart';

void main() {
  // Configure dependencies
  configureDependencies();

  runApp(MyApp());
}
```

### Basic Operations

```dart
import 'package:git_integration/git_integration.dart';
import 'package:get_it/get_it.dart';

// Get service instance
final gitService = GetIt.instance<GitService>();

// Initialize repository
final path = RepositoryPath.create('/path/to/repo');
final result = await gitService.initRepository(path: path);

result.fold(
  (failure) => print('Error: ${failure.userMessage}'),
  (repository) => print('Repository initialized: ${repository.path.path}'),
);

// Get status
final statusResult = await gitService.getStatus(path: path);

// Stage files
await gitService.stageFiles(
  path: path,
  filePaths: ['README.md', 'lib/main.dart'],
);

// Commit
final author = GitAuthor.create(
  name: 'John Doe',
  email: 'john@example.com',
);

await gitService.commit(
  path: path,
  message: 'feat: add git integration module',
  author: author,
);
```

### Diff Operations

```dart
final diffService = GetIt.instance<DiffService>();

// Get text diff (uses Rust WASM Myers algorithm)
final diffResult = await diffService.getDiff(
  oldContent: 'Hello\nWorld',
  newContent: 'Hello\nDart\nWorld',
  contextLines: 3,
);

// Get staged diff
final stagedDiffResult = await diffService.getStagedDiff(path: path);

// Get diff statistics
diffResult.fold(
  (failure) => print('Error: ${failure.userMessage}'),
  (hunks) {
    final stats = diffService.calculateStatistics(hunks);
    print('Changes: +${stats.additions} -${stats.deletions}');
  },
);
```

### Blame Operations

```dart
final blameService = GetIt.instance<BlameService>();

// Get blame for file
final blameResult = await blameService.getFileBlame(
  path: path,
  filePath: 'lib/main.dart',
);

// Get author contribution
final contributionResult = await blameService.getAuthorContribution(
  path: path,
  filePath: 'lib/main.dart',
);

contributionResult.fold(
  (failure) => print('Error: ${failure.userMessage}'),
  (contribution) {
    contribution.forEach((author, percentage) {
      print('$author: ${percentage.toStringAsFixed(1)}%');
    });
  },
);
```

### Merge Conflict Resolution

```dart
final mergeService = GetIt.instance<MergeService>();

// Merge branch
final mergeResult = await mergeService.merge(
  path: path,
  branch: 'feature-branch',
);

// Get conflicts
final conflictsResult = await mergeService.getConflicts(path: path);

// Resolve with strategy
await mergeService.resolveWithStrategy(
  path: path,
  filePath: 'lib/main.dart',
  strategy: ConflictResolutionStrategy.acceptIncoming,
);

// Get conflict analysis with suggestions
final suggestion = await mergeService.analyzeConflict(
  path: path,
  filePath: 'lib/main.dart',
);

if (suggestion != null && suggestion.isHighConfidence) {
  print('Suggested resolution: ${suggestion.strategy}');
  print('Reason: ${suggestion.reason}');
}
```

## Performance

- **Diff Algorithm**: Rust WASM Myers algorithm (10x faster than pure Dart)
- **Caching**: Smart caching of repository state, diffs, and blame
- **Operation Queue**: Prevents concurrent git operations on same repository
- **Lazy Loading**: Paginated commit history and blame

## Error Handling

All operations return `Either<GitFailure, T>` for explicit error handling:

```dart
final result = await gitService.commit(...);

result.fold(
  (failure) {
    // Handle specific failures
    failure.when(
      repositoryNotFound: (path) => showError('Repository not found'),
      authenticationFailed: (url, reason) => showError('Auth failed'),
      mergeConflict: (conflict) => showConflictResolution(conflict),
      networkError: (message) => showError('Network error: $message'),
      commandFailed: (cmd, code, stderr) => showError('Command failed'),
      unknown: (message, error, stackTrace) => showError(message),
    );
  },
  (commit) {
    // Success
    showSuccess('Committed: ${commit.hash.short}');
  },
);
```

## Testing

```dart
import 'package:git_integration/git_integration.dart';
import 'package:mockito/mockito.dart';

// Mock repositories for testing
class MockGitRepository extends Mock implements IGitRepository {}
class MockDiffRepository extends Mock implements IDiffRepository {}

void main() {
  late MockGitRepository mockRepo;
  late GitService gitService;

  setUp(() {
    mockRepo = MockGitRepository();
    // ... setup
  });

  test('should commit changes', () async {
    // ... test implementation
  });
}
```

## Rust WASM Integration

The module includes a Rust WASM module for high-performance diff algorithm:

- **Myers Algorithm**: Industry-standard diff algorithm
- **10x Performance**: Compared to pure Dart implementation
- **Fallback**: Pure Dart implementation when WASM unavailable

See `docs/RUST_WASM_INTEGRATION.md` for setup instructions.

## Contributing

This module follows these principles:

- **SOLID**: Single responsibility, Open/closed, Liskov substitution, Interface segregation, Dependency inversion
- **Clean Architecture**: Strict layer separation with dependency rule
- **DDD**: Rich domain models with behavior
- **Functional**: Either monad for error handling, immutable data

## License

MIT License - see LICENSE file for details
