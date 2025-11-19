# Bracket Pair Colorizer WASM Plugin

Rainbow bracket colorizer with nesting depth analysis and error detection, implemented in Rust and compiled to WebAssembly for maximum performance.

## Features

- **Rainbow Colors**: Different colors for different nesting levels
- **Bracket Types**: Supports `()`, `{}`, `[]`, `<>`
- **Nesting Depth**: Unlimited nesting with depth tracking
- **Error Detection**: Finds unmatched and mismatched brackets
- **Smart Parsing**: String and comment-aware
- **Language Support**: Generic + language-specific handling (Rust, C++, Java generics)
- **Custom Colors**: Configurable color schemes
- **Performance**: Optimized stack-based O(n) algorithm

## Architecture

Follows **Clean Architecture** principles:

```
Presentation (lib.rs - WASM exports)
    ↓
Application (use_cases.rs - business logic orchestration)
    ↓
Domain (entities.rs, value_objects.rs, services.rs - core business logic)
    ↑
Infrastructure (memory.rs - WASM memory management)
```

### Domain Layer

**Entities:**
- `Bracket`: A single bracket with position, depth, color
- `BracketPair`: Matched opening and closing brackets
- `UnmatchedBracket`: Orphan brackets with error reason
- `BracketCollection`: All brackets and pairs in a document

**Value Objects:**
- `BracketType`: Round, Curly, Square, Angle
- `BracketSide`: Opening, Closing
- `Position`: Line, column, offset
- `ColorLevel`: Depth-based color assignment
- `ColorScheme`: Rainbow or custom colors
- `Language`: Language-specific parsing rules

**Services:**
- `BracketAnalyzer`: Interface for bracket analysis
- `StackBasedMatcher`: Stack-based bracket matching algorithm

### Algorithm

Stack-based bracket matching with O(n) complexity:

1. Scan through source code character by character
2. Push opening brackets onto stack
3. Pop and match closing brackets
4. Track nesting depth for color assignment
5. Detect unmatched and mismatched brackets
6. Skip brackets in strings and comments

### String and Comment Awareness

The parser intelligently skips brackets inside:
- String literals: `"{ not counted }"`, `'{ also not counted }'`
- Single-line comments: `// ( not counted`
- Multi-line comments: `/* { not counted } */`

### Language-Specific Handling

- **Generic Types**: Skips `<>` in Rust, C++, Java, TypeScript, C# (e.g., `Vec<T>`, `HashMap<K, V>`)
- **Python**: Handles significant whitespace
- **Generic**: Works for all languages

## Building

```bash
# Make build script executable
chmod +x build.sh

# Build the WASM plugin
./build.sh
```

Output: `build/bracket_colorizer_wasm.wasm`

## Testing

```bash
cargo test
```

Comprehensive test suite covering:
- Simple bracket matching
- Nested brackets with depth
- Unmatched brackets
- Mismatched brackets
- Brackets in strings
- Brackets in comments
- Color level assignment
- Statistics calculation

## Usage

### From Dart

```dart
// Use through the BracketColorizerPlugin (Dart wrapper)
// See: app/modules/plugins/multi_editor_plugin_bracket_colorizer
```

### Direct WASM API

```javascript
// Initialize
plugin_initialize()

// Analyze brackets
const request = {
  event_type: "analyze_brackets",
  data: {
    request_id: "analyze-1",
    content: "function test() { return [1, 2, 3]; }",
    file_extension: "js",
    color_scheme: {
      colors: ["#FFD700", "#DA70D6", "#179FFF"],
      enabled: true,
      max_depth: 100
    }
  }
}

const response = plugin_handle_event(request)

// Response format:
{
  request_id: "analyze-1",
  success: true,
  data: {
    pairs: [
      {
        opening: {
          bracket_type: "Round",
          position: { line: 0, column: 13, offset: 13 },
          depth: 0,
          color_level: 0
        },
        closing: {
          bracket_type: "Round",
          position: { line: 0, column: 14, offset: 14 },
          depth: 0,
          color_level: 0
        },
        depth: 0,
        is_matched: true
      }
      // ... more pairs
    ],
    unmatched: [],
    max_depth: 2,
    total_brackets: 6,
    analysis_duration_ms: 2,
    statistics: {
      round_pairs: 1,
      curly_pairs: 1,
      square_pairs: 1,
      angle_pairs: 0,
      unmatched_count: 0,
      mismatched_count: 0
    }
  }
}
```

## Color Schemes

### Default Rainbow (6 colors)

```json
{
  "colors": [
    "#FFD700",  // Gold
    "#DA70D6",  // Orchid
    "#179FFF",  // Sky Blue
    "#FF6347",  // Tomato
    "#3CB371",  // Medium Sea Green
    "#FF8C00"   // Dark Orange
  ],
  "enabled": true,
  "max_depth": 100
}
```

### Monochrome

```json
{
  "colors": ["#FFFFFF"],
  "enabled": true,
  "max_depth": 100
}
```

### Custom

```json
{
  "colors": ["#color1", "#color2", "#color3"],
  "enabled": true,
  "max_depth": 50
}
```

Colors cycle based on nesting depth: `color = colors[depth % colors.length]`

## Error Detection

### Unmatched Opening Bracket

```javascript
"{ ( "  // Missing closing brackets
// Error: MissingClosing
```

### Unmatched Closing Bracket

```javascript
"} )"  // No opening brackets
// Error: MissingOpening
```

### Mismatched Brackets

```javascript
"( ]"  // Round opening, square closing
// Error: TypeMismatch { expected: Round, found: Square }
```

## Performance

- **Algorithm**: Stack-based, O(n) time complexity
- **Typical time**: 10-30ms for 10,000 lines
- **Memory**: O(n) for bracket storage
- **Incremental parsing**: Planned for future versions

## Capabilities

```json
{
  "bracket_types": ["()", "{}", "[]", "<>"],
  "max_depth": "unlimited",
  "color_schemes": ["rainbow", "monochrome", "custom"],
  "features": [
    "Nesting depth tracking",
    "Color cycling based on depth",
    "Unmatched bracket detection",
    "Mismatched bracket detection",
    "String literal awareness",
    "Comment awareness",
    "Language-specific handling"
  ],
  "performance": {
    "algorithm": "stack-based O(n)",
    "typical_time_10k_lines_ms": "10-30"
  }
}
```

## Future Enhancements

- [ ] Incremental parsing for better performance on edits
- [ ] Tree-sitter integration for AST-based bracket detection
- [ ] Bracket context (function args, array, object, etc.)
- [ ] Highlight matching pair on cursor
- [ ] Bracket navigation (jump to matching bracket)
- [ ] Custom bracket definitions
- [ ] Bracket scope indicators (vertical lines)
