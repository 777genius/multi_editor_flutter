import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/merge_conflict.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/failures/git_failures.dart';
import '../use_cases/merge_branch_use_case.dart';
import '../use_cases/rebase_branch_use_case.dart';
import '../use_cases/resolve_conflict_use_case.dart';

/// Service for merge and conflict resolution operations
///
/// This service provides high-level merge operations and coordinates
/// with merge, rebase, and conflict resolution use cases. It handles:
/// - Merge strategies and conflict detection
/// - Interactive conflict resolution UI
/// - Three-way merge visualization
/// - Automatic conflict resolution suggestions
@injectable
class MergeService {
  final MergeBranchUseCase _mergeBranchUseCase;
  final RebaseBranchUseCase _rebaseBranchUseCase;
  final ResolveConflictUseCase _resolveConflictUseCase;

  // Cache of conflict states
  final Map<String, List<MergeConflict>> _conflictCache = {};

  MergeService(
    this._mergeBranchUseCase,
    this._rebaseBranchUseCase,
    this._resolveConflictUseCase,
  );

  // ============================================================================
  // Merge Operations
  // ============================================================================

  /// Merge a branch
  Future<Either<GitFailure, Unit>> merge({
    required RepositoryPath path,
    required String branch,
    bool noFastForward = false,
  }) async {
    final result = await _mergeBranchUseCase(
      path: path,
      branch: branch,
      noFastForward: noFastForward,
    );

    // If merge conflicts occur, cache them
    result.fold(
      (failure) {
        failure.when(
          repositoryNotFound: (_) => null,
          notARepository: (_) => null,
          fileNotChanged: (_) => null,
          branchNotFound: (_) => null,
          mergeConflict: (conflict) {
            _conflictCache[path.path] = [conflict];
          },
          networkError: (_) => null,
          authenticationFailed: (_, __) => null,
          commandFailed: (_, __, ___) => null,
          unknown: (_, __, ___) => null,
        );
      },
      (_) => null,
    );

    return result;
  }

  // ============================================================================
  // Rebase Operations
  // ============================================================================

  /// Rebase current branch onto another branch
  Future<Either<GitFailure, Unit>> rebase({
    required RepositoryPath path,
    required String onto,
    bool interactive = false,
  }) async {
    return _rebaseBranchUseCase(
      path: path,
      onto: onto,
      interactive: interactive,
    );
  }

  /// Continue rebase after resolving conflicts
  Future<Either<GitFailure, Unit>> rebaseContinue({
    required RepositoryPath path,
  }) async {
    return _rebaseBranchUseCase.continue_(path: path);
  }

  /// Skip current commit during rebase
  Future<Either<GitFailure, Unit>> rebaseSkip({
    required RepositoryPath path,
  }) async {
    return _rebaseBranchUseCase.skip(path: path);
  }

  /// Abort rebase
  Future<Either<GitFailure, Unit>> rebaseAbort({
    required RepositoryPath path,
  }) async {
    return _rebaseBranchUseCase.abort(path: path);
  }

  /// Check if rebase is in progress
  Future<Either<GitFailure, bool>> isRebaseInProgress({
    required RepositoryPath path,
  }) async {
    return _rebaseBranchUseCase.isRebaseInProgress(path: path);
  }

  // ============================================================================
  // Conflict Resolution
  // ============================================================================

  /// Get list of conflicted files
  Future<Either<GitFailure, List<MergeConflict>>> getConflicts({
    required RepositoryPath path,
    bool useCache = false,
  }) async {
    // Check cache
    if (useCache && _conflictCache.containsKey(path.path)) {
      return right(_conflictCache[path.path]!);
    }

    // Get conflicts
    final result = await _resolveConflictUseCase.getConflicts(path: path);

    // Cache result
    result.fold(
      (_) => null,
      (conflicts) => _conflictCache[path.path] = conflicts,
    );

    return result;
  }

  /// Resolve conflict with strategy
  Future<Either<GitFailure, Unit>> resolveWithStrategy({
    required RepositoryPath path,
    required String filePath,
    required ConflictResolutionStrategy strategy,
  }) async {
    final result = await _resolveConflictUseCase.resolveWithStrategy(
      path: path,
      filePath: filePath,
      strategy: strategy,
    );

    // Update conflict cache
    _removeConflictFromCache(path, filePath);

    return result;
  }

  /// Resolve conflict with custom content
  Future<Either<GitFailure, Unit>> resolveWithContent({
    required RepositoryPath path,
    required String filePath,
    required String resolvedContent,
  }) async {
    final result = await _resolveConflictUseCase.resolveWithContent(
      path: path,
      filePath: filePath,
      resolvedContent: resolvedContent,
    );

    // Update conflict cache
    _removeConflictFromCache(path, filePath);

    return result;
  }

  /// Mark file as resolved
  Future<Either<GitFailure, Unit>> markAsResolved({
    required RepositoryPath path,
    required String filePath,
  }) async {
    final result = await _resolveConflictUseCase.markAsResolved(
      path: path,
      filePath: filePath,
    );

    // Update conflict cache
    _removeConflictFromCache(path, filePath);

    return result;
  }

  /// Check if merge can be continued
  Future<Either<GitFailure, bool>> canContinue({
    required RepositoryPath path,
  }) async {
    return _resolveConflictUseCase.canContinue(path: path);
  }

  /// Abort merge or rebase
  Future<Either<GitFailure, Unit>> abort({
    required RepositoryPath path,
  }) async {
    final result = await _resolveConflictUseCase.abort(path: path);

    // Clear conflict cache
    _conflictCache.remove(path.path);

    return result;
  }

  /// Get conflict content with markers
  Future<Either<GitFailure, String>> getConflictContent({
    required RepositoryPath path,
    required String filePath,
  }) async {
    return _resolveConflictUseCase.getConflictContent(
      path: path,
      filePath: filePath,
    );
  }

  // ============================================================================
  // Conflict Analysis
  // ============================================================================

  /// Analyze conflict and suggest resolution
  ///
  /// Uses heuristics to suggest automatic resolution:
  /// - If one side only adds lines, accept both
  /// - If one side is empty, accept the other
  /// - If changes are identical, accept either
  Future<ConflictResolutionSuggestion?> analyzeConflict({
    required RepositoryPath path,
    required String filePath,
  }) async {
    final contentResult = await getConflictContent(
      path: path,
      filePath: filePath,
    );

    return contentResult.fold(
      (_) => null,
      (content) {
        final parsed = _resolveConflictUseCase.parseConflictMarkers(content);
        final ours = parsed['ours'] ?? '';
        final theirs = parsed['theirs'] ?? '';

        // Heuristic 1: If one side is empty, accept the other
        if (ours.trim().isEmpty && theirs.trim().isNotEmpty) {
          return ConflictResolutionSuggestion(
            strategy: ConflictResolutionStrategy.acceptIncoming,
            confidence: 0.9,
            reason: 'Current side is empty, incoming side has content',
          );
        }

        if (theirs.trim().isEmpty && ours.trim().isNotEmpty) {
          return ConflictResolutionSuggestion(
            strategy: ConflictResolutionStrategy.keepCurrent,
            confidence: 0.9,
            reason: 'Incoming side is empty, current side has content',
          );
        }

        // Heuristic 2: If changes are identical, accept either
        if (ours.trim() == theirs.trim()) {
          return ConflictResolutionSuggestion(
            strategy: ConflictResolutionStrategy.acceptIncoming,
            confidence: 1.0,
            reason: 'Both sides have identical changes',
          );
        }

        // Heuristic 3: If one side only adds lines (no removals)
        final oursLines = ours.split('\n');
        final theirsLines = theirs.split('\n');

        if (oursLines.every((line) => theirsLines.contains(line))) {
          return ConflictResolutionSuggestion(
            strategy: ConflictResolutionStrategy.acceptIncoming,
            confidence: 0.7,
            reason: 'Incoming side includes all current changes plus additions',
          );
        }

        if (theirsLines.every((line) => oursLines.contains(line))) {
          return ConflictResolutionSuggestion(
            strategy: ConflictResolutionStrategy.keepCurrent,
            confidence: 0.7,
            reason: 'Current side includes all incoming changes plus additions',
          );
        }

        // No clear suggestion
        return null;
      },
    );
  }

  /// Get conflict statistics
  Future<Either<GitFailure, ConflictStatistics>> getConflictStatistics({
    required RepositoryPath path,
  }) async {
    final conflictsResult = await getConflicts(path: path);

    return conflictsResult.map((conflicts) {
      var totalFiles = conflicts.length;
      var totalConflicts = 0;

      for (final conflict in conflicts) {
        totalConflicts += conflict.conflictedRegions.length;
      }

      return ConflictStatistics(
        totalFiles: totalFiles,
        totalConflicts: totalConflicts,
      );
    });
  }

  // ============================================================================
  // Three-Way Merge Visualization
  // ============================================================================

  /// Get three-way merge content
  ///
  /// Returns base, ours, and theirs versions for visualization.
  Future<Either<GitFailure, ThreeWayMergeContent>> getThreeWayContent({
    required RepositoryPath path,
    required String filePath,
  }) async {
    // TODO: Implement three-way merge content retrieval
    // This requires getting base (common ancestor), ours, and theirs versions
    // Will be implemented with Infrastructure layer

    return left(
      GitFailure.unknown(
        message: 'Three-way merge visualization not yet implemented',
      ),
    );
  }

  // ============================================================================
  // Batch Conflict Resolution
  // ============================================================================

  /// Resolve all conflicts with strategy
  ///
  /// Applies the same strategy to all conflicted files.
  Future<Map<String, Either<GitFailure, Unit>>> resolveAllWithStrategy({
    required RepositoryPath path,
    required ConflictResolutionStrategy strategy,
  }) async {
    final conflictsResult = await getConflicts(path: path);

    return await conflictsResult.fold(
      (_) async => {},
      (conflicts) async {
        final results = <String, Either<GitFailure, Unit>>{};

        for (final conflict in conflicts) {
          final result = await resolveWithStrategy(
            path: path,
            filePath: conflict.filePath,
            strategy: strategy,
          );
          results[conflict.filePath] = result;
        }

        return results;
      },
    );
  }

  // ============================================================================
  // Cache Management
  // ============================================================================

  /// Remove conflict from cache
  void _removeConflictFromCache(RepositoryPath path, String filePath) {
    final conflicts = _conflictCache[path.path];
    if (conflicts != null) {
      conflicts.removeWhere((c) => c.filePath == filePath);
      if (conflicts.isEmpty) {
        _conflictCache.remove(path.path);
      }
    }
  }

  /// Clear conflict cache
  void clearCache() {
    _conflictCache.clear();
  }
}

/// Conflict resolution suggestion
class ConflictResolutionSuggestion {
  final ConflictResolutionStrategy strategy;
  final double confidence; // 0.0 to 1.0
  final String reason;

  ConflictResolutionSuggestion({
    required this.strategy,
    required this.confidence,
    required this.reason,
  });

  bool get isHighConfidence => confidence >= 0.8;
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;
  bool get isLowConfidence => confidence < 0.5;
}

/// Conflict statistics
class ConflictStatistics {
  final int totalFiles;
  final int totalConflicts;

  ConflictStatistics({
    required this.totalFiles,
    required this.totalConflicts,
  });

  double get averageConflictsPerFile {
    if (totalFiles == 0) return 0.0;
    return totalConflicts / totalFiles;
  }
}

/// Three-way merge content
class ThreeWayMergeContent {
  final String base; // Common ancestor
  final String ours; // Current branch
  final String theirs; // Branch being merged

  ThreeWayMergeContent({
    required this.base,
    required this.ours,
    required this.theirs,
  });
}
