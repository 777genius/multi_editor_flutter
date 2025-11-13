import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/entities/merge_conflict.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/failures/git_failures.dart';

/// Resolution strategy for conflicts
enum ConflictResolutionStrategy {
  /// Accept incoming changes (theirs)
  acceptIncoming,

  /// Keep current changes (ours)
  keepCurrent,

  /// Accept both changes
  acceptBoth,

  /// Manual resolution (user edited)
  manual,
}

/// Use case for resolving merge conflicts
@injectable
class ResolveConflictUseCase {
  final IGitRepository _repository;

  ResolveConflictUseCase(this._repository);

  /// Get list of conflicted files
  ///
  /// Returns all files that have merge conflicts.
  Future<Either<GitFailure, List<MergeConflict>>> getConflicts({
    required RepositoryPath path,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Delegate to repository
    return _repository.getConflicts(path: path);
  }

  /// Resolve conflict with strategy
  ///
  /// This applies a resolution strategy to a conflicted file.
  ///
  /// Parameters:
  /// - path: Repository path
  /// - filePath: Conflicted file path
  /// - strategy: Resolution strategy to apply
  ///
  /// Returns: Unit on success or GitFailure
  Future<Either<GitFailure, Unit>> resolveWithStrategy({
    required RepositoryPath path,
    required String filePath,
    required ConflictResolutionStrategy strategy,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate file path
    if (filePath.isEmpty) {
      return left(
        GitFailure.unknown(
          message: 'File path cannot be empty',
        ),
      );
    }

    // Delegate to repository based on strategy
    switch (strategy) {
      case ConflictResolutionStrategy.acceptIncoming:
        return _repository.acceptIncoming(
          path: path,
          filePath: filePath,
        );

      case ConflictResolutionStrategy.keepCurrent:
        return _repository.acceptCurrent(
          path: path,
          filePath: filePath,
        );

      case ConflictResolutionStrategy.acceptBoth:
        return _repository.acceptBoth(
          path: path,
          filePath: filePath,
        );

      case ConflictResolutionStrategy.manual:
        // Manual resolution means user has already edited the file
        // Just need to mark as resolved
        return _repository.markResolved(
          path: path,
          filePath: filePath,
        );
    }
  }

  /// Resolve conflict with custom content
  ///
  /// This allows manual resolution by providing the resolved content.
  Future<Either<GitFailure, Unit>> resolveWithContent({
    required RepositoryPath path,
    required String filePath,
    required String resolvedContent,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate file path
    if (filePath.isEmpty) {
      return left(
        GitFailure.unknown(
          message: 'File path cannot be empty',
        ),
      );
    }

    // Delegate to repository
    return _repository.resolveConflictWithContent(
      path: path,
      filePath: filePath,
      content: resolvedContent,
    );
  }

  /// Mark file as resolved
  ///
  /// This tells git that conflicts in the file have been resolved.
  /// Used after manual editing of conflicted file.
  Future<Either<GitFailure, Unit>> markAsResolved({
    required RepositoryPath path,
    required String filePath,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate file path
    if (filePath.isEmpty) {
      return left(
        GitFailure.unknown(
          message: 'File path cannot be empty',
        ),
      );
    }

    // Delegate to repository
    return _repository.markResolved(
      path: path,
      filePath: filePath,
    );
  }

  /// Check if merge/rebase can be continued
  ///
  /// Returns true if all conflicts have been resolved.
  Future<Either<GitFailure, bool>> canContinue({
    required RepositoryPath path,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Get conflicts
    final conflictsResult = await getConflicts(path: path);

    return conflictsResult.map((conflicts) {
      // Can continue if no conflicts remain
      return conflicts.isEmpty;
    });
  }

  /// Abort merge/rebase
  ///
  /// This cancels the operation and returns to pre-merge/rebase state.
  Future<Either<GitFailure, Unit>> abort({
    required RepositoryPath path,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Check repository state to determine abort command
    // This will be handled by repository implementation
    return _repository.abortMergeOrRebase(path: path);
  }

  /// Get conflict content with markers
  ///
  /// Returns file content with conflict markers (<<<<<<<, =======, >>>>>>>).
  /// Useful for displaying in conflict resolution UI.
  Future<Either<GitFailure, String>> getConflictContent({
    required RepositoryPath path,
    required String filePath,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate file path
    if (filePath.isEmpty) {
      return left(
        GitFailure.unknown(
          message: 'File path cannot be empty',
        ),
      );
    }

    // Delegate to repository
    return _repository.getConflictContent(
      path: path,
      filePath: filePath,
    );
  }

  /// Parse conflict markers from content
  ///
  /// Extracts the different versions (ours, theirs) from conflict content.
  /// Returns parsed conflict sections.
  Map<String, String> parseConflictMarkers(String content) {
    final lines = content.split('\n');
    final conflicts = <String, String>{};

    String? currentSection;
    final ourLines = <String>[];
    final theirLines = <String>[];

    for (final line in lines) {
      if (line.startsWith('<<<<<<<')) {
        currentSection = 'ours';
      } else if (line.startsWith('=======')) {
        currentSection = 'theirs';
      } else if (line.startsWith('>>>>>>>')) {
        currentSection = null;
        conflicts['ours'] = ourLines.join('\n');
        conflicts['theirs'] = theirLines.join('\n');
        ourLines.clear();
        theirLines.clear();
      } else {
        if (currentSection == 'ours') {
          ourLines.add(line);
        } else if (currentSection == 'theirs') {
          theirLines.add(line);
        }
      }
    }

    return conflicts;
  }
}
