import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/diff_hunk.dart';
import '../../domain/failures/git_failures.dart';
import '../../application/services/diff_service.dart';
import 'git_state_provider.dart';

part 'diff_state_provider.g.dart';

/// Diff view mode
enum DiffViewMode {
  sideBySide,
  unified,
}

/// Diff state
class DiffState {
  final Map<String, List<DiffHunk>> fileDiffs;
  final String? selectedFile;
  final DiffViewMode viewMode;
  final bool isLoading;
  final GitFailure? error;
  final bool showContext;
  final int contextLines;

  const DiffState({
    this.fileDiffs = const {},
    this.selectedFile,
    this.viewMode = DiffViewMode.sideBySide,
    this.isLoading = false,
    this.error,
    this.showContext = true,
    this.contextLines = 3,
  });

  DiffState copyWith({
    Map<String, List<DiffHunk>>? fileDiffs,
    String? selectedFile,
    DiffViewMode? viewMode,
    bool? isLoading,
    GitFailure? error,
    bool? showContext,
    int? contextLines,
    bool clearError = false,
    bool clearSelection = false,
  }) {
    return DiffState(
      fileDiffs: fileDiffs ?? this.fileDiffs,
      selectedFile:
          clearSelection ? null : (selectedFile ?? this.selectedFile),
      viewMode: viewMode ?? this.viewMode,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      showContext: showContext ?? this.showContext,
      contextLines: contextLines ?? this.contextLines,
    );
  }

  List<DiffHunk>? get selectedDiff =>
      selectedFile != null ? fileDiffs[selectedFile] : null;
  bool get hasFiles => fileDiffs.isNotEmpty;
  bool get hasError => error != null;
  int get totalFiles => fileDiffs.length;

  int get totalAdditions {
    var count = 0;
    for (final hunks in fileDiffs.values) {
      for (final hunk in hunks) {
        count += hunk.addedLinesCount;
      }
    }
    return count;
  }

  int get totalDeletions {
    var count = 0;
    for (final hunks in fileDiffs.values) {
      for (final hunk in hunks) {
        count += hunk.removedLinesCount;
      }
    }
    return count;
  }
}

/// Diff service provider
@riverpod
DiffService diffService(DiffServiceRef ref) {
  return GetIt.instance<DiffService>();
}

/// Diff state provider
@riverpod
class DiffNotifier extends _$DiffNotifier {
  @override
  DiffState build() {
    return const DiffState();
  }

  DiffService get _diffService => ref.read(diffServiceProvider);

  /// Load staged diff
  Future<void> loadStagedDiff() async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _diffService.getStagedDiff(path: path);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (fileDiffs) {
        state = state.copyWith(
          fileDiffs: fileDiffs,
          isLoading: false,
          clearError: true,
          // Auto-select first file if any
          selectedFile:
              fileDiffs.isNotEmpty ? fileDiffs.keys.first : null,
        );
      },
    );
  }

  /// Load unstaged diff
  Future<void> loadUnstagedDiff() async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _diffService.getUnstagedDiff(path: path);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (fileDiffs) {
        state = state.copyWith(
          fileDiffs: fileDiffs,
          isLoading: false,
          clearError: true,
          selectedFile:
              fileDiffs.isNotEmpty ? fileDiffs.keys.first : null,
        );
      },
    );
  }

  /// Load diff for specific file
  Future<void> loadFileDiff({
    required String filePath,
    bool staged = false,
  }) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _diffService.getFileDiff(
      path: path,
      filePath: filePath,
      staged: staged,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (hunks) {
        final fileDiffs = Map<String, List<DiffHunk>>.from(state.fileDiffs);
        fileDiffs[filePath] = hunks;

        state = state.copyWith(
          fileDiffs: fileDiffs,
          isLoading: false,
          clearError: true,
          selectedFile: filePath,
        );
      },
    );
  }

  /// Load diff between commits
  Future<void> loadCommitDiff({
    required String oldCommit,
    required String newCommit,
  }) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _diffService.getDiffBetweenCommits(
      path: path,
      oldCommit: oldCommit,
      newCommit: newCommit,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (fileDiffs) {
        state = state.copyWith(
          fileDiffs: fileDiffs,
          isLoading: false,
          clearError: true,
          selectedFile:
              fileDiffs.isNotEmpty ? fileDiffs.keys.first : null,
        );
      },
    );
  }

  /// Select file
  void selectFile(String filePath) {
    state = state.copyWith(selectedFile: filePath);
  }

  /// Set view mode
  void setViewMode(DiffViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Toggle context lines
  void toggleContext() {
    state = state.copyWith(showContext: !state.showContext);
  }

  /// Set context lines count
  void setContextLines(int lines) {
    state = state.copyWith(contextLines: lines);
  }

  /// Clear diff
  void clear() {
    state = const DiffState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Diff statistics provider
@riverpod
DiffStatistics? diffStatistics(DiffStatisticsRef ref) {
  final diffState = ref.watch(diffNotifierProvider);
  final selectedDiff = diffState.selectedDiff;

  if (selectedDiff == null || selectedDiff.isEmpty) {
    return null;
  }

  final diffService = ref.read(diffServiceProvider);
  return diffService.calculateStatistics(selectedDiff);
}
