import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/value_objects/git_author.dart';
import '../providers/git_state_provider.dart';

/// Commit dialog
///
/// Dialog for creating git commits with:
/// - Commit message input (subject + body)
/// - Author information
/// - Amend option
/// - Conventional commit templates
class CommitDialog extends ConsumerStatefulWidget {
  final bool amend;

  const CommitDialog({
    super.key,
    this.amend = false,
  });

  @override
  ConsumerState<CommitDialog> createState() => _CommitDialogState();
}

class _CommitDialogState extends ConsumerState<CommitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _authorNameController = TextEditingController();
  final _authorEmailController = TextEditingController();

  bool _isCommitting = false;
  bool _useConventionalCommit = false;
  String _commitType = 'feat';

  final _conventionalCommitTypes = const {
    'feat': 'New feature',
    'fix': 'Bug fix',
    'docs': 'Documentation',
    'style': 'Code style',
    'refactor': 'Refactoring',
    'perf': 'Performance',
    'test': 'Tests',
    'chore': 'Maintenance',
    'build': 'Build system',
    'ci': 'CI/CD',
  };

  @override
  void initState() {
    super.initState();
    _loadAuthorInfo();

    if (widget.amend) {
      _loadLastCommitMessage();
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    _authorNameController.dispose();
    _authorEmailController.dispose();
    super.dispose();
  }

  void _loadAuthorInfo() {
    // TODO: Load from git config or stored preferences
    _authorNameController.text = 'Developer';
    _authorEmailController.text = 'dev@example.com';
  }

  void _loadLastCommitMessage() {
    // TODO: Load last commit message if amending
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.amend ? 'Amend Commit' : 'Create Commit'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConventionalCommitToggle(),
                const SizedBox(height: 16),
                if (_useConventionalCommit) ...[
                  _buildCommitTypeSelector(),
                  const SizedBox(height: 16),
                ],
                _buildSubjectField(),
                const SizedBox(height: 16),
                _buildBodyField(),
                const SizedBox(height: 16),
                _buildAuthorFields(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCommitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isCommitting ? null : _commit,
          icon: _isCommitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(widget.amend ? 'Amend' : 'Commit'),
        ),
      ],
    );
  }

  Widget _buildConventionalCommitToggle() {
    return CheckboxListTile(
      title: const Text('Use Conventional Commit'),
      subtitle: const Text('Format: type(scope): subject'),
      value: _useConventionalCommit,
      onChanged: (value) {
        setState(() {
          _useConventionalCommit = value ?? false;
        });
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildCommitTypeSelector() {
    return DropdownButtonFormField<String>(
      value: _commitType,
      decoration: const InputDecoration(
        labelText: 'Commit Type',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: _conventionalCommitTypes.entries
          .map((entry) => DropdownMenuItem(
                value: entry.key,
                child: Row(
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.value,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _commitType = value;
          });
        }
      },
    );
  }

  Widget _buildSubjectField() {
    return TextFormField(
      controller: _subjectController,
      decoration: InputDecoration(
        labelText: 'Commit Message',
        hintText: _useConventionalCommit
            ? 'e.g., add user authentication'
            : 'Brief summary of changes',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.message),
        counterText: '${_subjectController.text.length}/50',
      ),
      maxLength: 50,
      maxLines: 1,
      autofocus: true,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Commit message is required';
        }
        if (value.trim().length < 3) {
          return 'Commit message is too short';
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildBodyField() {
    return TextFormField(
      controller: _bodyController,
      decoration: const InputDecoration(
        labelText: 'Description (optional)',
        hintText: 'Detailed explanation of changes',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
      maxLength: 500,
    );
  }

  Widget _buildAuthorFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Author',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _authorNameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _authorEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _commit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCommitting = true;
    });

    // Build commit message
    String message = _subjectController.text.trim();
    if (_useConventionalCommit) {
      message = '$_commitType: $message';
    }

    if (_bodyController.text.trim().isNotEmpty) {
      message += '\n\n${_bodyController.text.trim()}';
    }

    // Create author
    final author = GitAuthor.create(
      name: _authorNameController.text.trim(),
      email: _authorEmailController.text.trim(),
    );

    // Perform commit
    final commit =
        await ref.read(gitRepositoryNotifierProvider.notifier).commit(
              message: message,
              author: author,
              amend: widget.amend,
            );

    if (!mounted) return;

    setState(() {
      _isCommitting = false;
    });

    if (commit != null) {
      Navigator.pop(context, commit);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.amend
                ? 'Commit amended: ${commit.hash.short}'
                : 'Commit created: ${commit.hash.short}',
          ),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              // TODO: Show commit details
            },
          ),
        ),
      );
    } else {
      // Show error from state
      final error = ref.read(gitRepositoryNotifierProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to commit: ${error.userMessage}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Quick commit dialog (minimal UI)
class QuickCommitDialog extends ConsumerStatefulWidget {
  const QuickCommitDialog({super.key});

  @override
  ConsumerState<QuickCommitDialog> createState() => _QuickCommitDialogState();
}

class _QuickCommitDialogState extends ConsumerState<QuickCommitDialog> {
  final _controller = TextEditingController();
  bool _isCommitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick Commit'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Commit message',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: _isCommitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isCommitting || _controller.text.trim().isEmpty
              ? null
              : _commit,
          child: _isCommitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Commit'),
        ),
      ],
    );
  }

  Future<void> _commit() async {
    setState(() {
      _isCommitting = true;
    });

    final author = GitAuthor.create(
      name: 'Developer', // TODO: Load from config
      email: 'dev@example.com',
    );

    final commit =
        await ref.read(gitRepositoryNotifierProvider.notifier).commit(
              message: _controller.text.trim(),
              author: author,
            );

    if (!mounted) return;

    Navigator.pop(context, commit);
  }
}
