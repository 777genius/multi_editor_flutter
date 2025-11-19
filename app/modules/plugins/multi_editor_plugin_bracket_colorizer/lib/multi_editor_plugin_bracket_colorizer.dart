/// Bracket Pair Colorizer Plugin
///
/// Rainbow bracket colorizer with nesting depth analysis and error detection.
/// Uses Rust WASM backend for performance.
///
/// Features:
/// - Rainbow colors for different nesting levels
/// - Supports (), {}, [], <>
/// - Unlimited nesting depth
/// - Error detection (unmatched, mismatched)
/// - String and comment awareness
/// - Language-specific handling (generics, etc.)
/// - Customizable color schemes
library multi_editor_plugin_bracket_colorizer;

export 'src/domain/entities/bracket_match.dart';
export 'src/infrastructure/plugin/bracket_colorizer_plugin.dart';
