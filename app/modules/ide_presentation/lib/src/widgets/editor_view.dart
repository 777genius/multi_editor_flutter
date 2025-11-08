import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:get_it/get_it.dart';
import '../stores/editor/editor_store.dart';

/// EditorView
///
/// Main code editor widget that displays and edits text content.
///
/// Architecture (Clean Architecture + MobX):
/// ```
/// EditorView (UI Widget)
///     ↓ observes (@observable)
/// EditorStore (MobX Store)
///     ↓ calls (@action)
/// Use Cases (Application Layer)
///     ↓ uses
/// Repositories (Domain Interfaces)
/// ```
///
/// MobX Best Practices:
/// - Observer: Automatically rebuilds when observables change
/// - Reactions: Side effects in reaction() or autorun()
/// - Computed: Derived state accessed as properties
/// - Actions: Triggered directly on store
///
/// Responsibilities:
/// - Displays editor content reactively
/// - Handles text input and editing
/// - Shows cursor and selection
/// - Displays line numbers
/// - Handles keyboard shortcuts
/// - Observes EditorStore for state changes
///
/// Example:
/// ```dart
/// // Store is provided via GetIt
/// final store = getIt<EditorStore>();
///
/// // In widget tree
/// EditorView()
/// ```
class EditorView extends StatefulWidget {
  final EditorStore? store;

  const EditorView({
    super.key,
    this.store,
  });

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final EditorStore _store;
  late final ReactionDisposer _contentReactionDisposer;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? GetIt.I<EditorStore>();

    // Initial sync
    _controller.text = _store.content;

    // React to store content changes
    // This is the CORRECT way - reaction() instead of modifying in build()
    _contentReactionDisposer = reaction(
      // What to observe
      (_) => _store.content,
      // What to do when it changes
      (String newContent) {
        if (_controller.text != newContent) {
          final cursorOffset = _controller.selection.baseOffset;
          _controller.text = newContent;

          // Restore cursor position if valid
          if (cursorOffset >= 0 && cursorOffset <= newContent.length) {
            _controller.selection = TextSelection.collapsed(offset: cursorOffset);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _contentReactionDisposer();  // Dispose reaction
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        // Pure build - no side effects!
        // Content sync handled by reaction() in initState

        // Render based on store state
        if (!_store.hasDocument) {
          return _buildEmptyState();
        }

        if (_store.isLoading) {
          return _buildLoadingState();
        }

        if (_store.hasError) {
          return _buildErrorState();
        }

        return _buildEditor();
      },
    );
  }

  /// Builds empty state (no document opened)
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No document opened',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Open a file to start editing',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Builds loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading...'),
        ],
      ),
    );
  }

  /// Builds error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _store.errorMessage ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _store.clearError(),
            child: const Text('Clear Error'),
          ),
        ],
      ),
    );
  }

  /// Builds the main editor
  Widget _buildEditor() {
    return Container(
      color: const Color(0xFF1E1E1E), // VS Code dark background
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line numbers
          _buildLineNumbers(),

          // Editor content
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: (text) {
                // Update store content directly (TextField is source of truth for UI)
                // Don't call insertText as it would insert entire text at cursor position
                _store.updateContentFromUI(text);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds line numbers column
  Widget _buildLineNumbers() {
    return Observer(
      builder: (_) {
        final lineCount = _store.lineCount;

        return Container(
          width: 60,
          color: const Color(0xFF252525), // Slightly lighter than editor
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              lineCount,
              (index) {
                final isCurrentLine = index == _store.cursorPosition.line;

                return Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: isCurrentLine
                        ? const Color(0xFFC6C6C6) // Highlighted line number
                        : const Color(0xFF858585), // Normal line number
                    fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                    height: 1.5,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
