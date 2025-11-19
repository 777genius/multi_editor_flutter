# Advanced Find & Replace Plugin

Advanced find and replace functionality with regex support, multi-file capabilities, and live preview.

## Features

- **Regex Support**: Full regular expression search and replace
- **Case Sensitivity**: Toggle case-sensitive matching
- **Whole Word**: Match whole words only
- **Multi-file Search**: Search across multiple files (planned)
- **Replace Preview**: See changes before applying
- **Search History**: Remembers last 20 searches
- **Capture Groups**: Supports regex capture groups in replacements

## Search Options

- **Literal Search**: Simple text matching
- **Regex Search**: Full regex pattern support
- **Case Sensitive**: Match case exactly
- **Whole Word**: Match complete words only

## Replace Features

- **Preview Mode**: See all replacements before applying
- **Selective Replace**: Apply replacements individually
- **Bulk Replace**: Apply all replacements at once
- **Diff View**: Shows before/after comparison

## Usage Examples

### Simple Find & Replace

```dart
final plugin = FindReplacePlugin();
await pluginManager.registerPlugin(plugin);

// Start search
await plugin.startSearch(
  query: 'oldText',
  caseSensitive: false,
);

// Start replace
plugin.startReplace(replaceText: 'newText');

// Apply all replacements
await plugin.applyAllReplacements();
```

### Regex Find & Replace

```dart
// Find: (\w+)@example\.com
// Replace: $1@newdomain.com

await plugin.startSearch(
  query: r'(\w+)@example\.com',
  isRegex: true,
);

plugin.startReplace(replaceText: r'$1@newdomain.com');
```

### Whole Word Matching

```dart
// Find "test" as a whole word (won't match "testing")
await plugin.startSearch(
  query: 'test',
  wholeWord: true,
);
```

## Search History

The plugin remembers your last 20 search queries and persists them across sessions.

```dart
// Access search history
final history = plugin.searchHistory;
print('Recent searches: $history');
```

## Navigation

- **Next Match**: `plugin.nextMatch()`
- **Previous Match**: `plugin.previousMatch()`
- **Clear Search**: `plugin.clearSearch()`

## UI Integration

Shows search results in sidebar panel with:
- Total match count
- Current match position
- Replace preview statistics
- Applied vs pending replacements

## Performance

- **Debounced Search**: Avoids excessive operations
- **Incremental Results**: Updates as matches are found
- **Configurable**: Search history size configurable

## Architecture

- **Domain**: `SearchSession`, `ReplaceSession`, `SearchMatch`, `ReplacePreview`
- **Infrastructure**: Regex-based search with planned `global_search` integration
- **State Management**: Uses `StatefulPlugin` and `ConfigurablePlugin` mixins

## Future Enhancements

- [ ] Integration with `global_search` WASM module
- [ ] Multi-file search and replace
- [ ] Search in specific folders
- [ ] File pattern filtering
- [ ] Search results export
