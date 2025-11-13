import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/git_commit.dart';
import '../providers/git_state_provider.dart';
import '../utils/git_ui_utils.dart';

/// Commit history viewer widget
///
/// Shows commit history with:
/// - Commit graph visualization
/// - Commit details (author, date, message)
/// - Pagination for large histories
/// - Filtering and search
class CommitHistoryViewer extends ConsumerStatefulWidget {
  const CommitHistoryViewer({super.key});

  @override
  ConsumerState<CommitHistoryViewer> createState() =>
      _CommitHistoryViewerState();
}

class _CommitHistoryViewerState extends ConsumerState<CommitHistoryViewer> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchDebouncer = Debouncer(milliseconds: 300);
  final _scrollThrottler = Throttler(milliseconds: 200);
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _loadHistory() {
    ref.read(commitHistoryNotifierProvider.notifier).load();
  }

  void _onScroll() {
    // Throttle scroll listener to prevent excessive calls
    _scrollThrottler.run(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        // Load more when near bottom (90%)
        ref.read(commitHistoryNotifierProvider.notifier).loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(commitHistoryNotifierProvider);

    return Column(
      children: [
        _buildToolbar(context),
        const Divider(height: 1),
        _buildSearchBar(),
        Expanded(
          child: historyAsync.when(
            data: (commits) => _buildCommitList(context, commits),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(error.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Commit History',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search commits...',
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
    );
  }

  Widget _buildCommitList(BuildContext context, List<GitCommit> commits) {
    final filteredCommits = _filterCommits(commits);

    if (filteredCommits.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredCommits.length,
      itemBuilder: (context, index) {
        final commit = filteredCommits[index];
        final isFirst = index == 0;
        final isLast = index == filteredCommits.length - 1;

        return _buildCommitItem(
          context,
          commit: commit,
          showTopLine: !isFirst,
          showBottomLine: !isLast,
        );
      },
    );
  }

  Widget _buildCommitItem(
    BuildContext context, {
    required GitCommit commit,
    required bool showTopLine,
    required bool showBottomLine,
  }) {
    return InkWell(
      onTap: () => _showCommitDetails(commit),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCommitGraph(
              context,
              showTopLine: showTopLine,
              showBottomLine: showBottomLine,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCommitHeader(context, commit),
                  const SizedBox(height: 4),
                  Text(
                    commit.message.subject,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildCommitMeta(context, commit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitGraph(
    BuildContext context, {
    required bool showTopLine,
    required bool showBottomLine,
  }) {
    return SizedBox(
      width: 24,
      child: Column(
        children: [
          if (showTopLine)
            Container(
              width: 2,
              height: 16,
              color: Theme.of(context).colorScheme.outline,
            ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimary,
                width: 2,
              ),
            ),
          ),
          if (showBottomLine)
            Expanded(
              child: Container(
                width: 2,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommitHeader(BuildContext context, GitCommit commit) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: GitUIUtils.getAuthorColor(commit.author.name),
          child: Text(
            GitUIUtils.getAuthorInitials(commit.author.name),
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            commit.author.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            commit.hash.short,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommitMeta(BuildContext context, GitCommit commit) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 12,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          commit.ageDisplay,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        if (commit.tags.isNotEmpty) ...[
          const SizedBox(width: 8),
          ...commit.tags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Chip(
                  label: Text(tag),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 6),
                  side: BorderSide.none,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
              )),
        ],
        if (commit.isMergeCommit) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.merge,
            size: 14,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No commits found' : 'No commits',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load history',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  List<GitCommit> _filterCommits(List<GitCommit> commits) {
    if (_searchQuery.isEmpty) {
      return commits;
    }

    final query = _searchQuery.toLowerCase();
    return commits
        .where((commit) =>
            commit.message.value.toLowerCase().contains(query) ||
            commit.author.name.toLowerCase().contains(query) ||
            commit.hash.value.toLowerCase().contains(query))
        .toList();
  }


  void _showCommitDetails(GitCommit commit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return CommitDetailsView(
            commit: commit,
            scrollController: scrollController,
          );
        },
      ),
    );
  }
}

/// Commit details view
class CommitDetailsView extends StatelessWidget {
  final GitCommit commit;
  final ScrollController scrollController;

  const CommitDetailsView({
    super.key,
    required this.commit,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          _buildHandle(context),
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard(
                  context,
                  title: 'Commit',
                  icon: Icons.commit,
                  children: [
                    _buildInfoRow(
                      context,
                      label: 'Hash',
                      value: commit.hash.value,
                      copyable: true,
                    ),
                    if (commit.parentHash.toNullable() != null)
                      _buildInfoRow(
                        context,
                        label: 'Parent',
                        value: commit.parentHash.toNullable()!.value,
                        copyable: true,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  title: 'Author',
                  icon: Icons.person,
                  children: [
                    _buildInfoRow(
                      context,
                      label: 'Name',
                      value: commit.author.name,
                    ),
                    _buildInfoRow(
                      context,
                      label: 'Email',
                      value: commit.author.email,
                    ),
                    _buildInfoRow(
                      context,
                      label: 'Date',
                      value: dateFormat.format(commit.authorDate),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  context,
                  title: 'Message',
                  icon: Icons.message,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        commit.message.value,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (commit.changedFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    title: 'Changed Files (${commit.changedFiles.length})',
                    icon: Icons.insert_drive_file,
                    children: commit.changedFiles
                        .map((file) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.edit, size: 16),
                              title: Text(
                                file,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ))
                        .toList(),
                  ),
                ],
                if (commit.totalChanges > 0) ...[
                  const SizedBox(height: 16),
                  _buildStatsCard(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: GitUIUtils.getAuthorColor(commit.author.name),
            child: Text(
              GitUIUtils.getAuthorInitials(commit.author.name),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commit.message.subject,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${commit.author.name} • ${commit.ageDisplay}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: copyable ? 'monospace' : null,
                  ),
            ),
          ),
          if (copyable)
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () => GitUIUtils.copyToClipboard(context, value),
              visualDensity: VisualDensity.compact,
              tooltip: 'Copy',
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat(
              context,
              icon: Icons.add,
              count: commit.insertions,
              label: 'Additions',
              color: GitUIUtils.getAdditionColor(context),
            ),
            _buildStat(
              context,
              icon: Icons.remove,
              count: commit.deletions,
              label: 'Deletions',
              color: GitUIUtils.getDeletionColor(context),
            ),
            _buildStat(
              context,
              icon: Icons.timeline,
              count: commit.totalChanges,
              label: 'Changes',
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

}
