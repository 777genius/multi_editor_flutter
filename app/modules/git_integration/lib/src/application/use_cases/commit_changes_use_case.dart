import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart' as fp;
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/entities/git_commit.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/commit_message.dart';
import '../../domain/value_objects/git_author.dart';
import '../../domain/failures/git_failures.dart';

/// Use case for creating commits
@injectable
class CommitChangesUseCase {
  final IGitRepository _repository;

  CommitChangesUseCase(this._repository);

  /// Create a new commit (git commit)
  ///
  /// This will:
  /// 1. Validate there are staged changes
  /// 2. Validate commit message
  /// 3. Create commit object
  /// 4. Update HEAD
  ///
  /// Parameters:
  /// - path: Repository path
  /// - message: Commit message (will be validated)
  /// - author: Commit author (name and email)
  /// - amend: If true, amends last commit instead of creating new one
  ///
  /// Returns: Created GitCommit or GitFailure
  Future<Either<GitFailure, GitCommit>> call({
    required RepositoryPath path,
    required String message,
    required GitAuthor author,
    bool amend = false,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Validate and create commit message
    final CommitMessage commitMessage;
    try {
      commitMessage = CommitMessage.create(message);
    } catch (e) {
      return left(
        GitFailure.unknown(
          message: 'Invalid commit message: ${e.toString()}',
          error: e,
        ),
      );
    }

    // Warn if subject is too long (>72 chars)
    if (commitMessage.isSubjectTooLong) {
      // Note: In UI, should warn user but allow anyway
      // For now, just log warning
    }

    // Delegate to repository
    return _repository.commit(
      path: path,
      message: commitMessage,
      author: author,
      amend: amend,
    );
  }

  /// Amend last commit (git commit --amend)
  Future<Either<GitFailure, GitCommit>> amend({
    required RepositoryPath path,
    fp.Option<String>? newMessage,
  }) async {
    // Check if repository exists
    final exists = await path.exists();
    if (!exists) {
      return left(
        GitFailure.repositoryNotFound(path: path),
      );
    }

    // Parse new message if provided
    fp.Option<CommitMessage>? commitMessage;
    if (newMessage != null && newMessage is fp.Some<String>) {
      final msg = (newMessage as fp.Some<String>).value;
      try {
        commitMessage = fp.some(CommitMessage.create(msg));
      } catch (e) {
        return left(
          GitFailure.unknown(
            message: 'Invalid commit message: ${e.toString()}',
            error: e,
          ),
        );
      }
    }

    // Delegate to repository
    return _repository.amendCommit(
      path: path,
      newMessage: commitMessage,
    );
  }
}
