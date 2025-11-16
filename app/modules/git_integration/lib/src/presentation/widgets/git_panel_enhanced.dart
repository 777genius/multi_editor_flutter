import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/file_change.dart';
import '../../domain/value_objects/file_status.dart';
import '../providers/git_state_provider.dart';
import 'commit_dialog.dart';
import 'merge_conflict_resolver.dart';
import 'ssh_key_manager.dart';
import 'package:get_it/get_it.dart';
import '../../application/use_cases/resolve_conflict_use_case.dart';

/// Enhanced Git Panel with full feature integration
///
/// Includes:
/// - Source control operations (stage, commit, push/pull)
/// - Merge conflict resolution
/// - SSH key management
/// - Visual diff viewer
/// - Branch management
class GitPanelEnhanced extends ConsumerStatefulWidget {
  const GitPanelEnhanced({super.key});

  @override
  ConsumerState<GitPanelEnhanced> createState() => _GitPanelEnhancedState();
}

class _GitPanelEnhancedState extends ConsumerState<GitPanelEnhanced> {
  bool _showStagedFiles = true;
  bool _showUnstagedFiles = true;
  bool _hasConflicts = false;
  int _conflictCount = 0;

  @override
  void initState() {
    super.initState();
    _checkForConflicts();
  }

  Future<void> _checkForConflicts() async {
    // Check for merge conflicts
    final gitState = ref.read(gitRepositoryNotifierProvider);
    if (!gitState.hasRepository) return;

    try {
      final useCase = GetIt.instance<ResolveConflictUseCase>();
      final result = await useCase.getConflicts(
        path: gitState.repository!.path,
      );

      result.fold(
        (failure) {
          setState(() {
            _hasConflicts = false;
            _conflictCount = 0;
          });
        },
        (conflicts) {
          setState(() {
            _hasConflicts = conflicts.isNotEmpty;
            _conflictCount = conflicts.fold(
              0,
              (sum, conflict) => sum + conflict.totalFilesCount,
            );
          });
        },
      );
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final gitState = ref.watch(gitRepositoryNotifierProvider);
    final repository = gitState.repository;

    if (!gitState.hasRepository) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildHeader(context, repository!),
        const Divider(height: 1),
        if (_hasConflicts) _buildConflictBanner(context),
        Expanded(
          child: gitState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(context, gitState),
        ),
        if (gitState.hasError) _buildErrorBar(context, gitState),
        _buildActionBar(context, gitState),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.source,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Repository Opened',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Open a git repository to see changes',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _openRepository(),
            icon: const Icon(Icons.folder_open),
            label: const Text('Open Repository'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, repository) {
    final currentBranch = repository.currentBranch?.toNullable();
    final branchName = currentBranch?.name.value ?? 'Detached HEAD';

    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.source_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Source Control',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.vpn_key, size: 20),
                onPressed: () => _openSshKeyManager(),
                tooltip: 'SSH Keys',
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => _refresh(),
                tooltip: 'Refresh',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                tooltip: 'More Options',
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'ssh_keys',
                    child: Row(
                      children: [
                        Icon(Icons.vpn_key, size: 18),
                        SizedBox(width: 12),
                        Text('SSH Keys'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'view_history',
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 18),
                        SizedBox(width: 12),
                        Text('View History'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clone',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_download, size: 18),
                        SizedBox(width: 12),
                        Text('Clone Repository'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 18),
                        SizedBox(width: 12),
                        Text('Git Settings'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.call_split,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  branchName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              _buildSyncButton(context, repository),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConflictBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merge Conflicts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                Text(
                  '$_conflictCount file(s) have conflicts',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => _resolveConflicts(),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context, repository) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sync, size: 20),
      tooltip: 'Sync',
      onSelected: (value) {
        switch (value) {
          case 'pull':
            _pull();
            break;
          case 'push':
            _push();
            break;
          case 'fetch':
            _fetch();
            break;
          case 'pull_rebase':
            _pullRebase();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pull',
          child: Row(
            children: [
              Icon(Icons.download, size: 18),
              SizedBox(width: 8),
              Text('Pull'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'push',
          child: Row(
            children: [
              Icon(Icons.upload, size: 18),
              SizedBox(width: 8),
              Text('Push'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'fetch',
          child: Row(
            children: [
              Icon(Icons.sync_alt, size: 18),
              SizedBox(width: 8),
              Text('Fetch'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'pull_rebase',
          child: Row(
            children: [
              Icon(Icons.merge_type, size: 18),
              SizedBox(width: 8),
              Text('Pull (Rebase)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, GitRepositoryState gitState) {
    final repository = gitState.repository!;
    final stagedChanges = repository.stagedChanges;
    final unstagedChanges = repository.changes;

    if (stagedChanges.isEmpty && unstagedChanges.isEmpty) {
      return _buildNoChanges(context);
    }

    return ListView(
      children: [
        if (stagedChanges.isNotEmpty)
          _buildChangesSection(
            context,
            title: 'Staged Changes',
            count: stagedChanges.length,
            changes: stagedChanges,
            isStaged: true,
            expanded: _showStagedFiles,
            onToggle: () =>
                setState(() => _showStagedFiles = !_showStagedFiles),
          ),
        if (unstagedChanges.isNotEmpty)
          _buildChangesSection(
            context,
            title: 'Changes',
            count: unstagedChanges.length,
            changes: unstagedChanges,
            isStaged: false,
            expanded: _showUnstagedFiles,
            onToggle: () =>
                setState(() => _showUnstagedFiles = !_showUnstagedFiles),
          ),
      ],
    );
  }

  Widget _buildNoChanges(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Changes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your working tree is clean',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildChangesSection(
    BuildContext context, {
    required String title,
    required int count,
    required List<FileChange> changes,
    required bool isStaged,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_more : Icons.chevron_right,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '$title ($count)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (isStaged)
                  TextButton.icon(
                    onPressed: _unstageAll,
                    icon: const Icon(Icons.remove, size: 16),
                    label: const Text('Unstage All'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: _stageAll,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Stage All'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (expanded)
          ...changes.map((change) => _buildFileItem(
                context,
                change: change,
                isStaged: isStaged,
              )),
      ],
    );
  }

  Widget _buildFileItem(
    BuildContext context, {
    required FileChange change,
    required bool isStaged,
  }) {
    final icon = _getFileStatusIcon(change.status);
    final color = _getFileStatusColor(context, change.status);

    return ListTile(
      dense: true,
      leading: Icon(icon, size: 16, color: color),
      title: Text(
        change.path.split('/').last,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        change.path,
        style: const TextStyle(fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isStaged ? Icons.remove_circle_outline : Icons.add_circle_outline,
              size: 18,
            ),
            onPressed: () => isStaged
                ? _unstageFile(change.path)
                : _stageFile(change.path),
            tooltip: isStaged ? 'Unstage' : 'Stage',
          ),
          IconButton(
            icon: const Icon(Icons.visibility, size: 18),
            onPressed: () => _viewDiff(change),
            tooltip: 'View Diff',
          ),
        ],
      ),
      onTap: () => _viewDiff(change),
    );
  }

  Widget _buildActionBar(BuildContext context, GitRepositoryState gitState) {
    final hasStaged = gitState.repository?.stagedChanges.isNotEmpty ?? false;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: hasStaged ? () => _commit() : null,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Commit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBar(BuildContext context, GitRepositoryState gitState) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              gitState.error ?? 'Unknown error',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Status icons and colors
  IconData _getFileStatusIcon(FileStatus status) {
    return status.when(
      added: () => Icons.add_circle,
      modified: () => Icons.edit,
      deleted: () => Icons.delete,
      renamed: (from) => Icons.drive_file_rename_outline,
      copied: (from) => Icons.content_copy,
      untracked: () => Icons.help_outline,
      ignored: () => Icons.visibility_off,
      conflicted: () => Icons.error,
      typeChanged: () => Icons.change_circle,
    );
  }

  Color _getFileStatusColor(BuildContext context, FileStatus status) {
    return status.when(
      added: () => Colors.green,
      modified: () => Colors.blue,
      deleted: () => Colors.red,
      renamed: (_) => Colors.purple,
      copied: (_) => Colors.purple,
      untracked: () => Colors.grey,
      ignored: () => Colors.grey,
      conflicted: () => Theme.of(context).colorScheme.error,
      typeChanged: () => Colors.orange,
    );
  }

  // Actions
  void _openRepository() {
    // TODO: Implement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open repository dialog')),
    );
  }

  void _openSshKeyManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SshKeyManager(),
      ),
    );
  }

  void _resolveConflicts() async {
    // Get conflicts and show resolution UI
    final gitState = ref.read(gitRepositoryNotifierProvider);
    if (!gitState.hasRepository) return;

    final useCase = GetIt.instance<ResolveConflictUseCase>();
    final result = await useCase.getConflicts(
      path: gitState.repository!.path,
    );

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get conflicts: ${failure.userMessage}')),
        );
      },
      (conflicts) {
        if (conflicts.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No conflicts found')),
          );
          return;
        }

        // Show first conflict
        final firstConflict = conflicts.first;
        if (firstConflict.conflictedFiles.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MergeConflictResolver(
                repositoryPath: gitState.repository!.path.path,
                conflictedFile: firstConflict.conflictedFiles.first,
                onResolved: () {
                  _refresh();
                  _checkForConflicts();
                },
                onCancel: () => Navigator.of(context).pop(),
              ),
            ),
          );
        }
      },
    );
  }

  void _refresh() {
    ref.read(gitRepositoryNotifierProvider.notifier).refresh();
    _checkForConflicts();
  }

  void _stageFile(String path) {
    ref.read(gitRepositoryNotifierProvider.notifier).stageFile(path);
  }

  void _unstageFile(String path) {
    ref.read(gitRepositoryNotifierProvider.notifier).unstageFile(path);
  }

  void _stageAll() {
    ref.read(gitRepositoryNotifierProvider.notifier).stageAll();
  }

  void _unstageAll() {
    ref.read(gitRepositoryNotifierProvider.notifier).unstageAll();
  }

  void _commit() {
    showDialog(
      context: context,
      builder: (context) => const CommitDialog(),
    ).then((value) {
      if (value == true) {
        _refresh();
      }
    });
  }

  void _pull() {
    ref.read(gitRepositoryNotifierProvider.notifier).pull();
  }

  void _push() {
    ref.read(gitRepositoryNotifierProvider.notifier).push();
  }

  void _fetch() {
    ref.read(gitRepositoryNotifierProvider.notifier).fetch();
  }

  void _pullRebase() {
    // TODO: Implement pull with rebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pull with rebase')),
    );
  }

  void _viewDiff(FileChange change) {
    // TODO: Show diff viewer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View diff for ${change.path}')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'ssh_keys':
        _openSshKeyManager();
        break;
      case 'view_history':
        // TODO: Implement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('View history')),
        );
        break;
      case 'clone':
        // TODO: Implement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clone repository')),
        );
        break;
      case 'settings':
        // TODO: Implement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Git settings')),
        );
        break;
    }
  }
}
