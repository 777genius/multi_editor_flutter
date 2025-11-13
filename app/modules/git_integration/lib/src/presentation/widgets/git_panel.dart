import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/file_change.dart';
import '../../domain/value_objects/file_status.dart';
import '../providers/git_state_provider.dart';
import 'commit_dialog.dart';

/// Git panel widget
///
/// Main panel for git operations showing:
/// - Current branch
/// - Changed files (staged/unstaged)
/// - Quick actions (stage, unstage, commit, push, pull)
class GitPanel extends ConsumerStatefulWidget {
  const GitPanel({super.key});

  @override
  ConsumerState<GitPanel> createState() => _GitPanelState();
}

class _GitPanelState extends ConsumerState<GitPanel> {
  bool _showStagedFiles = true;
  bool _showUnstagedFiles = true;

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
        Expanded(
          child: gitState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(context, gitState),
        ),
        if (gitState.hasError) _buildErrorBar(context, gitState),
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
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => _refresh(),
                tooltip: 'Refresh',
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

  Widget _buildSyncButton(BuildContext context, repository) {
    // Check ahead/behind status
    // For now, just show sync button
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
        if (expanded && isStaged) _buildCommitButton(context),
      ],
    );
  }

  Widget _buildFileItem(
    BuildContext context, {
    required FileChange change,
    required bool isStaged,
  }) {
    return ListTile(
      dense: true,
      leading: _buildStatusIcon(context, change.status),
      title: Text(
        change.fileName,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        change.directoryPath,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isStaged ? Icons.remove : Icons.add,
              size: 18,
            ),
            onPressed: () {
              if (isStaged) {
                _unstageFile(change.filePath);
              } else {
                _stageFile(change.filePath);
              }
            },
            tooltip: isStaged ? 'Unstage' : 'Stage',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 18),
            onPressed: () => _showFileMenu(context, change),
          ),
        ],
      ),
      onTap: () => _openDiff(change.filePath, isStaged),
    );
  }

  Widget _buildStatusIcon(BuildContext context, FileStatus status) {
    return status.when(
      unmodified: () => Icon(Icons.check, size: 16,
          color: Theme.of(context).colorScheme.outline),
      added: () => Icon(Icons.add_circle, size: 16,
          color: Colors.green),
      modified: () => Icon(Icons.edit, size: 16,
          color: Colors.blue),
      deleted: () => Icon(Icons.delete, size: 16,
          color: Colors.red),
      renamed: () => Icon(Icons.drive_file_rename_outline, size: 16,
          color: Colors.orange),
      copied: () => Icon(Icons.copy, size: 16,
          color: Colors.orange),
      untracked: () => Icon(Icons.help_outline, size: 16,
          color: Colors.grey),
      ignored: () => Icon(Icons.block, size: 16,
          color: Colors.grey),
      conflicted: () => Icon(Icons.warning, size: 16,
          color: Colors.red),
    );
  }

  Widget _buildCommitButton(BuildContext context) {
    final gitState = ref.watch(gitRepositoryNotifierProvider);
    final hasStagedChanges = gitState.hasStagedChanges;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: hasStagedChanges ? _showCommitDialog : null,
          icon: const Icon(Icons.check),
          label: const Text('Commit'),
        ),
      ),
    );
  }

  Widget _buildErrorBar(BuildContext context, GitRepositoryState gitState) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              gitState.error!.userMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              ref.read(gitRepositoryNotifierProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }

  void _showFileMenu(BuildContext context, FileChange change) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Diff'),
            onTap: () {
              Navigator.pop(context);
              _openDiff(change.filePath, change.isStaged);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('View History'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show file history
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Discard Changes'),
            onTap: () {
              Navigator.pop(context);
              _discardChanges(change.filePath);
            },
          ),
        ],
      ),
    );
  }

  void _refresh() {
    ref.read(gitRepositoryNotifierProvider.notifier).refresh();
  }

  void _stageFile(String filePath) {
    ref.read(gitRepositoryNotifierProvider.notifier).stageFiles([filePath]);
  }

  void _stageAll() {
    ref.read(gitRepositoryNotifierProvider.notifier).stageAll();
  }

  void _unstageFile(String filePath) {
    ref.read(gitRepositoryNotifierProvider.notifier).unstageFiles([filePath]);
  }

  void _unstageAll() {
    ref.read(gitRepositoryNotifierProvider.notifier).unstageAll();
  }

  void _showCommitDialog() {
    showDialog(
      context: context,
      builder: (context) => const CommitDialog(),
    );
  }

  void _pull() {
    ref.read(gitRepositoryNotifierProvider.notifier).pull();
  }

  void _push() {
    final gitState = ref.read(gitRepositoryNotifierProvider);
    final currentBranch =
        gitState.repository?.currentBranch?.toNullable()?.name.value;

    if (currentBranch != null) {
      ref.read(gitRepositoryNotifierProvider.notifier).push(
            branch: currentBranch,
          );
    }
  }

  void _fetch() {
    ref.read(gitRepositoryNotifierProvider.notifier).fetch();
  }

  void _openDiff(String filePath, bool staged) {
    // TODO: Open diff viewer
  }

  void _discardChanges(String filePath) {
    // TODO: Implement discard changes
  }
}
