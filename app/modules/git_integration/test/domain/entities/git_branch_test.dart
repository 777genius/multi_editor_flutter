import 'package:flutter_test/flutter_test.dart';
import 'package:git_integration/git_integration.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('GitBranch', () {
    late BranchName mainBranch;
    late BranchName featureBranch;
    late CommitHash headCommit;

    setUp(() {
      mainBranch = const BranchName(value: 'main');
      featureBranch = const BranchName(value: 'feature/authentication');
      headCommit = CommitHash.create('a' * 40);
    });

    group('creation', () {
      test('should create local branch', () {
        // Act
        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        // Assert
        expect(branch.name, equals(mainBranch));
        expect(branch.headCommit, equals(headCommit));
        expect(branch.type, equals(BranchType.local));
        expect(branch.isCurrent, isTrue);
        expect(branch.aheadCount, equals(0));
        expect(branch.behindCount, equals(0));
      });

      test('should create remote branch', () {
        final remoteBranch = const BranchName(value: 'origin/main');

        final branch = GitBranch(
          name: remoteBranch,
          headCommit: headCommit,
          type: BranchType.remote,
          isCurrent: false,
        );

        expect(branch.type, equals(BranchType.remote));
        expect(branch.isRemote, isTrue);
        expect(branch.isLocal, isFalse);
      });

      test('should create branch with upstream', () {
        final upstreamBranch = const BranchName(value: 'origin/main');

        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(upstreamBranch),
          isCurrent: true,
        );

        expect(branch.hasUpstream, isTrue);
        expect(branch.isTracking, isTrue);
      });

      test('should create branch with sync information', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
          aheadCount: 3,
          behindCount: 1,
          commitCount: 25,
        );

        expect(branch.aheadCount, equals(3));
        expect(branch.behindCount, equals(1));
        expect(branch.commitCount, equals(25));
      });
    });

    group('branch type detection', () {
      test('should detect local branch', () {
        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch.isLocal, isTrue);
        expect(branch.isRemote, isFalse);
      });

      test('should detect remote branch', () {
        final remoteBranch = const BranchName(value: 'origin/develop');

        final branch = GitBranch(
          name: remoteBranch,
          headCommit: headCommit,
          type: BranchType.remote,
          isCurrent: false,
        );

        expect(branch.isRemote, isTrue);
        expect(branch.isLocal, isFalse);
      });
    });

    group('upstream tracking', () {
      test('should detect branch with upstream', () {
        final upstreamBranch = const BranchName(value: 'origin/main');

        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(upstreamBranch),
          isCurrent: true,
        );

        expect(branch.hasUpstream, isTrue);
        expect(branch.isTracking, isTrue);
      });

      test('should detect branch without upstream', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch.hasUpstream, isFalse);
        expect(branch.isTracking, isFalse);
      });

      test('should return upstream display name', () {
        final upstreamBranch = const BranchName(value: 'origin/main');

        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(upstreamBranch),
          isCurrent: true,
        );

        expect(branch.upstreamDisplay, equals('origin/main'));
      });

      test('should return "No upstream" when no tracking branch', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch.upstreamDisplay, equals('No upstream'));
      });
    });

    group('sync status', () {
      test('should detect branch needs push (ahead)', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(const BranchName(value: 'origin/feature/authentication')),
          isCurrent: true,
          aheadCount: 3,
          behindCount: 0,
        );

        expect(branch.needsPush, isTrue);
        expect(branch.needsPull, isFalse);
        expect(branch.isSynced, isFalse);
      });

      test('should detect branch needs pull (behind)', () {
        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(const BranchName(value: 'origin/main')),
          isCurrent: true,
          aheadCount: 0,
          behindCount: 5,
        );

        expect(branch.needsPull, isTrue);
        expect(branch.needsPush, isFalse);
        expect(branch.isSynced, isFalse);
      });

      test('should detect synced branch', () {
        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(const BranchName(value: 'origin/main')),
          isCurrent: true,
          aheadCount: 0,
          behindCount: 0,
        );

        expect(branch.isSynced, isTrue);
        expect(branch.needsPush, isFalse);
        expect(branch.needsPull, isFalse);
      });

      test('should detect diverged branch', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(const BranchName(value: 'origin/feature/authentication')),
          isCurrent: true,
          aheadCount: 3,
          behindCount: 2,
        );

        expect(branch.hasDiverged, isTrue);
        expect(branch.needsPush, isTrue);
        expect(branch.needsPull, isTrue);
      });
    });

    group('syncStatus display', () {
      test('should display "No upstream" for non-tracking branch', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch.syncStatus, equals('No upstream'));
      });

      test('should display "Up to date" for synced branch', () {
        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(const BranchName(value: 'origin/main')),
          isCurrent: true,
          aheadCount: 0,
          behindCount: 0,
        );

        expect(branch.syncStatus, equals('Up to date'));
      });

      test('should display ahead count', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(const BranchName(value: 'origin/feature/authentication')),
          isCurrent: true,
          aheadCount: 5,
          behindCount: 0,
        );

        expect(branch.syncStatus, equals('5 ahead'));
      });

      test('should display behind count', () {
        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(const BranchName(value: 'origin/main')),
          isCurrent: true,
          aheadCount: 0,
          behindCount: 3,
        );

        expect(branch.syncStatus, equals('3 behind'));
      });

      test('should display diverged status', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(const BranchName(value: 'origin/feature/authentication')),
          isCurrent: true,
          aheadCount: 2,
          behindCount: 3,
        );

        expect(branch.syncStatus, equals('Diverged (2 ahead, 3 behind)'));
      });
    });

    group('isMainBranch', () {
      test('should detect main branch', () {
        final branch = GitBranch(
          name: const BranchName(value: 'main'),
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch.isMainBranch, isTrue);
      });

      test('should detect master branch', () {
        final branch = GitBranch(
          name: const BranchName(value: 'master'),
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch.isMainBranch, isTrue);
      });

      test('should not detect feature branch as main', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch.isMainBranch, isFalse);
      });
    });

    group('canBeDeleted', () {
      test('should allow deletion of non-current feature branch', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: false,
        );

        expect(branch.canBeDeleted, isTrue);
      });

      test('should not allow deletion of current branch', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch.canBeDeleted, isFalse);
      });

      test('should not allow deletion of main branch', () {
        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: false,
        );

        expect(branch.canBeDeleted, isFalse);
      });

      test('should not allow deletion of current main branch', () {
        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch.canBeDeleted, isFalse);
      });
    });

    group('display names', () {
      test('should use full name for local branch', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch.displayName, equals('feature/authentication'));
        expect(branch.fullName, equals('feature/authentication'));
      });

      test('should use short name for remote branch', () {
        final remoteBranch = const BranchName(value: 'origin/feature/authentication');

        final branch = GitBranch(
          name: remoteBranch,
          headCommit: headCommit,
          type: BranchType.remote,
          isCurrent: false,
        );

        expect(branch.displayName, equals('feature/authentication'));
        expect(branch.fullName, equals('origin/feature/authentication'));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        final branch1 = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        final branch2 = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch1, equals(branch2));
      });

      test('should not be equal with different name', () {
        final branch1 = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        final branch2 = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        expect(branch1, isNot(equals(branch2)));
      });
    });

    group('copyWith', () {
      test('should copy with updated ahead/behind counts', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
          aheadCount: 0,
          behindCount: 0,
        );

        final updated = branch.copyWith(
          aheadCount: 3,
          behindCount: 1,
        );

        expect(updated.aheadCount, equals(3));
        expect(updated.behindCount, equals(1));
        expect(branch.aheadCount, equals(0));
      });

      test('should copy with new upstream', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: true,
        );

        final updated = branch.copyWith(
          upstream: some(const BranchName(value: 'origin/feature/authentication')),
        );

        expect(updated.hasUpstream, isTrue);
        expect(branch.hasUpstream, isFalse);
      });

      test('should copy with current status changed', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          isCurrent: false,
        );

        final updated = branch.copyWith(isCurrent: true);

        expect(updated.isCurrent, isTrue);
        expect(branch.isCurrent, isFalse);
      });
    });

    group('use cases', () {
      test('should represent typical local feature branch', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(const BranchName(value: 'origin/feature/authentication')),
          isCurrent: true,
          aheadCount: 5,
          behindCount: 0,
          commitCount: 10,
        );

        expect(branch.isLocal, isTrue);
        expect(branch.hasUpstream, isTrue);
        expect(branch.needsPush, isTrue);
        expect(branch.canBeDeleted, isFalse);
      });

      test('should represent main branch up to date', () {
        final branch = GitBranch(
          name: mainBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(const BranchName(value: 'origin/main')),
          isCurrent: true,
          aheadCount: 0,
          behindCount: 0,
          commitCount: 100,
        );

        expect(branch.isMainBranch, isTrue);
        expect(branch.isSynced, isTrue);
        expect(branch.canBeDeleted, isFalse);
      });

      test('should represent remote tracking branch', () {
        final remoteBranch = const BranchName(value: 'origin/develop');

        final branch = GitBranch(
          name: remoteBranch,
          headCommit: headCommit,
          type: BranchType.remote,
          isCurrent: false,
          commitCount: 250,
        );

        expect(branch.isRemote, isTrue);
        expect(branch.hasUpstream, isFalse);
      });

      test('should represent diverged branch needing rebase', () {
        final branch = GitBranch(
          name: featureBranch,
          headCommit: headCommit,
          type: BranchType.local,
          upstream: some(const BranchName(value: 'origin/feature/authentication')),
          isCurrent: false,
          aheadCount: 8,
          behindCount: 12,
        );

        expect(branch.hasDiverged, isTrue);
        expect(branch.needsPush, isTrue);
        expect(branch.needsPull, isTrue);
        expect(branch.canBeDeleted, isTrue);
      });
    });
  });
}
