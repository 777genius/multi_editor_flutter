import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/git_repository.dart';
import '../../domain/entities/git_commit.dart';
import '../../domain/entities/file_change.dart';
import '../../domain/value_objects/repository_path.dart';
import '../../domain/value_objects/git_author.dart';
import '../../domain/failures/git_failures.dart';
import '../../application/services/git_service.dart';

part 'git_state_provider.g.dart';

/// Git repository state
class GitRepositoryState {
  final GitRepository? repository;
  final bool isLoading;
  final GitFailure? error;
  final List<FileChange> selectedFiles;

  const GitRepositoryState({
    this.repository,
    this.isLoading = false,
    this.error,
    this.selectedFiles = const [],
  });

  GitRepositoryState copyWith({
    GitRepository? repository,
    bool? isLoading,
    GitFailure? error,
    List<FileChange>? selectedFiles,
    bool clearError = false,
  }) {
    return GitRepositoryState(
      repository: repository ?? this.repository,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedFiles: selectedFiles ?? this.selectedFiles,
    );
  }

  bool get hasRepository => repository != null;
  bool get hasError => error != null;
  bool get hasChanges =>
      repository?.changes.isNotEmpty ?? false ||
      repository?.stagedChanges.isNotEmpty ?? false;
  bool get hasStagedChanges => repository?.stagedChanges.isNotEmpty ?? false;
  bool get hasUnstagedChanges => repository?.changes.isNotEmpty ?? false;
}

/// Git service provider
@riverpod
GitService gitService(GitServiceRef ref) {
  return GetIt.instance<GitService>();
}

/// Current repository path provider
final currentRepositoryPathProvider =
    StateProvider<RepositoryPath?>((ref) => null);

/// Git repository state provider
@riverpod
class GitRepositoryNotifier extends _$GitRepositoryNotifier {
  @override
  GitRepositoryState build() {
    return const GitRepositoryState();
  }

  GitService get _gitService => ref.read(gitServiceProvider);

  /// Open repository
  Future<void> openRepository(RepositoryPath path) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _gitService.getStatus(path: path);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (repository) {
        state = state.copyWith(
          repository: repository,
          isLoading: false,
          clearError: true,
        );
        ref.read(currentRepositoryPathProvider.notifier).state = path;
      },
    );
  }

  /// Refresh repository status
  Future<void> refresh() async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.getStatus(
      path: path,
      forceRefresh: true,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (repository) {
        state = state.copyWith(
          repository: repository,
          isLoading: false,
          clearError: true,
        );
      },
    );
  }

  /// Stage files
  Future<void> stageFiles(List<String> filePaths) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.stageFiles(
      path: path,
      filePaths: filePaths,
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (_) async {
        await refresh();
      },
    );
  }

  /// Stage all files
  Future<void> stageAll() async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.stageAll(path: path);

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (_) async {
        await refresh();
      },
    );
  }

  /// Unstage files
  Future<void> unstageFiles(List<String> filePaths) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.unstageFiles(
      path: path,
      filePaths: filePaths,
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (_) async {
        await refresh();
      },
    );
  }

  /// Unstage all files
  Future<void> unstageAll() async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.unstageAll(path: path);

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (_) async {
        await refresh();
      },
    );
  }

  /// Commit changes
  Future<GitCommit?> commit({
    required String message,
    required GitAuthor author,
    bool amend = false,
  }) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return null;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.commit(
      path: path,
      message: message,
      author: author,
      amend: amend,
    );

    return await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
        return null;
      },
      (commit) async {
        await refresh();
        return commit;
      },
    );
  }

  /// Checkout branch
  Future<void> checkoutBranch(String branchName, {bool force = false}) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.checkoutBranch(
      path: path,
      branchName: branchName,
      force: force,
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (_) async {
        await refresh();
      },
    );
  }

  /// Create branch
  Future<void> createBranch({
    required String branchName,
    String? startPoint,
    bool checkout = false,
  }) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.createBranch(
      path: path,
      branchName: branchName,
      startPoint: startPoint,
      checkout: checkout,
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (_) async {
        await refresh();
      },
    );
  }

  /// Delete branch
  Future<void> deleteBranch({
    required String branchName,
    bool force = false,
  }) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.deleteBranch(
      path: path,
      branchName: branchName,
      force: force,
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (_) async {
        await refresh();
      },
    );
  }

  /// Push to remote
  Future<void> push({
    String remote = 'origin',
    required String branch,
    bool force = false,
    bool setUpstream = false,
  }) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.push(
      path: path,
      remote: remote,
      branch: branch,
      force: force,
      setUpstream: setUpstream,
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (_) async {
        await refresh();
      },
    );
  }

  /// Pull from remote
  Future<void> pull({
    String remote = 'origin',
    bool rebase = false,
  }) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.pull(
      path: path,
      remote: remote,
      rebase: rebase,
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (_) async {
        await refresh();
      },
    );
  }

  /// Fetch from remote
  Future<void> fetch({String remote = 'origin'}) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true);

    final result = await _gitService.fetch(
      path: path,
      remote: remote,
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (_) async {
        await refresh();
      },
    );
  }

  /// Toggle file selection
  void toggleFileSelection(FileChange file) {
    final selected = List<FileChange>.from(state.selectedFiles);
    if (selected.contains(file)) {
      selected.remove(file);
    } else {
      selected.add(file);
    }
    state = state.copyWith(selectedFiles: selected);
  }

  /// Clear file selection
  void clearSelection() {
    state = state.copyWith(selectedFiles: []);
  }

  /// Select all files
  void selectAll() {
    final repository = state.repository;
    if (repository == null) return;

    state = state.copyWith(
      selectedFiles: [...repository.changes, ...repository.stagedChanges],
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Commit history provider
@riverpod
class CommitHistoryNotifier extends _$CommitHistoryNotifier {
  @override
  AsyncValue<List<GitCommit>> build() {
    return const AsyncValue.loading();
  }

  GitService get _gitService => ref.read(gitServiceProvider);

  /// Load commit history
  Future<void> load({
    int maxCount = 100,
    int skip = 0,
  }) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) {
      state = AsyncValue.error('No repository opened', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();

    final result = await _gitService.getHistory(
      path: path,
      maxCount: maxCount,
      skip: skip,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.userMessage, StackTrace.current);
      },
      (commits) {
        state = AsyncValue.data(commits);
      },
    );
  }

  /// Load more commits (pagination)
  Future<void> loadMore() async {
    final currentData = state.value;
    if (currentData == null) return;

    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    final result = await _gitService.getHistory(
      path: path,
      maxCount: 50,
      skip: currentData.length,
    );

    result.fold(
      (failure) {
        // Keep current data on error
      },
      (newCommits) {
        state = AsyncValue.data([...currentData, ...newCommits]);
      },
    );
  }
}
