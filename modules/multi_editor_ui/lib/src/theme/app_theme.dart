/// Professional theme system for the code editor application.
///
/// This module provides a complete, scalable theme solution following
/// Flutter best practices 2025 and Material Design 3 principles.
///
/// ## Features:
/// - Design token system (primitive, semantic, component)
/// - ColorScheme.fromSeed() for harmonious colors
/// - Spacing, radius, elevation, typography systems
/// - Accessibility utilities (WCAG compliance)
/// - Type-safe language colors
/// - Interaction states (hover, pressed, focused)
/// - Zero magic numbers
/// - Zero code duplication
///
/// ## Usage:
/// ```dart
/// import 'package:multi_editor_ui/multi_editor_ui.dart';
///
/// MaterialApp(
///   theme: AppThemeData.light(),
///   darkTheme: AppThemeData.dark(),
///   themeMode: ThemeMode.system,
/// );
///
/// // In widgets:
/// final spacing = AppSpacing.m;
/// final radius = AppRadius.m;
/// final editorTheme = context.editorTheme;
/// final isDark = context.isDarkMode;
/// ```
///
/// ## Architecture:
/// ```
/// Primitive Tokens (raw values)
///       ↓
/// Semantic Tokens (meaning)
///       ↓
/// Component Tokens (usage)
///       ↓
/// Theme Data
/// ```
library;

// Core theme
export 'app_theme_data.dart';
export 'editor_theme_extension.dart';

// Design tokens - Primitives
export 'tokens/primitive/color_primitives.dart';
export 'tokens/primitive/size_primitives.dart';
export 'tokens/primitive/font_primitives.dart';

// Design tokens - Semantic
export 'tokens/semantic/color_semantic.dart';

// Systems
export 'systems/app_spacing.dart';
export 'systems/app_radius.dart';
export 'systems/app_elevation.dart';
export 'systems/app_typography.dart';
export 'systems/app_icon_size.dart';
export 'systems/app_duration.dart';
export 'systems/interaction_states.dart';

// Colors
export 'colors/language_colors.dart';

// Utilities
export 'utils/accessibility.dart';
export 'extensions/theme_extensions.dart';
