import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/git_branch.dart';
import '../providers/git_state_provider.dart';
import '../utils/git_ui_utils.dart';

/// Branch selector widget
///
/// Shows list of branches with:
/// - Current branch indicator
/// - Local and remote branches
/// - Branch actions (checkout, delete, create)
/// - Search/filter branches
class BranchSelector extends ConsumerStatefulWidget {
  final bool showCreateButton;

  const BranchSelector({
    super.key,
    this.showCreateButton = true,
  });

  @override
  ConsumerState<BranchSelector> createState() => _BranchSelectorState();
}

class _BranchSelectorState extends ConsumerState<BranchSelector> {
  final _searchController = TextEditingController();
  final _searchDebouncer = Debouncer(milliseconds: 300);
  bool _showRemoteBranches = true;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gitState = ref.watch(gitRepositoryNotifierProvider);
    final repository = gitState.repository;

    if (!gitState.hasRepository) {
      return _buildEmptyState();
    }

    final localBranches = _filterBranches(repository!.localBranches);
    final remoteBranches = _showRemoteBranches
        ? _filterBranches(repository.remoteBranches)
        : <GitBranch>[];

    return Column(
      children: [
        _buildToolbar(context),
        const Divider(height: 1),
        _buildSearchBar(),
        Expanded(
          child: gitState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildBranchList(
                  context,
                  localBranches: localBranches,
                  remoteBranches: remoteBranches,
                  currentBranch: repository.currentBranch?.toNullable(),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_split,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Repository',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            Icons.call_split,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Branches',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (widget.showCreateButton)
            FilledButton.tonalIcon(
              onPressed: _showCreateBranchDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search branches...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Debounce search to avoid excessive rebuilds
                _searchDebouncer.run(() {
                  if (mounted) {
                    setState(() {
                      _searchQuery = value;
                    });
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Remote'),
            selected: _showRemoteBranches,
            onSelected: (value) {
              setState(() {
                _showRemoteBranches = value;
              });
            },
            avatar: Icon(
              _showRemoteBranches ? Icons.cloud : Icons.cloud_outlined,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchList(
    BuildContext context, {
    required List<GitBranch> localBranches,
    required List<GitBranch> remoteBranches,
    required GitBranch? currentBranch,
  }) {
    return ListView(
      children: [
        if (localBranches.isNotEmpty) ...[
          _buildSectionHeader(context, 'Local Branches'),
          ...localBranches.map((branch) => _buildBranchItem(
                context,
                branch: branch,
                isCurrent: branch == currentBranch,
              )),
        ],
        if (remoteBranches.isNotEmpty) ...[
          _buildSectionHeader(context, 'Remote Branches'),
          ...remoteBranches.map((branch) => _buildBranchItem(
                context,
                branch: branch,
                isCurrent: false,
              )),
        ],
        if (localBranches.isEmpty && remoteBranches.isEmpty)
          _buildNoResults(),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildBranchItem(
    BuildContext context, {
    required GitBranch branch,
    required bool isCurrent,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(
        isCurrent ? Icons.check_circle : Icons.call_split,
        size: 20,
        color: isCurrent
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      title: Text(
        branch.name.shortName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isCurrent ? FontWeight.bold : null,
            ),
      ),
      subtitle: branch.headCommit.toNullable() != null
          ? Text(
              branch.headCommit.toNullable()!.short,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            )
          : null,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (value) => _handleBranchAction(value, branch),
        itemBuilder: (context) => [
          if (!isCurrent && !branch.isRemote)
            const PopupMenuItem(
              value: 'checkout',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 18),
                  SizedBox(width: 8),
                  Text('Checkout'),
                ],
              ),
            ),
          if (!isCurrent)
            const PopupMenuItem(
              value: 'merge',
              child: Row(
                children: [
                  Icon(Icons.merge, size: 18),
                  SizedBox(width: 8),
                  Text('Merge'),
                ],
              ),
            ),
          if (!branch.name.isMainBranch && !branch.isRemote)
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          const PopupMenuItem(
            value: 'copy',
            child: Row(
              children: [
                Icon(Icons.copy, size: 18),
                SizedBox(width: 8),
                Text('Copy Name'),
              ],
            ),
          ),
        ],
      ),
      onTap: isCurrent || branch.isRemote
          ? null
          : () => _checkoutBranch(branch.name.value),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No branches found',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  List<GitBranch> _filterBranches(List<GitBranch> branches) {
    if (_searchQuery.isEmpty) {
      return branches;
    }

    final query = _searchQuery.toLowerCase();
    return branches
        .where((branch) =>
            branch.name.value.toLowerCase().contains(query) ||
            branch.name.shortName.toLowerCase().contains(query))
        .toList();
  }

  void _handleBranchAction(String action, GitBranch branch) {
    switch (action) {
      case 'checkout':
        _checkoutBranch(branch.name.value);
        break;
      case 'merge':
        _mergeBranch(branch.name.value);
        break;
      case 'delete':
        _deleteBranch(branch.name.value);
        break;
      case 'copy':
        GitUIUtils.copyToClipboard(
          context,
          branch.name.value,
          successMessage: 'Branch name copied',
        );
        break;
    }
  }

  void _checkoutBranch(String branchName) {
    ref.read(gitRepositoryNotifierProvider.notifier).checkoutBranch(branchName);
    Navigator.pop(context);
  }

  void _mergeBranch(String branchName) {
    final gitState = ref.read(gitRepositoryNotifierProvider);
    final currentBranch =
        gitState.repository?.currentBranch?.toNullable()?.name.value ??
            'current branch';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge Branch'),
        content: Text(
          'Merge "$branchName" into "$currentBranch"?\n\n'
          'This will combine the changes from both branches.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Note: Merge operation would be implemented in GitRepositoryNotifier
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Merge not yet implemented for "$branchName"'),
                  action: SnackBarAction(
                    label: 'Dismiss',
                    onPressed: () {},
                  ),
                ),
              );
            },
            icon: const Icon(Icons.merge, size: 18),
            child: const Text('Merge'),
          ),
        ],
      ),
    );
  }

  void _deleteBranch(String branchName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text(
          'Are you sure you want to delete branch "$branchName"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(gitRepositoryNotifierProvider.notifier)
                  .deleteBranch(branchName: branchName);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateBranchDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateBranchDialog(),
    );
  }
}

/// Create branch dialog
class CreateBranchDialog extends ConsumerStatefulWidget {
  const CreateBranchDialog({super.key});

  @override
  ConsumerState<CreateBranchDialog> createState() =>
      _CreateBranchDialogState();
}

class _CreateBranchDialogState extends ConsumerState<CreateBranchDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _checkout = true;
  bool _isCreating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Branch'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Branch Name',
                hintText: 'feature/my-feature',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Branch name is required';
                }
                if (value.contains(' ')) {
                  return 'Branch name cannot contain spaces';
                }
                if (value.contains('..')) {
                  return 'Branch name cannot contain ".."';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Checkout branch'),
              subtitle: const Text('Switch to the new branch after creation'),
              value: _checkout,
              onChanged: (value) {
                setState(() {
                  _checkout = value ?? true;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isCreating ? null : _createBranch,
          icon: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add),
          label: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createBranch() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    await ref.read(gitRepositoryNotifierProvider.notifier).createBranch(
          branchName: _controller.text.trim(),
          checkout: _checkout,
        );

    if (!mounted) return;
    Navigator.pop(context);
  }
}
