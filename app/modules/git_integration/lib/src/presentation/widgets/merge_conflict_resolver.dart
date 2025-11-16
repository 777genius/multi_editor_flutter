import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/github-dark.dart';
import '../../domain/entities/merge_conflict.dart';
import '../../application/use_cases/resolve_conflict_use_case.dart';
import '../../domain/value_objects/repository_path.dart';
import 'package:get_it/get_it.dart';

/// Merge Conflict Resolver Widget
///
/// Provides interactive UI for resolving merge conflicts with:
/// - Three-way merge view (base, current, incoming)
/// - Multiple resolution strategies
/// - Manual editing support
/// - Real-time preview
class MergeConflictResolver extends ConsumerStatefulWidget {
  final String repositoryPath;
  final ConflictedFile conflictedFile;
  final VoidCallback? onResolved;
  final VoidCallback? onCancel;

  const MergeConflictResolver({
    super.key,
    required this.repositoryPath,
    required this.conflictedFile,
    this.onResolved,
    this.onCancel,
  });

  @override
  ConsumerState<MergeConflictResolver> createState() =>
      _MergeConflictResolverState();
}

class _MergeConflictResolverState
    extends ConsumerState<MergeConflictResolver> {
  late TextEditingController _manualController;
  ConflictResolutionStrategy _selectedStrategy =
      ConflictResolutionStrategy.manual;
  bool _isResolving = false;
  String? _errorMessage;
  String _previewContent = '';

  @override
  void initState() {
    super.initState();
    _manualController = TextEditingController(
      text: widget.conflictedFile.ourContent,
    );
    _updatePreview();
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    setState(() {
      switch (_selectedStrategy) {
        case ConflictResolutionStrategy.keepCurrent:
          _previewContent = widget.conflictedFile.ourContent;
          break;
        case ConflictResolutionStrategy.acceptIncoming:
          _previewContent = widget.conflictedFile.theirContent;
          break;
        case ConflictResolutionStrategy.acceptBoth:
          _previewContent = widget.conflictedFile.ourContent +
              '\n' +
              widget.conflictedFile.theirContent;
          break;
        case ConflictResolutionStrategy.manual:
          _previewContent = _manualController.text;
          break;
      }
    });
  }

  Future<void> _resolveConflict() async {
    setState(() {
      _isResolving = true;
      _errorMessage = null;
    });

    try {
      final useCase = GetIt.instance<ResolveConflictUseCase>();
      final repoPath = RepositoryPath.create(widget.repositoryPath);

      final result = _selectedStrategy == ConflictResolutionStrategy.manual
          ? await useCase.resolveWithContent(
              path: repoPath,
              filePath: widget.conflictedFile.filePath,
              resolvedContent: _manualController.text,
            )
          : await useCase.resolveWithStrategy(
              path: repoPath,
              filePath: widget.conflictedFile.filePath,
              strategy: _selectedStrategy,
            );

      result.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.userMessage;
            _isResolving = false;
          });
        },
        (_) {
          setState(() {
            _isResolving = false;
          });
          widget.onResolved?.call();
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isResolving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resolve Conflict: ${widget.conflictedFile.fileName}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        actions: [
          if (_errorMessage != null)
            IconButton(
              icon: const Icon(Icons.error_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error'),
                    content: Text(_errorMessage!),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildConflictInfo(),
          const Divider(height: 1),
          Expanded(
            child: _buildConflictView(),
          ),
          const Divider(height: 1),
          _buildResolutionPanel(),
        ],
      ),
    );
  }

  Widget _buildConflictInfo() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            Icons.merge_type,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conflictedFile.filePath,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.conflictedFile.conflictCount} conflict(s) found',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          if (widget.conflictedFile.isResolved)
            Chip(
              label: const Text('Resolved'),
              backgroundColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConflictView() {
    return Column(
      children: [
        _buildStrategySelector(),
        Expanded(
          child: _selectedStrategy == ConflictResolutionStrategy.manual
              ? _buildManualEditor()
              : _buildThreeWayMergeView(),
        ),
      ],
    );
  }

  Widget _buildStrategySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resolution Strategy',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStrategyChip(
                strategy: ConflictResolutionStrategy.keepCurrent,
                label: 'Keep Current (Ours)',
                icon: Icons.check_circle_outline,
                description: 'Accept all changes from current branch',
              ),
              _buildStrategyChip(
                strategy: ConflictResolutionStrategy.acceptIncoming,
                label: 'Accept Incoming (Theirs)',
                icon: Icons.download,
                description: 'Accept all changes from incoming branch',
              ),
              _buildStrategyChip(
                strategy: ConflictResolutionStrategy.acceptBoth,
                label: 'Accept Both',
                icon: Icons.merge_type,
                description: 'Combine both changes',
              ),
              _buildStrategyChip(
                strategy: ConflictResolutionStrategy.manual,
                label: 'Manual Edit',
                icon: Icons.edit,
                description: 'Manually edit the resolution',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyChip({
    required ConflictResolutionStrategy strategy,
    required String label,
    required IconData icon,
    required String description,
  }) {
    final isSelected = _selectedStrategy == strategy;
    final theme = Theme.of(context);

    return Tooltip(
      message: description,
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedStrategy = strategy;
              _updatePreview();
            });
          }
        },
        selectedColor: theme.colorScheme.primaryContainer,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildManualEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Manual Resolution',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _manualController.text),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Content copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _manualController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Edit the resolved content here...',
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: (_) => _updatePreview(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreeWayMergeView() {
    return Row(
      children: [
        Expanded(
          child: _buildVersionPanel(
            title: 'Current (Ours)',
            content: widget.conflictedFile.ourContent,
            color: Colors.blue,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _buildVersionPanel(
            title: 'Base (Common Ancestor)',
            content: widget.conflictedFile.baseContent,
            color: Colors.grey,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _buildVersionPanel(
            title: 'Incoming (Theirs)',
            content: widget.conflictedFile.theirContent,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildVersionPanel({
    required String title,
    required String content,
    required Color color,
  }) {
    final extension = widget.conflictedFile.filePath.split('.').last;
    final language = _getLanguageFromExtension(extension);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: color.withOpacity(0.1),
          child: Row(
            children: [
              Icon(Icons.code, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: language != null
                ? HighlightView(
                    content,
                    language: language,
                    theme: Theme.of(context).brightness == Brightness.dark
                        ? githubDarkTheme
                        : githubTheme,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  )
                : Text(
                    content,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildResolutionPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            'Preview',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: Text(
                _previewContent,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isResolving ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isResolving ? null : _resolveConflict,
                icon: _isResolving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isResolving ? 'Resolving...' : 'Resolve Conflict'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _getLanguageFromExtension(String extension) {
    const languageMap = {
      'dart': 'dart',
      'js': 'javascript',
      'ts': 'typescript',
      'jsx': 'javascript',
      'tsx': 'typescript',
      'py': 'python',
      'java': 'java',
      'kt': 'kotlin',
      'swift': 'swift',
      'rs': 'rust',
      'go': 'go',
      'cpp': 'cpp',
      'c': 'c',
      'cs': 'csharp',
      'rb': 'ruby',
      'php': 'php',
      'html': 'xml',
      'xml': 'xml',
      'json': 'json',
      'yaml': 'yaml',
      'yml': 'yaml',
      'md': 'markdown',
      'sh': 'bash',
      'sql': 'sql',
      'css': 'css',
      'scss': 'scss',
    };

    return languageMap[extension.toLowerCase()];
  }
}

/// Merge Conflicts List Widget
///
/// Shows all conflicts in the repository with resolution progress
class MergeConflictsList extends ConsumerWidget {
  final String repositoryPath;
  final List<ConflictedFile> conflicts;
  final Function(ConflictedFile) onResolveConflict;

  const MergeConflictsList({
    super.key,
    required this.repositoryPath,
    required this.conflicts,
    required this.onResolveConflict,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (conflicts.isEmpty) {
      return _buildEmptyState(context);
    }

    final resolvedCount = conflicts.where((c) => c.isResolved).length;
    final progress = resolvedCount / conflicts.length;

    return Column(
      children: [
        _buildProgressHeader(context, resolvedCount, conflicts.length, progress),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: conflicts.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conflict = conflicts[index];
              return _buildConflictTile(context, conflict);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Conflicts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'All merge conflicts have been resolved',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(
    BuildContext context,
    int resolvedCount,
    int totalCount,
    double progress,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.merge_type,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Merge Conflicts ($resolvedCount/$totalCount resolved)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictTile(BuildContext context, ConflictedFile conflict) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        conflict.isResolved ? Icons.check_circle : Icons.error_outline,
        color: conflict.isResolved
            ? theme.colorScheme.primary
            : theme.colorScheme.error,
      ),
      title: Text(
        conflict.filePath,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        '${conflict.conflictCount} conflict(s)' +
            (conflict.isResolved ? ' - Resolved' : ''),
        style: TextStyle(
          color: conflict.isResolved
              ? theme.colorScheme.primary
              : theme.colorScheme.error,
        ),
      ),
      trailing: conflict.isResolved
          ? null
          : FilledButton(
              onPressed: () => onResolveConflict(conflict),
              child: const Text('Resolve'),
            ),
      onTap: () => onResolveConflict(conflict),
    );
  }
}
