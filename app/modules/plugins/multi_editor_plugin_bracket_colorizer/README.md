# Bracket Pair Colorizer Plugin

Rainbow bracket colorizer with nesting depth analysis, error detection, and Rust WASM backend for performance.

## Features

- **Rainbow Colors**: Different colors for different nesting levels
- **Bracket Types**: Supports `()`, `{}`, `[]`, `<>`
- **Unlimited Nesting**: No depth limit
- **Error Detection**: Finds unmatched and mismatched brackets
- **Smart Parsing**: String and comment-aware
- **Language Support**: Generic + language-specific handling
- **Custom Colors**: Configurable color schemes
- **Real-time**: Updates as you type (debounced)
- **Performance**: Optimized stack-based algorithm

## How It Works

### Stack-Based Algorithm

The plugin uses a classic stack-based bracket matching algorithm:

1. **Scan** through source code character by character
2. **Push** opening brackets `(`, `{`, `[`, `<` onto stack
3. **Pop** and match closing brackets `)`, `}`, `]`, `>`
4. **Track** nesting depth for color assignment
5. **Detect** unmatched and mismatched brackets
6. **Skip** brackets inside strings and comments

### Color Assignment

Colors are assigned based on nesting depth:

```dart
// Depth 0 (Gold)
{
  // Depth 1 (Orchid)
  [
    // Depth 2 (Sky Blue)
    (
      // Depth 3 (Tomato)
    )
  ]
}
```

Colors cycle when depth exceeds color count: `color = colors[depth % colors.length]`

## Color Schemes

### Default Rainbow (6 colors)

```dart
ColorScheme.rainbow()
// Gold, Orchid, Sky Blue, Tomato, Medium Sea Green, Dark Orange
```

### Monochrome

```dart
ColorScheme.monochrome('#FFFFFF')
// Single color
```

### Custom

```dart
ColorScheme(
  colors: ['#FF0000', '#00FF00', '#0000FF'],
  enabled: true,
  maxDepth: 100,
)
```

## Usage

```dart
final plugin = BracketColorizerPlugin();
await pluginManager.registerPlugin(plugin);

// Get current file's bracket analysis
final brackets = plugin.currentBrackets;
if (brackets != null) {
  print('Found ${brackets.statistics.totalPairs} bracket pairs');
  print('Max depth: ${brackets.maxDepth}');
  print('Errors: ${brackets.unmatched.length}');
}

// Change color scheme
await plugin.setColorScheme(ColorScheme(
  colors: ['#FF6B6B', '#4ECDC4', '#45B7D1'],
));
```

## Error Detection

### Unmatched Opening Bracket

```dart
function test() {
  // Missing closing }
```

**Error**: `MissingClosing` on `{` at line 0

### Unmatched Closing Bracket

```dart
}  // No opening bracket
```

**Error**: `MissingOpening` on `}` at line 0

### Mismatched Brackets

```dart
(  // Round opening
]  // Square closing - mismatch!
```

**Error**: `TypeMismatch` on both brackets

## String and Comment Awareness

Brackets inside strings and comments are ignored:

```dart
// Ignored: { not counted
let s = "{ also not counted }";
{ counted }  // ✓ This one is counted
```

Supports:
- Double quote strings: `"..."`
- Single quote strings: `'...'`
- Single-line comments: `// ...`
- Multi-line comments: `/* ... */`

## Statistics

```dart
final stats = brackets.statistics;

print('Round brackets (): ${stats.roundPairs}');
print('Curly brackets {}: ${stats.curlyPairs}');
print('Square brackets []: ${stats.squarePairs}');
print('Angle brackets <>: ${stats.anglePairs}');
print('Total pairs: ${stats.totalPairs}');
print('Unmatched: ${stats.unmatchedCount}');
print('Mismatched: ${stats.mismatchedCount}');
```

## UI Integration

Shows bracket information in sidebar panel:

```
Brackets: 15 pairs
Max depth: 4 • ✓ All matched

() Round: 6
{} Curly: 5
[] Square: 4
<> Angle: 0
```

If there are errors:

```
⚠️ Errors: 3
Mismatched: 1
```

## Architecture

- **Domain**: `BracketMatch`, `BracketPair`, `BracketCollection` entities
- **Infrastructure**: Hybrid analyzer (Dart + WASM backend)
- **WASM Backend**: `/packages/wasm_plugins/bracket_colorizer_wasm/`

## Performance

- **Algorithm**: Stack-based, O(n) time complexity
- **Small files**: ~5-10ms (Dart)
- **Large files**: ~10-30ms (WASM - planned)
- **Debouncing**: 200ms delay after typing

## Configuration

Color scheme is persisted across sessions:

```dart
// Plugin automatically saves/loads color scheme
await plugin.setColorScheme(ColorScheme.rainbow());
// Saved to SharedPreferences
```

## Future Enhancements

- [ ] WASM backend integration for large files
- [ ] Incremental parsing for better performance
- [ ] Highlight matching pair on cursor
- [ ] Bracket navigation (jump to matching bracket)
- [ ] Bracket scope indicators (vertical lines)
- [ ] Custom bracket definitions
- [ ] Bracket context (function args, array, object)
- [ ] Animation on bracket match/mismatch

## Examples

### Simple Code

```dart
function test() {
  return [1, 2, 3];
}
```

**Result**:
- 2 bracket pairs: `()` and `{}`
- 1 square pair: `[]`
- Max depth: 2
- All matched ✓

### Nested Code

```dart
class Foo {
  void bar() {
    if (x > 0) {
      print([1, 2, 3]);
    }
  }
}
```

**Result**:
- 5 curly pairs
- 2 round pairs
- 1 square pair
- Max depth: 4
- All matched ✓

### Error Example

```dart
function broken() {
  let x = (1 + 2];  // Mismatch!
  // Missing closing }
```

**Result**:
- 2 errors: TypeMismatch on `(` and `]`, MissingClosing on `{`
