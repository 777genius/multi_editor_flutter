import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('MergeStrategy', () {
    group('displayName', () {
      test('should return correct name for fast-forward', () {
        // Arrange
        const strategy = MergeStrategy.fastForward();

        // Act
        final name = strategy.displayName;

        // Assert
        expect(name, equals('Fast-Forward'));
      });

      test('should return correct name for recursive', () {
        // Arrange
        const strategy = MergeStrategy.recursive();

        // Act
        final name = strategy.displayName;

        // Assert
        expect(name, equals('Recursive'));
      });

      test('should return correct name for three-way', () {
        // Arrange
        const strategy = MergeStrategy.threeWay();

        // Act
        final name = strategy.displayName;

        // Assert
        expect(name, equals('Three-Way'));
      });

      test('should return correct name for ours', () {
        // Arrange
        const strategy = MergeStrategy.ours();

        // Act
        final name = strategy.displayName;

        // Assert
        expect(name, equals('Ours'));
      });

      test('should return correct name for theirs', () {
        // Arrange
        const strategy = MergeStrategy.theirs();

        // Act
        final name = strategy.displayName;

        // Assert
        expect(name, equals('Theirs'));
      });
    });
  });

  group('MergeStrategySelector', () {
    late MergeStrategySelector selector;
    late RepositoryPath path;
    late GitBranch mainBranch;
    late GitBranch featureBranch;

    setUp(() {
      selector = const MergeStrategySelector();
      path = RepositoryPath.create('/test/repo');
      mainBranch = GitBranch(
        name: BranchName.create('main'),
        isCurrentBranch: true,
        lastCommitHash: CommitHash.create('a' * 40),
        lastCommitMessage: 'Latest commit',
        aheadCount: 0,
        behindCount: 5, // Behind remote
      );
      featureBranch = GitBranch(
        name: BranchName.create('feature'),
        isCurrentBranch: false,
        lastCommitHash: CommitHash.create('b' * 40),
        lastCommitMessage: 'Feature commit',
        aheadCount: 3,
        behindCount: 0,
      );
    });

    group('selectStrategy', () {
      test('should select fast-forward when branch is behind', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch, featureBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final strategy = selector.selectStrategy(
          repository: repo,
          sourceBranch: featureBranch.name,
          targetBranch: mainBranch.name,
        );

        // Assert
        expect(strategy, equals(const MergeStrategy.fastForward()));
      });

      test('should select three-way when branches diverged', () {
        // Arrange
        final divergedBranch = GitBranch(
          name: BranchName.create('diverged'),
          isCurrentBranch: false,
          lastCommitHash: CommitHash.create('c' * 40),
          lastCommitMessage: 'Diverged',
          aheadCount: 3,
          behindCount: 5, // Both ahead and behind = diverged
        );

        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch, divergedBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final strategy = selector.selectStrategy(
          repository: repo,
          sourceBranch: divergedBranch.name,
          targetBranch: mainBranch.name,
        );

        // Assert
        expect(strategy, equals(const MergeStrategy.threeWay()));
      });

      test('should select recursive as default', () {
        // Arrange
        final simpleBranch = GitBranch(
          name: BranchName.create('simple'),
          isCurrentBranch: false,
          lastCommitHash: CommitHash.create('d' * 40),
          lastCommitMessage: 'Simple',
          aheadCount: 0,
          behindCount: 0,
        );

        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch, simpleBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final strategy = selector.selectStrategy(
          repository: repo,
          sourceBranch: simpleBranch.name,
          targetBranch: mainBranch.name,
        );

        // Assert
        expect(strategy, equals(const MergeStrategy.recursive()));
      });
    });

    group('getRecommendation', () {
      test('should recommend fast-forward correctly', () {
        // Arrange
        const strategy = MergeStrategy.fastForward();

        // Act
        final recommendation = selector.getRecommendation(strategy);

        // Assert
        expect(recommendation, contains('fast-forward'));
        expect(recommendation, contains('No merge commit'));
      });

      test('should recommend recursive correctly', () {
        // Arrange
        const strategy = MergeStrategy.recursive();

        // Act
        final recommendation = selector.getRecommendation(strategy);

        // Assert
        expect(recommendation, contains('recursive'));
        expect(recommendation, contains('merge commit'));
      });

      test('should recommend three-way correctly', () {
        // Arrange
        const strategy = MergeStrategy.threeWay();

        // Act
        final recommendation = selector.getRecommendation(strategy);

        // Assert
        expect(recommendation, contains('Three-way'));
        expect(recommendation, contains('diverged'));
        expect(recommendation, contains('conflict'));
      });

      test('should warn about ours strategy', () {
        // Arrange
        const strategy = MergeStrategy.ours();

        // Act
        final recommendation = selector.getRecommendation(strategy);

        // Assert
        expect(recommendation, contains('our changes'));
        expect(recommendation, contains('caution'));
      });

      test('should warn about theirs strategy', () {
        // Arrange
        const strategy = MergeStrategy.theirs();

        // Act
        final recommendation = selector.getRecommendation(strategy);

        // Assert
        expect(recommendation, contains('their changes'));
        expect(recommendation, contains('caution'));
      });
    });

    group('use cases', () {
      test('should handle feature branch merge into main', () {
        // Arrange - Feature branch ahead, main not changed
        final upToDateMain = GitBranch(
          name: BranchName.create('main'),
          isCurrentBranch: true,
          lastCommitHash: CommitHash.create('a' * 40),
          lastCommitMessage: 'Base commit',
          aheadCount: 0,
          behindCount: 3, // Behind feature by 3 commits
        );

        final repo = GitRepository(
          path: path,
          currentBranch: some(upToDateMain),
          localBranches: [upToDateMain, featureBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final strategy = selector.selectStrategy(
          repository: repo,
          sourceBranch: featureBranch.name,
          targetBranch: upToDateMain.name,
        );

        // Assert
        expect(strategy, equals(const MergeStrategy.fastForward()));
      });

      test('should handle hotfix merge with diverged branches', () {
        // Arrange
        final hotfixBranch = GitBranch(
          name: BranchName.create('hotfix/critical'),
          isCurrentBranch: false,
          lastCommitHash: CommitHash.create('e' * 40),
          lastCommitMessage: 'Critical fix',
          aheadCount: 1,
          behindCount: 2, // Diverged from main
        );

        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch, hotfixBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final strategy = selector.selectStrategy(
          repository: repo,
          sourceBranch: hotfixBranch.name,
          targetBranch: mainBranch.name,
        );

        // Assert
        expect(strategy, equals(const MergeStrategy.threeWay()));
      });

      test('should handle release branch merge', () {
        // Arrange
        final releaseBranch = GitBranch(
          name: BranchName.create('release/v1.0'),
          isCurrentBranch: false,
          lastCommitHash: CommitHash.create('f' * 40),
          lastCommitMessage: 'Release prep',
          aheadCount: 5,
          behindCount: 0,
        );

        final developBranch = GitBranch(
          name: BranchName.create('develop'),
          isCurrentBranch: true,
          lastCommitHash: CommitHash.create('g' * 40),
          lastCommitMessage: 'Development',
          aheadCount: 0,
          behindCount: 5,
        );

        final repo = GitRepository(
          path: path,
          currentBranch: some(developBranch),
          localBranches: [developBranch, releaseBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final strategy = selector.selectStrategy(
          repository: repo,
          sourceBranch: releaseBranch.name,
          targetBranch: developBranch.name,
        );
        final recommendation = selector.getRecommendation(strategy);

        // Assert
        expect(strategy, equals(const MergeStrategy.fastForward()));
        expect(recommendation, isNotEmpty);
      });

      test('should provide clear recommendation for each strategy', () {
        // Arrange
        const strategies = [
          MergeStrategy.fastForward(),
          MergeStrategy.recursive(),
          MergeStrategy.threeWay(),
          MergeStrategy.ours(),
          MergeStrategy.theirs(),
        ];

        // Act & Assert
        for (final strategy in strategies) {
          final recommendation = selector.getRecommendation(strategy);
          expect(recommendation, isNotEmpty);
          expect(recommendation.length, greaterThan(10));
        }
      });
    });

    group('edge cases', () {
      test('should handle non-existent source branch', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(mainBranch),
          localBranches: [mainBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act - Branch doesn't exist, selector should handle gracefully
        final strategy = selector.selectStrategy(
          repository: repo,
          sourceBranch: BranchName.create('non-existent'),
          targetBranch: mainBranch.name,
        );

        // Assert - Should default to recursive
        expect(strategy, equals(const MergeStrategy.recursive()));
      });

      test('should handle non-existent target branch', () {
        // Arrange
        final repo = GitRepository(
          path: path,
          currentBranch: some(featureBranch),
          localBranches: [featureBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final strategy = selector.selectStrategy(
          repository: repo,
          sourceBranch: featureBranch.name,
          targetBranch: BranchName.create('non-existent'),
        );

        // Assert - Should default to recursive
        expect(strategy, equals(const MergeStrategy.recursive()));
      });

      test('should handle equal branches', () {
        // Arrange - Same branch on both sides
        final sameBranch = GitBranch(
          name: BranchName.create('same'),
          isCurrentBranch: true,
          lastCommitHash: CommitHash.create('h' * 40),
          lastCommitMessage: 'Same',
          aheadCount: 0,
          behindCount: 0,
        );

        final repo = GitRepository(
          path: path,
          currentBranch: some(sameBranch),
          localBranches: [sameBranch],
          remoteBranches: const [],
          remotes: const [],
          state: GitRepositoryState.clean,
          changes: const [],
          stagedChanges: const [],
          headCommit: none(),
          stashes: const [],
          activeConflict: none(),
        );

        // Act
        final strategy = selector.selectStrategy(
          repository: repo,
          sourceBranch: sameBranch.name,
          targetBranch: sameBranch.name,
        );

        // Assert
        expect(strategy, equals(const MergeStrategy.recursive()));
      });
    });
  });
}
