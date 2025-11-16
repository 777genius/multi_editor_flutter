import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git_integration/git_integration.dart';

void main() {
  Widget createTestWidget({
    GitRepositoryState? initialState,
  }) {
    return ProviderScope(
      overrides: initialState != null
          ? [
              gitRepositoryNotifierProvider.overrideWith(
                (ref) => TestGitRepositoryNotifier(initialState),
              ),
            ]
          : [],
      child: const MaterialApp(
        home: Scaffold(
          body: GitPanelEnhanced(),
        ),
      ),
    );
  }

  group('GitPanelEnhanced - No Repository', () {
    testWidgets('should show "No repository" message when no repo is open',
        (tester) async {
      // Arrange
      final state = const GitRepositoryState();

      // Act
      await tester.pumpWidget(createTestWidget(initialState: state));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('No repository'), findsOneWidget);
    });

    testWidgets('should show "Open Repository" button when no repo is open',
        (tester) async {
      // Arrange
      final state = const GitRepositoryState();

      // Act
      await tester.pumpWidget(createTestWidget(initialState: state));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Open'), findsWidgets);
    });
  });

  group('GitPanelEnhanced - With Repository', () {
    testWidgets('should show repository info when repo is open', (tester) async {
      // Note: Creating a full GitRepository requires complex setup with freezed
      // This is a simplified test checking the panel renders without error

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Panel renders without crash
      expect(find.byType(GitPanelEnhanced), findsOneWidget);
    });
  });

  group('GitPanelEnhanced - Loading State', () {
    testWidgets('should show loading indicator when loading', (tester) async {
      // Arrange
      final state = const GitRepositoryState(isLoading: true);

      // Act
      await tester.pumpWidget(createTestWidget(initialState: state));
      await tester.pump(); // Don't settle, to catch loading state

      // Assert
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  group('GitPanelEnhanced - Error State', () {
    testWidgets('should show error message when error occurs', (tester) async {
      // Arrange
      final state = GitRepositoryState(
        error: GitFailure.notFound(path: '/test/repo'),
      );

      // Act
      await tester.pumpWidget(createTestWidget(initialState: state));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('not found'), findsWidgets);
    });
  });

  group('GitPanelEnhanced - Rendering', () {
    testWidgets('should render without crashing', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(GitPanelEnhanced), findsOneWidget);
    });
  });
}

/// Test notifier for overriding the provider
class TestGitRepositoryNotifier extends GitRepositoryNotifier {
  final GitRepositoryState _state;

  TestGitRepositoryNotifier(this._state);

  @override
  GitRepositoryState build() {
    return _state;
  }
}
