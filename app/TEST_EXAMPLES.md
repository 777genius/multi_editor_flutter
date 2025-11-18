# Примеры тестов для каждого слоя Clean Architecture

Этот документ содержит конкретные примеры тестов для каждого слоя архитектуры в IDE проекте.

---

## 📚 Содержание

1. [Domain Layer тесты](#domain-layer-тесты)
2. [Application Layer тесты](#application-layer-тесты)
3. [Infrastructure Layer тесты](#infrastructure-layer-тесты)
4. [Presentation Layer тесты](#presentation-layer-тесты)
5. [Integration тесты](#integration-тесты)
6. [Test Helpers и Utilities](#test-helpers-и-utilities)

---

## 🔷 Domain Layer тесты

### Пример 1: Entity тест (lsp_domain)

**Файл:** `app/modules/lsp_domain/test/entities/lsp_session_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('LspSession', () {
    late SessionId sessionId;
    late LanguageId languageId;
    late DocumentUri rootUri;

    setUp(() {
      sessionId = SessionId.generate();
      languageId = const LanguageId('dart');
      rootUri = DocumentUri.fromString('file:///project');
    });

    group('creation', () {
      test('should create session with valid data', () {
        // Arrange & Act
        final session = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.uninitialized,
          rootUri: rootUri,
          createdAt: DateTime.now(),
        );

        // Assert
        expect(session.id, equals(sessionId));
        expect(session.languageId, equals(languageId));
        expect(session.state, equals(SessionState.uninitialized));
        expect(session.rootUri, equals(rootUri));
        expect(session.initializedAt, isNull);
      });

      test('should be uninitialized by default', () {
        final session = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.uninitialized,
          rootUri: rootUri,
          createdAt: DateTime.now(),
        );

        expect(session.state, equals(SessionState.uninitialized));
      });
    });

    group('state transitions', () {
      test('should transition from uninitialized to initializing', () {
        // Arrange
        final session = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.uninitialized,
          rootUri: rootUri,
          createdAt: DateTime.now(),
        );

        // Act
        final updatedSession = session.copyWith(
          state: SessionState.initializing,
        );

        // Assert
        expect(updatedSession.state, equals(SessionState.initializing));
        expect(session.state, equals(SessionState.uninitialized));
      });

      test('should transition to ready with initialized timestamp', () {
        final now = DateTime.now();
        final session = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.initializing,
          rootUri: rootUri,
          createdAt: now,
        );

        final readySession = session.copyWith(
          state: SessionState.ready,
          initializedAt: now,
        );

        expect(readySession.state, equals(SessionState.ready));
        expect(readySession.initializedAt, equals(now));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        final createdAt = DateTime.now();
        final session1 = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.ready,
          rootUri: rootUri,
          createdAt: createdAt,
        );

        final session2 = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.ready,
          rootUri: rootUri,
          createdAt: createdAt,
        );

        expect(session1, equals(session2));
        expect(session1.hashCode, equals(session2.hashCode));
      });

      test('should not be equal with different session ID', () {
        final session1 = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.ready,
          rootUri: rootUri,
          createdAt: DateTime.now(),
        );

        final session2 = LspSession(
          id: SessionId.generate(),
          languageId: languageId,
          state: SessionState.ready,
          rootUri: rootUri,
          createdAt: DateTime.now(),
        );

        expect(session1, isNot(equals(session2)));
      });
    });

    group('copyWith', () {
      test('should copy with new state', () {
        final session = LspSession(
          id: sessionId,
          languageId: languageId,
          state: SessionState.uninitialized,
          rootUri: rootUri,
          createdAt: DateTime.now(),
        );

        final copied = session.copyWith(state: SessionState.ready);

        expect(copied.state, equals(SessionState.ready));
        expect(copied.id, equals(session.id));
        expect(copied.languageId, equals(session.languageId));
      });
    });
  });
}
```

---

### Пример 2: Value Object тест (editor_core)

**Файл:** `app/modules/editor_core/test/value_objects/document_uri_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:editor_core/editor_core.dart';
import 'package:dartz/dartz.dart';

void main() {
  group('DocumentUri', () {
    group('creation', () {
      test('should create valid file URI', () {
        // Act
        final result = DocumentUri.fromString('file:///path/to/file.dart');

        // Assert
        result.fold(
          (failure) => fail('Should not fail'),
          (uri) {
            expect(uri.value, equals('file:///path/to/file.dart'));
            expect(uri.isFile, isTrue);
          },
        );
      });

      test('should create valid http URI', () {
        final result = DocumentUri.fromString('https://example.com/file.dart');

        result.fold(
          (failure) => fail('Should not fail'),
          (uri) {
            expect(uri.isFile, isFalse);
            expect(uri.scheme, equals('https'));
          },
        );
      });

      test('should fail with invalid URI', () {
        final result = DocumentUri.fromString('not a valid uri');

        result.fold(
          (failure) => expect(failure, isA<EditorFailure>()),
          (_) => fail('Should fail with invalid URI'),
        );
      });

      test('should fail with empty string', () {
        final result = DocumentUri.fromString('');

        expect(result.isLeft(), isTrue);
      });
    });

    group('path extraction', () {
      test('should extract path from file URI', () {
        final uri = DocumentUri.fromString('file:///home/user/project/lib/main.dart')
            .getOrElse(() => throw Exception());

        expect(uri.path, equals('/home/user/project/lib/main.dart'));
      });

      test('should extract filename', () {
        final uri = DocumentUri.fromString('file:///path/to/file.dart')
            .getOrElse(() => throw Exception());

        expect(uri.filename, equals('file.dart'));
      });

      test('should extract extension', () {
        final uri = DocumentUri.fromString('file:///path/to/file.dart')
            .getOrElse(() => throw Exception());

        expect(uri.extension, equals('.dart'));
      });
    });

    group('comparison', () {
      test('should be equal with same URI', () {
        final uri1 = DocumentUri.fromString('file:///path/to/file.dart')
            .getOrElse(() => throw Exception());
        final uri2 = DocumentUri.fromString('file:///path/to/file.dart')
            .getOrElse(() => throw Exception());

        expect(uri1, equals(uri2));
      });

      test('should not be equal with different paths', () {
        final uri1 = DocumentUri.fromString('file:///path/to/file1.dart')
            .getOrElse(() => throw Exception());
        final uri2 = DocumentUri.fromString('file:///path/to/file2.dart')
            .getOrElse(() => throw Exception());

        expect(uri1, isNot(equals(uri2)));
      });
    });

    group('validation', () {
      test('should validate dart file extension', () {
        final uri = DocumentUri.fromString('file:///main.dart')
            .getOrElse(() => throw Exception());

        expect(uri.isDartFile, isTrue);
      });

      test('should validate non-dart file', () {
        final uri = DocumentUri.fromString('file:///README.md')
            .getOrElse(() => throw Exception());

        expect(uri.isDartFile, isFalse);
      });
    });
  });
}
```

---

### Пример 3: Entity тест (git_integration)

**Файл:** `app/modules/git_integration/test/domain/entities/git_commit_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';

void main() {
  group('GitCommit', () {
    late CommitHash hash;
    late GitAuthor author;
    late CommitMessage message;

    setUp(() {
      hash = CommitHash.fromString('a1b2c3d4e5f6')
          .getOrElse(() => throw Exception());
      author = GitAuthor(
        name: 'John Doe',
        email: 'john@example.com',
      );
      message = CommitMessage.create('Initial commit')
          .getOrElse(() => throw Exception());
    });

    test('should create commit with valid data', () {
      final commit = GitCommit(
        hash: hash,
        author: author,
        committer: author,
        message: message,
        timestamp: DateTime.now(),
        parents: [],
      );

      expect(commit.hash, equals(hash));
      expect(commit.author, equals(author));
      expect(commit.message, equals(message));
    });

    test('should identify merge commit', () {
      final mergeCommit = GitCommit(
        hash: hash,
        author: author,
        committer: author,
        message: message,
        timestamp: DateTime.now(),
        parents: [
          CommitHash.fromString('parent1').getOrElse(() => throw Exception()),
          CommitHash.fromString('parent2').getOrElse(() => throw Exception()),
        ],
      );

      expect(mergeCommit.isMergeCommit, isTrue);
    });

    test('should identify regular commit', () {
      final regularCommit = GitCommit(
        hash: hash,
        author: author,
        committer: author,
        message: message,
        timestamp: DateTime.now(),
        parents: [
          CommitHash.fromString('parent1').getOrElse(() => throw Exception()),
        ],
      );

      expect(regularCommit.isMergeCommit, isFalse);
    });

    test('should extract short hash', () {
      final commit = GitCommit(
        hash: hash,
        author: author,
        committer: author,
        message: message,
        timestamp: DateTime.now(),
        parents: [],
      );

      expect(commit.shortHash, equals('a1b2c3d'));
    });
  });
}
```

---

## 🔶 Application Layer тесты

### Пример 4: Use Case тест (lsp_application)

**Файл:** `app/modules/lsp_application/test/use_cases/get_completions_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';

@GenerateMocks([ILspClientRepository])
import 'get_completions_use_case_test.mocks.dart';

void main() {
  late GetCompletionsUseCase useCase;
  late MockILspClientRepository mockRepository;

  setUp(() {
    mockRepository = MockILspClientRepository();
    useCase = GetCompletionsUseCase(mockRepository);
  });

  group('GetCompletionsUseCase', () {
    final sessionId = SessionId.generate();
    final documentUri = DocumentUri.fromString('file:///main.dart')
        .getOrElse(() => throw Exception());
    final position = const CursorPosition(line: 10, column: 5);

    test('should return completion list on success', () async {
      // Arrange
      final expectedCompletions = CompletionList(
        isIncomplete: false,
        items: [
          CompletionItem(
            label: 'print',
            kind: CompletionItemKind.function,
            detail: 'void print(Object? object)',
          ),
          CompletionItem(
            label: 'println',
            kind: CompletionItemKind.function,
            detail: 'void println(String str)',
          ),
        ],
      );

      when(mockRepository.getCompletions(
        sessionId: sessionId,
        documentUri: documentUri,
        position: position,
      )).thenAnswer((_) async => Right(expectedCompletions));

      // Act
      final result = await useCase(
        sessionId: sessionId,
        documentUri: documentUri,
        position: position,
      );

      // Assert
      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail'),
        (completions) {
          expect(completions.items.length, equals(2));
          expect(completions.items[0].label, equals('print'));
          expect(completions.isIncomplete, isFalse);
        },
      );

      verify(mockRepository.getCompletions(
        sessionId: sessionId,
        documentUri: documentUri,
        position: position,
      )).called(1);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      final expectedFailure = LspFailure.connectionFailed(
        message: 'Connection lost',
      );

      when(mockRepository.getCompletions(
        sessionId: any(named: 'sessionId'),
        documentUri: any(named: 'documentUri'),
        position: any(named: 'position'),
      )).thenAnswer((_) async => Left(expectedFailure));

      // Act
      final result = await useCase(
        sessionId: sessionId,
        documentUri: documentUri,
        position: position,
      );

      // Assert
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, equals(expectedFailure));
          expect(failure.message, contains('Connection lost'));
        },
        (_) => fail('Should fail'),
      );
    });

    test('should filter completions by prefix', () async {
      // Arrange
      final completions = CompletionList(
        isIncomplete: false,
        items: [
          CompletionItem(label: 'print', kind: CompletionItemKind.function),
          CompletionItem(label: 'println', kind: CompletionItemKind.function),
          CompletionItem(label: 'parseInt', kind: CompletionItemKind.function),
          CompletionItem(label: 'String', kind: CompletionItemKind.class_),
        ],
      );

      when(mockRepository.getCompletions(
        sessionId: any(named: 'sessionId'),
        documentUri: any(named: 'documentUri'),
        position: any(named: 'position'),
      )).thenAnswer((_) async => Right(completions));

      // Act
      final result = await useCase(
        sessionId: sessionId,
        documentUri: documentUri,
        position: position,
        prefix: 'prin',
      );

      // Assert
      result.fold(
        (_) => fail('Should not fail'),
        (filtered) {
          expect(filtered.items.length, equals(2));
          expect(filtered.items.every((item) => item.label.startsWith('prin')), isTrue);
        },
      );
    });

    test('should sort completions by kind', () async {
      // Arrange
      final completions = CompletionList(
        isIncomplete: false,
        items: [
          CompletionItem(label: 'variable', kind: CompletionItemKind.variable),
          CompletionItem(label: 'function', kind: CompletionItemKind.function),
          CompletionItem(label: 'class', kind: CompletionItemKind.class_),
        ],
      );

      when(mockRepository.getCompletions(
        sessionId: any(named: 'sessionId'),
        documentUri: any(named: 'documentUri'),
        position: any(named: 'position'),
      )).thenAnswer((_) async => Right(completions));

      // Act
      final result = await useCase(
        sessionId: sessionId,
        documentUri: documentUri,
        position: position,
        sortByKind: true,
      );

      // Assert
      result.fold(
        (_) => fail('Should not fail'),
        (sorted) {
          expect(sorted.items[0].kind, equals(CompletionItemKind.class_));
          expect(sorted.items[1].kind, equals(CompletionItemKind.function));
          expect(sorted.items[2].kind, equals(CompletionItemKind.variable));
        },
      );
    });
  });
}
```

---

### Пример 5: Service тест (git_integration)

**Файл:** `app/modules/git_integration/test/application/services/git_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:git_integration/git_integration.dart';

@GenerateMocks([IGitRepository, ICredentialRepository])
import 'git_service_test.mocks.dart';

void main() {
  late GitService gitService;
  late MockIGitRepository mockGitRepository;
  late MockICredentialRepository mockCredentialRepository;

  setUp(() {
    mockGitRepository = MockIGitRepository();
    mockCredentialRepository = MockICredentialRepository();
    gitService = GitService(
      gitRepository: mockGitRepository,
      credentialRepository: mockCredentialRepository,
    );
  });

  group('GitService', () {
    final repositoryPath = RepositoryPath.fromString('/project')
        .getOrElse(() => throw Exception());

    group('commitWithValidation', () {
      test('should commit successfully with valid message', () async {
        // Arrange
        final message = CommitMessage.create('feat: add new feature')
            .getOrElse(() => throw Exception());
        final author = GitAuthor(name: 'John', email: 'john@example.com');

        when(mockGitRepository.hasChanges(repositoryPath))
            .thenAnswer((_) async => const Right(true));

        when(mockGitRepository.commit(
          path: repositoryPath,
          message: message,
          author: author,
        )).thenAnswer((_) async => Right(
          CommitHash.fromString('abc123').getOrElse(() => throw Exception()),
        ));

        // Act
        final result = await gitService.commitWithValidation(
          path: repositoryPath,
          message: message,
          author: author,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(mockGitRepository.hasChanges(repositoryPath)).called(1);
        verify(mockGitRepository.commit(
          path: repositoryPath,
          message: message,
          author: author,
        )).called(1);
      });

      test('should fail when no changes to commit', () async {
        // Arrange
        final message = CommitMessage.create('test commit')
            .getOrElse(() => throw Exception());
        final author = GitAuthor(name: 'John', email: 'john@example.com');

        when(mockGitRepository.hasChanges(repositoryPath))
            .thenAnswer((_) async => const Right(false));

        // Act
        final result = await gitService.commitWithValidation(
          path: repositoryPath,
          message: message,
          author: author,
        );

        // Assert
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure.message, contains('no changes')),
          (_) => fail('Should fail'),
        );

        verify(mockGitRepository.hasChanges(repositoryPath)).called(1);
        verifyNever(mockGitRepository.commit(
          path: any(named: 'path'),
          message: any(named: 'message'),
          author: any(named: 'author'),
        ));
      });
    });

    group('pushWithCredentials', () {
      test('should push with stored credentials', () async {
        // Arrange
        final remoteName = RemoteName.fromString('origin')
            .getOrElse(() => throw Exception());
        final branchName = BranchName.fromString('main')
            .getOrElse(() => throw Exception());
        final credentials = GitCredential(
          username: 'user',
          password: 'pass',
        );

        when(mockCredentialRepository.getCredentials(remoteName))
            .thenAnswer((_) async => Right(credentials));

        when(mockGitRepository.push(
          path: repositoryPath,
          remote: remoteName,
          branch: branchName,
          credentials: credentials,
        )).thenAnswer((_) async => const Right(unit));

        // Act
        final result = await gitService.pushWithCredentials(
          path: repositoryPath,
          remote: remoteName,
          branch: branchName,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(mockCredentialRepository.getCredentials(remoteName)).called(1);
        verify(mockGitRepository.push(
          path: repositoryPath,
          remote: remoteName,
          branch: branchName,
          credentials: credentials,
        )).called(1);
      });
    });
  });
}
```

---

## 🔸 Infrastructure Layer тесты

### Пример 6: Repository тест (lsp_infrastructure)

**Файл:** `app/modules/lsp_infrastructure/test/client/websocket_lsp_client_repository_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:lsp_infrastructure/lsp_infrastructure.dart';
import 'package:lsp_domain/lsp_domain.dart';

@GenerateMocks([WebSocketChannel])
import 'websocket_lsp_client_repository_test.mocks.dart';

void main() {
  late WebsocketLspClientRepository repository;
  late MockWebSocketChannel mockChannel;

  setUp(() {
    mockChannel = MockWebSocketChannel();
    // Inject mock через constructor или factory
  });

  group('WebsocketLspClientRepository', () {
    group('initialize', () {
      test('should send initialize request', () async {
        // Arrange
        final sessionId = SessionId.generate();
        final rootUri = DocumentUri.fromString('file:///project')
            .getOrElse(() => throw Exception());

        when(mockChannel.stream).thenAnswer((_) => Stream.value('''
          {
            "jsonrpc": "2.0",
            "id": 1,
            "result": {
              "capabilities": {
                "textDocumentSync": 1,
                "completionProvider": {}
              }
            }
          }
        '''));

        // Act
        final result = await repository.initialize(
          sessionId: sessionId,
          rootUri: rootUri,
        );

        // Assert
        expect(result.isRight(), isTrue);
        verify(mockChannel.sink.add(any)).called(1);
      });

      test('should handle initialization error', () async {
        // Arrange
        final sessionId = SessionId.generate();
        final rootUri = DocumentUri.fromString('file:///project')
            .getOrElse(() => throw Exception());

        when(mockChannel.stream).thenAnswer((_) => Stream.value('''
          {
            "jsonrpc": "2.0",
            "id": 1,
            "error": {
              "code": -32600,
              "message": "Invalid request"
            }
          }
        '''));

        // Act
        final result = await repository.initialize(
          sessionId: sessionId,
          rootUri: rootUri,
        );

        // Assert
        expect(result.isLeft(), isTrue);
      });
    });

    group('getCompletions', () {
      test('should parse completion response', () async {
        // Arrange
        final sessionId = SessionId.generate();
        final documentUri = DocumentUri.fromString('file:///main.dart')
            .getOrElse(() => throw Exception());
        final position = const CursorPosition(line: 10, column: 5);

        when(mockChannel.stream).thenAnswer((_) => Stream.value('''
          {
            "jsonrpc": "2.0",
            "id": 2,
            "result": {
              "isIncomplete": false,
              "items": [
                {
                  "label": "print",
                  "kind": 3,
                  "detail": "void print(Object? object)"
                }
              ]
            }
          }
        '''));

        // Act
        final result = await repository.getCompletions(
          sessionId: sessionId,
          documentUri: documentUri,
          position: position,
        );

        // Assert
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Should not fail'),
          (completions) {
            expect(completions.items.length, equals(1));
            expect(completions.items[0].label, equals('print'));
          },
        );
      });
    });

    group('connection management', () {
      test('should reconnect on connection loss', () async {
        // Test reconnection logic
      });

      test('should queue requests when disconnected', () async {
        // Test request queuing
      });
    });
  });
}
```

---

## 🔹 Presentation Layer тесты

### Пример 7: Widget тест (ide_presentation)

**Файл:** `app/modules/ide_presentation/test/widgets/completion_popup_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ide_presentation/ide_presentation.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('CompletionPopup', () {
    late CompletionList completionList;

    setUp(() {
      completionList = CompletionList(
        isIncomplete: false,
        items: [
          CompletionItem(
            label: 'print',
            kind: CompletionItemKind.function,
            detail: 'void print(Object? object)',
            documentation: 'Prints an object to the console',
          ),
          CompletionItem(
            label: 'println',
            kind: CompletionItemKind.function,
            detail: 'void println(String str)',
          ),
          CompletionItem(
            label: 'String',
            kind: CompletionItemKind.class_,
            detail: 'class String',
          ),
        ],
      );
    });

    testWidgets('should display completion items', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionPopup(
              completions: completionList,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('print'), findsOneWidget);
      expect(find.text('println'), findsOneWidget);
      expect(find.text('String'), findsOneWidget);
    });

    testWidgets('should show detail information', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionPopup(
              completions: completionList,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('void print(Object? object)'), findsOneWidget);
    });

    testWidgets('should call onSelected when item is tapped', (tester) async {
      // Arrange
      CompletionItem? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionPopup(
              completions: completionList,
              onSelected: (item) => selectedItem = item,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('print'));
      await tester.pump();

      // Assert
      expect(selectedItem, isNotNull);
      expect(selectedItem!.label, equals('print'));
    });

    testWidgets('should filter items by search query', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionPopup(
              completions: completionList,
              onSelected: (_) {},
              searchQuery: 'prin',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('print'), findsOneWidget);
      expect(find.text('println'), findsOneWidget);
      expect(find.text('String'), findsNothing);
    });

    testWidgets('should show different icons for different kinds', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionPopup(
              completions: completionList,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // Assert - проверить что иконки различаются
      expect(find.byIcon(Icons.functions), findsNWidgets(2)); // functions
      expect(find.byIcon(Icons.class_), findsOneWidget); // class
    });

    testWidgets('should navigate with arrow keys', (tester) async {
      // Arrange
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionPopup(
              completions: completionList,
              onSelected: (_) {},
              onIndexChanged: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      // Act - simulate arrow down key
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      // Assert
      expect(selectedIndex, equals(1));

      // Act - simulate arrow up key
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      // Assert
      expect(selectedIndex, equals(0));
    });

    testWidgets('should confirm selection with Enter key', (tester) async {
      // Arrange
      CompletionItem? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletionPopup(
              completions: completionList,
              onSelected: (item) => selectedItem = item,
              selectedIndex: 0,
            ),
          ),
        ),
      );

      // Act - simulate Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // Assert
      expect(selectedItem, isNotNull);
      expect(selectedItem!.label, equals('print'));
    });
  });
}
```

---

### Пример 8: Store тест (ide_presentation с MobX)

**Файл:** `app/modules/ide_presentation/test/stores/lsp_store_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ide_presentation/ide_presentation.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_domain/lsp_domain.dart';
import 'package:dartz/dartz.dart';

@GenerateMocks([
  InitializeLspSessionUseCase,
  GetCompletionsUseCase,
  GetDiagnosticsUseCase,
])
import 'lsp_store_test.mocks.dart';

void main() {
  late LspStore store;
  late MockInitializeLspSessionUseCase mockInitializeUseCase;
  late MockGetCompletionsUseCase mockGetCompletionsUseCase;
  late MockGetDiagnosticsUseCase mockGetDiagnosticsUseCase;

  setUp(() {
    mockInitializeUseCase = MockInitializeLspSessionUseCase();
    mockGetCompletionsUseCase = MockGetCompletionsUseCase();
    mockGetDiagnosticsUseCase = MockGetDiagnosticsUseCase();

    store = LspStore(
      initializeUseCase: mockInitializeUseCase,
      getCompletionsUseCase: mockGetCompletionsUseCase,
      getDiagnosticsUseCase: mockGetDiagnosticsUseCase,
    );
  });

  group('LspStore', () {
    group('initialization', () {
      test('should initialize successfully', () async {
        // Arrange
        final session = LspSession(
          id: SessionId.generate(),
          languageId: const LanguageId('dart'),
          state: SessionState.ready,
          rootUri: DocumentUri.fromString('file:///project')
              .getOrElse(() => throw Exception()),
          createdAt: DateTime.now(),
        );

        when(mockInitializeUseCase(
          languageId: anyNamed('languageId'),
          rootUri: anyNamed('rootUri'),
        )).thenAnswer((_) async => Right(session));

        // Act
        await store.initialize(
          languageId: const LanguageId('dart'),
          rootUri: DocumentUri.fromString('file:///project')
              .getOrElse(() => throw Exception()),
        );

        // Assert
        expect(store.isInitialized, isTrue);
        expect(store.session, equals(session));
        expect(store.error, isNull);
      });

      test('should handle initialization failure', () async {
        // Arrange
        final failure = LspFailure.serverNotFound(
          message: 'Dart analyzer not found',
        );

        when(mockInitializeUseCase(
          languageId: anyNamed('languageId'),
          rootUri: anyNamed('rootUri'),
        )).thenAnswer((_) async => Left(failure));

        // Act
        await store.initialize(
          languageId: const LanguageId('dart'),
          rootUri: DocumentUri.fromString('file:///project')
              .getOrElse(() => throw Exception()),
        );

        // Assert
        expect(store.isInitialized, isFalse);
        expect(store.session, isNull);
        expect(store.error, isNotNull);
        expect(store.error, contains('not found'));
      });
    });

    group('completions', () {
      test('should fetch completions', () async {
        // Arrange
        final completions = CompletionList(
          isIncomplete: false,
          items: [
            CompletionItem(label: 'print', kind: CompletionItemKind.function),
          ],
        );

        when(mockGetCompletionsUseCase(
          sessionId: any(named: 'sessionId'),
          documentUri: any(named: 'documentUri'),
          position: any(named: 'position'),
        )).thenAnswer((_) async => Right(completions));

        // Setup initialized session first
        store.session = LspSession(
          id: SessionId.generate(),
          languageId: const LanguageId('dart'),
          state: SessionState.ready,
          rootUri: DocumentUri.fromString('file:///project')
              .getOrElse(() => throw Exception()),
          createdAt: DateTime.now(),
        );

        // Act
        await store.getCompletions(
          documentUri: DocumentUri.fromString('file:///main.dart')
              .getOrElse(() => throw Exception()),
          position: const CursorPosition(line: 10, column: 5),
        );

        // Assert
        expect(store.completions, equals(completions));
        expect(store.isLoadingCompletions, isFalse);
      });
    });

    group('diagnostics', () {
      test('should update diagnostics', () async {
        // Arrange
        final diagnostics = [
          Diagnostic(
            range: const Range(
              start: Position(line: 5, character: 10),
              end: Position(line: 5, character: 20),
            ),
            severity: DiagnosticSeverity.error,
            message: 'Undefined name',
          ),
        ];

        when(mockGetDiagnosticsUseCase(
          sessionId: any(named: 'sessionId'),
          documentUri: any(named: 'documentUri'),
        )).thenAnswer((_) async => Right(diagnostics));

        store.session = LspSession(
          id: SessionId.generate(),
          languageId: const LanguageId('dart'),
          state: SessionState.ready,
          rootUri: DocumentUri.fromString('file:///project')
              .getOrElse(() => throw Exception()),
          createdAt: DateTime.now(),
        );

        // Act
        await store.getDiagnostics(
          documentUri: DocumentUri.fromString('file:///main.dart')
              .getOrElse(() => throw Exception()),
        );

        // Assert
        expect(store.diagnostics.length, equals(1));
        expect(store.errorCount, equals(1));
        expect(store.warningCount, equals(0));
      });

      test('should count errors and warnings separately', () {
        // Arrange
        store.diagnostics = [
          Diagnostic(
            range: const Range(
              start: Position(line: 1, character: 0),
              end: Position(line: 1, character: 10),
            ),
            severity: DiagnosticSeverity.error,
            message: 'Error 1',
          ),
          Diagnostic(
            range: const Range(
              start: Position(line: 2, character: 0),
              end: Position(line: 2, character: 10),
            ),
            severity: DiagnosticSeverity.error,
            message: 'Error 2',
          ),
          Diagnostic(
            range: const Range(
              start: Position(line: 3, character: 0),
              end: Position(line: 3, character: 10),
            ),
            severity: DiagnosticSeverity.warning,
            message: 'Warning 1',
          ),
        ];

        // Assert
        expect(store.errorCount, equals(2));
        expect(store.warningCount, equals(1));
      });
    });
  });
}
```

---

## 🔗 Integration тесты

### Пример 9: LSP Workflow Integration тест

**Файл:** `app/modules/lsp_application/test/integration/lsp_workflow_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_application/lsp_application.dart';
import 'package:lsp_infrastructure/lsp_infrastructure.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('LSP Workflow Integration', () {
    late ILspClientRepository repository;
    late InitializeLspSessionUseCase initializeUseCase;
    late GetCompletionsUseCase getCompletionsUseCase;
    late GetDiagnosticsUseCase getDiagnosticsUseCase;

    setUpAll(() {
      // Setup real repository with test LSP server
      repository = WebsocketLspClientRepository(
        serverUrl: 'ws://localhost:9999',
      );

      initializeUseCase = InitializeLspSessionUseCase(repository);
      getCompletionsUseCase = GetCompletionsUseCase(repository);
      getDiagnosticsUseCase = GetDiagnosticsUseCase(repository);
    });

    test('full LSP workflow: initialize → open document → get completions → diagnostics', () async {
      // Step 1: Initialize session
      final initResult = await initializeUseCase(
        languageId: const LanguageId('dart'),
        rootUri: DocumentUri.fromString('file:///test_project')
            .getOrElse(() => throw Exception()),
      );

      expect(initResult.isRight(), isTrue);
      final session = initResult.getOrElse(() => throw Exception());
      expect(session.state, equals(SessionState.ready));

      // Step 2: Open document
      final documentUri = DocumentUri.fromString('file:///test_project/lib/main.dart')
          .getOrElse(() => throw Exception());
      final content = '''
void main() {
  prin
}
      ''';

      final openResult = await repository.didOpenDocument(
        sessionId: session.id,
        documentUri: documentUri,
        content: content,
      );
      expect(openResult.isRight(), isTrue);

      // Step 3: Get completions at cursor
      final completionsResult = await getCompletionsUseCase(
        sessionId: session.id,
        documentUri: documentUri,
        position: const CursorPosition(line: 1, column: 6), // after "prin"
      );

      expect(completionsResult.isRight(), isTrue);
      final completions = completionsResult.getOrElse(() => throw Exception());
      expect(completions.items.any((item) => item.label == 'print'), isTrue);

      // Step 4: Complete the code and get diagnostics
      final updatedContent = '''
void main() {
  print('Hello');
}
      ''';

      await repository.didChangeDocument(
        sessionId: session.id,
        documentUri: documentUri,
        content: updatedContent,
      );

      final diagnosticsResult = await getDiagnosticsUseCase(
        sessionId: session.id,
        documentUri: documentUri,
      );

      expect(diagnosticsResult.isRight(), isTrue);
      final diagnostics = diagnosticsResult.getOrElse(() => throw Exception());
      expect(diagnostics.where((d) => d.severity == DiagnosticSeverity.error), isEmpty);
    });
  });
}
```

---

## 🛠️ Test Helpers и Utilities

### Пример 10: Mock Factories

**Файл:** `app/test/helpers/mock_factories.dart`

```dart
import 'package:lsp_domain/lsp_domain.dart';
import 'package:editor_core/editor_core.dart';
import 'package:git_integration/git_integration.dart';

class MockFactories {
  // LSP Mocks
  static LspSession createMockLspSession({
    SessionId? id,
    LanguageId? languageId,
    SessionState? state,
  }) {
    return LspSession(
      id: id ?? SessionId.generate(),
      languageId: languageId ?? const LanguageId('dart'),
      state: state ?? SessionState.ready,
      rootUri: DocumentUri.fromString('file:///project')
          .getOrElse(() => throw Exception()),
      createdAt: DateTime.now(),
    );
  }

  static CompletionList createMockCompletionList({
    int itemCount = 5,
    bool isIncomplete = false,
  }) {
    return CompletionList(
      isIncomplete: isIncomplete,
      items: List.generate(
        itemCount,
        (i) => CompletionItem(
          label: 'item$i',
          kind: CompletionItemKind.function,
          detail: 'Detail for item$i',
        ),
      ),
    );
  }

  static List<Diagnostic> createMockDiagnostics({
    int errorCount = 1,
    int warningCount = 1,
  }) {
    final diagnostics = <Diagnostic>[];

    for (int i = 0; i < errorCount; i++) {
      diagnostics.add(Diagnostic(
        range: Range(
          start: Position(line: i, character: 0),
          end: Position(line: i, character: 10),
        ),
        severity: DiagnosticSeverity.error,
        message: 'Error $i',
      ));
    }

    for (int i = 0; i < warningCount; i++) {
      diagnostics.add(Diagnostic(
        range: Range(
          start: Position(line: errorCount + i, character: 0),
          end: Position(line: errorCount + i, character: 10),
        ),
        severity: DiagnosticSeverity.warning,
        message: 'Warning $i',
      ));
    }

    return diagnostics;
  }

  // Editor Mocks
  static EditorDocument createMockDocument({
    String? content,
    String? uri,
  }) {
    return EditorDocument(
      uri: DocumentUri.fromString(uri ?? 'file:///main.dart')
          .getOrElse(() => throw Exception()),
      content: content ?? 'void main() {}',
      languageId: const LanguageId('dart'),
      version: 1,
    );
  }

  // Git Mocks
  static GitCommit createMockCommit({
    String? hash,
    String? message,
    String? authorName,
  }) {
    return GitCommit(
      hash: CommitHash.fromString(hash ?? 'abc123')
          .getOrElse(() => throw Exception()),
      author: GitAuthor(
        name: authorName ?? 'John Doe',
        email: 'john@example.com',
      ),
      committer: GitAuthor(
        name: authorName ?? 'John Doe',
        email: 'john@example.com',
      ),
      message: CommitMessage.create(message ?? 'Initial commit')
          .getOrElse(() => throw Exception()),
      timestamp: DateTime.now(),
      parents: [],
    );
  }

  static GitBranch createMockBranch({
    String? name,
    bool isActive = false,
  }) {
    return GitBranch(
      name: BranchName.fromString(name ?? 'main')
          .getOrElse(() => throw Exception()),
      isActive: isActive,
      isRemote: false,
      upstream: null,
    );
  }
}
```

---

### Пример 11: Test Data Builders

**Файл:** `app/test/helpers/test_data_builders.dart`

```dart
import 'package:lsp_domain/lsp_domain.dart';

class LspSessionBuilder {
  SessionId _id = SessionId.generate();
  LanguageId _languageId = const LanguageId('dart');
  SessionState _state = SessionState.ready;
  late DocumentUri _rootUri;
  DateTime _createdAt = DateTime.now();
  DateTime? _initializedAt;

  LspSessionBuilder() {
    _rootUri = DocumentUri.fromString('file:///project')
        .getOrElse(() => throw Exception());
  }

  LspSessionBuilder withId(SessionId id) {
    _id = id;
    return this;
  }

  LspSessionBuilder withLanguage(String language) {
    _languageId = LanguageId(language);
    return this;
  }

  LspSessionBuilder withState(SessionState state) {
    _state = state;
    return this;
  }

  LspSessionBuilder asUninitialized() {
    _state = SessionState.uninitialized;
    _initializedAt = null;
    return this;
  }

  LspSessionBuilder asReady() {
    _state = SessionState.ready;
    _initializedAt = DateTime.now();
    return this;
  }

  LspSessionBuilder withRootUri(String uri) {
    _rootUri = DocumentUri.fromString(uri)
        .getOrElse(() => throw Exception());
    return this;
  }

  LspSession build() {
    return LspSession(
      id: _id,
      languageId: _languageId,
      state: _state,
      rootUri: _rootUri,
      createdAt: _createdAt,
      initializedAt: _initializedAt,
    );
  }
}

// Usage:
// final session = LspSessionBuilder()
//     .withLanguage('typescript')
//     .asReady()
//     .build();
```

---

### Пример 12: Custom Matchers

**Файл:** `app/test/helpers/custom_matchers.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';

// Either matchers
Matcher isRight() => _IsRight();
Matcher isLeft() => _IsLeft();

class _IsRight extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    return item is Either && item.isRight();
  }

  @override
  Description describe(Description description) {
    return description.add('is Right');
  }
}

class _IsLeft extends Matcher {
  @override
  bool matches(dynamic item, Map matchState) {
    return item is Either && item.isLeft();
  }

  @override
  Description describe(Description description) {
    return description.add('is Left');
  }
}

// LSP specific matchers
Matcher hasCompletionWithLabel(String label) => _HasCompletionWithLabel(label);

class _HasCompletionWithLabel extends Matcher {
  final String label;

  _HasCompletionWithLabel(this.label);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! CompletionList) return false;
    return item.items.any((completion) => completion.label == label);
  }

  @override
  Description describe(Description description) {
    return description.add('has completion with label "$label"');
  }
}

// Usage:
// expect(result, isRight());
// expect(completions, hasCompletionWithLabel('print'));
```

---

## 📝 Заключение

Эти примеры показывают:

1. **Domain Layer** - Unit тесты для entities, value objects, failures
2. **Application Layer** - Unit тесты для use cases и services с моками
3. **Infrastructure Layer** - Integration тесты для repositories и adapters
4. **Presentation Layer** - Widget тесты и Store тесты
5. **Integration тесты** - End-to-end workflows
6. **Helpers** - Переиспользуемые mock factories и builders

### Best Practices из примеров:

- ✅ AAA pattern (Arrange-Act-Assert)
- ✅ Descriptive test names
- ✅ One concept per test
- ✅ Use builders для сложных объектов
- ✅ Mock внешние зависимости
- ✅ Test both success and failure paths
- ✅ Verify interactions с моками
- ✅ Use custom matchers для читаемости

---

**Следующие шаги:**
1. Скопировать эти примеры в соответствующие модули
2. Адаптировать под конкретные use cases
3. Запустить тесты: `flutter test`
4. Проверить coverage: `flutter test --coverage`
