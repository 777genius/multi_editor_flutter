import 'package:freezed_annotation/freezed_annotation.dart';
import '../entities/git_repository.dart';
import '../value_objects/branch_name.dart';

part 'merge_strategy_selector.freezed.dart';

/// Merge strategy types
@freezed
class MergeStrategy with _$MergeStrategy {
  const factory MergeStrategy.fastForward() = _FastForward;
  const factory MergeStrategy.recursive() = _Recursive;
  const factory MergeStrategy.threeWay() = _ThreeWay;
  const factory MergeStrategy.ours() = _Ours;
  const factory MergeStrategy.theirs() = _Theirs;

  const MergeStrategy._();

  String get displayName {
    return when(
      fastForward: () => 'Fast-Forward',
      recursive: () => 'Recursive',
      threeWay: () => 'Three-Way',
      ours: () => 'Ours',
      theirs: () => 'Theirs',
    );
  }
}

/// Domain service for selecting appropriate merge strategy
class MergeStrategySelector {
  const MergeStrategySelector();

  /// Select appropriate merge strategy based on repository state
  MergeStrategy selectStrategy({
    required GitRepository repository,
    required BranchName sourceBranch,
    required BranchName targetBranch,
  }) {
    // Check if fast-forward is possible
    // Note: This is a simplified version. Real implementation would need
    // to check commit history to determine if fast-forward is possible
    if (_canFastForward(repository, sourceBranch, targetBranch)) {
      return const MergeStrategy.fastForward();
    }

    // Check if branches have diverged
    if (_haveDiverged(repository, sourceBranch, targetBranch)) {
      return const MergeStrategy.threeWay();
    }

    // Default to recursive (most common)
    return const MergeStrategy.recursive();
  }

  /// Check if fast-forward merge is possible
  /// Fast-forward: target branch is direct ancestor of source branch
  bool _canFastForward(
    GitRepository repository,
    BranchName source,
    BranchName target,
  ) {
    // Simplified: In real implementation, would check:
    // - git merge-base --is-ancestor target source
    // - If target is ancestor of source, can fast-forward

    // For now, assume fast-forward if target branch is behind
    final targetBranch = repository.getBranchByName(target.value);
    return targetBranch.fold(
      () => false,
      (branch) => branch.behindCount > 0 && branch.aheadCount == 0,
    );
  }

  /// Check if branches have diverged (both have unique commits)
  bool _haveDiverged(
    GitRepository repository,
    BranchName source,
    BranchName target,
  ) {
    // Simplified: In real implementation, would check:
    // - git rev-list --left-right --count source...target
    // - If both sides have commits, branches have diverged

    final targetBranch = repository.getBranchByName(target.value);
    return targetBranch.fold(
      () => false,
      (branch) => branch.hasDiverged,
    );
  }

  /// Get strategy recommendation for user
  String getRecommendation(MergeStrategy strategy) {
    return strategy.when(
      fastForward: () =>
          'Clean fast-forward merge. No merge commit will be created.',
      recursive: () =>
          'Standard recursive merge. A merge commit will be created.',
      threeWay: () =>
          'Three-way merge for diverged branches. May require conflict resolution.',
      ours: () =>
          'Keep our changes in case of conflicts. Use with caution.',
      theirs: () =>
          'Keep their changes in case of conflicts. Use with caution.',
    );
  }
}
