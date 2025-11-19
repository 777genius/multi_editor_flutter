# Git Blame Inline Viewer Plugin

Shows git blame information for the current line in the editor.

## Features

- **Inline Blame Info**: Displays commit info for the line under cursor
- **Commit Details**: Shows commit hash, author, time, and message
- **Relative Time**: Human-readable timestamps (e.g., "2 hours ago")
- **Integration**: Uses existing `git_integration` module
- **Debounced Updates**: Avoids excessive git operations

## Display Information

For each line, shows:
- **Short Commit Hash**: First 7 characters of commit SHA
- **Author**: Commit author name and email
- **Relative Time**: Human-friendly timestamp
- **Commit Message**: First line of commit message

## UI Integration

Displays blame info in the editor status bar or as an inline annotation:

```
87fe227 • John Doe • 2 hours ago • fix: resolve critical bug
```

## Performance

- **Debounced**: 200ms delay after cursor movement
- **Cached**: Git blame results are cached per file
- **Efficient**: Only fetches blame when cursor line changes

## Usage

```dart
final plugin = GitBlamePlugin();
await pluginManager.registerPlugin(plugin);

// Access current line's blame info
final blameLine = plugin.currentBlameLine;
if (blameLine != null) {
  print('${blameLine.author.name} • ${blameLine.relativeTime}');
}
```

## Requirements

- Git repository must be initialized
- `BlameService` must be available in plugin context
- File must be tracked by Git

## Integration with git_integration

Uses the following services from `git_integration` module:
- `BlameService`: Fetches git blame information
- `BlameLine` entity: Contains commit metadata
- `GitAuthor`: Author information
