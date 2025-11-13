import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/blame_line.dart';
import '../../domain/failures/git_failures.dart';
import '../../application/services/blame_service.dart';
import 'git_state_provider.dart';

part 'blame_state_provider.g.dart';

/// Blame state
class BlameState {
  final List<BlameLine> blameLines;
  final String? filePath;
  final bool isLoading;
  final GitFailure? error;
  final int? selectedLineNumber;
  final BlameTooltip? tooltip;
  final Map<String, int>? authorContribution;
  final List<int>? heatMap;

  const BlameState({
    this.blameLines = const [],
    this.filePath,
    this.isLoading = false,
    this.error,
    this.selectedLineNumber,
    this.tooltip,
    this.authorContribution,
    this.heatMap,
  });

  BlameState copyWith({
    List<BlameLine>? blameLines,
    String? filePath,
    bool? isLoading,
    GitFailure? error,
    int? selectedLineNumber,
    BlameTooltip? tooltip,
    Map<String, int>? authorContribution,
    List<int>? heatMap,
    bool clearError = false,
    bool clearSelection = false,
    bool clearTooltip = false,
  }) {
    return BlameState(
      blameLines: blameLines ?? this.blameLines,
      filePath: filePath ?? this.filePath,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedLineNumber: clearSelection
          ? null
          : (selectedLineNumber ?? this.selectedLineNumber),
      tooltip: clearTooltip ? null : (tooltip ?? this.tooltip),
      authorContribution: authorContribution ?? this.authorContribution,
      heatMap: heatMap ?? this.heatMap,
    );
  }

  bool get hasBlame => blameLines.isNotEmpty;
  bool get hasError => error != null;
  bool get hasSelection => selectedLineNumber != null;
  bool get hasTooltip => tooltip != null;
  bool get hasHeatMap => heatMap != null && heatMap!.isNotEmpty;
}

/// Blame service provider
@riverpod
BlameService blameService(BlameServiceRef ref) {
  return GetIt.instance<BlameService>();
}

/// Blame state provider
@riverpod
class BlameNotifier extends _$BlameNotifier {
  @override
  BlameState build() {
    return const BlameState();
  }

  BlameService get _blameService => ref.read(blameServiceProvider);

  /// Load blame for file
  Future<void> loadBlame({
    required String filePath,
    int? startLine,
    int? endLine,
  }) async {
    final path = ref.read(currentRepositoryPathProvider);
    if (path == null) return;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      filePath: filePath,
    );

    // Load blame lines
    final blameResult = await _blameService.getBlame(
      path: path,
      filePath: filePath,
      startLine: startLine,
      endLine: endLine,
    );

    await blameResult.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure,
        );
      },
      (blameLines) async {
        // Load author contribution
        final contributionResult =
            await _blameService.getAuthorContribution(
          path: path,
          filePath: filePath,
        );

        final contribution = contributionResult.fold(
          (_) => <String, int>{},
          (data) => data.map((k, v) => MapEntry(k, v.round())),
        );

        // Load heat map
        final heatMapResult = await _blameService.getBlameHeatMap(
          path: path,
          filePath: filePath,
        );

        final heatMap = heatMapResult.fold(
          (_) => <int>[],
          (data) => data,
        );

        state = state.copyWith(
          blameLines: blameLines,
          isLoading: false,
          clearError: true,
          authorContribution: contribution,
          heatMap: heatMap,
        );
      },
    );
  }

  /// Select line and show tooltip
  Future<void> selectLine(int lineNumber) async {
    final path = ref.read(currentRepositoryPathProvider);
    final filePath = state.filePath;

    if (path == null || filePath == null) return;

    state = state.copyWith(selectedLineNumber: lineNumber);

    // Load tooltip
    final tooltipResult = await _blameService.getLineTooltip(
      path: path,
      filePath: filePath,
      lineNumber: lineNumber,
    );

    tooltipResult.fold(
      (failure) {
        // Tooltip loading failed, keep line selected
      },
      (tooltip) {
        state = state.copyWith(tooltip: tooltip);
      },
    );
  }

  /// Clear selection and tooltip
  void clearSelection() {
    state = state.copyWith(
      clearSelection: true,
      clearTooltip: true,
    );
  }

  /// Get heat map color for line
  int? getHeatMapColor(int lineNumber) {
    final heatMap = state.heatMap;
    if (heatMap == null || lineNumber >= heatMap.length) {
      return null;
    }

    final age = heatMap[lineNumber];

    // Color gradient based on age (in days)
    // 0-7 days: Green (fresh)
    // 7-30 days: Yellow (recent)
    // 30-90 days: Orange (aging)
    // 90+ days: Red (old)

    if (age <= 7) {
      return 0xFF4CAF50; // Green
    } else if (age <= 30) {
      return 0xFFFFEB3B; // Yellow
    } else if (age <= 90) {
      return 0xFFFF9800; // Orange
    } else {
      return 0xFFF44336; // Red
    }
  }

  /// Clear blame
  void clear() {
    state = const BlameState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Author contribution chart data provider
@riverpod
List<AuthorContribution> authorContributionChart(
    AuthorContributionChartRef ref) {
  final blameState = ref.watch(blameNotifierProvider);
  final contribution = blameState.authorContribution;

  if (contribution == null || contribution.isEmpty) {
    return [];
  }

  return contribution.entries
      .map((e) => AuthorContribution(
            author: e.key,
            percentage: e.value,
          ))
      .toList()
    ..sort((a, b) => b.percentage.compareTo(a.percentage));
}

/// Author contribution data
class AuthorContribution {
  final String author;
  final int percentage;

  AuthorContribution({
    required this.author,
    required this.percentage,
  });
}
