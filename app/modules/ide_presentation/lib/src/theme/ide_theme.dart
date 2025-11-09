import 'package:flutter/material.dart';

/// IDE Theme System
///
/// Comprehensive theme system for the IDE:
/// - Dark theme (VS Code dark)
/// - Light theme (VS Code light)
/// - High contrast themes
/// - Custom color schemes
/// - Syntax highlighting colors
/// - UI element colors
///
/// Architecture:
/// - Centralized theme management
/// - Type-safe color access
/// - Theme persistence
/// - Hot reload support
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: IdeTheme.dark,
///   themeMode: ThemeMode.dark,
/// )
/// ```
class IdeTheme {
  // ================================================================
  // Theme Definitions
  // ================================================================

  /// VS Code Dark Theme
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF007ACC),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF007ACC),
          secondary: Color(0xFF0E639C),
          surface: Color(0xFF252526),
          background: Color(0xFF1E1E1E),
          error: Color(0xFFF48771),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onError: Colors.white,
        ),
        cardColor: const Color(0xFF252526),
        dividerColor: const Color(0xFF3E3E42),
        textTheme: _buildTextTheme(Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2D2D30),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        extensions: [
          IdeColors.dark,
          SyntaxColors.dark,
        ],
      );

  /// VS Code Light Theme
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF005FB8),
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF005FB8),
          secondary: Color(0xFF0078D4),
          surface: Color(0xFFF3F3F3),
          background: Color(0xFFFFFFFF),
          error: Color(0xFFE81123),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
          onBackground: Colors.black,
          onError: Colors.white,
        ),
        cardColor: const Color(0xFFF3F3F3),
        dividerColor: const Color(0xFFE5E5E5),
        textTheme: _buildTextTheme(Colors.black),
        iconTheme: const IconThemeData(color: Colors.black),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF3F3F3),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        extensions: [
          IdeColors.light,
          SyntaxColors.light,
        ],
      );

  /// High Contrast Dark Theme
  static ThemeData get highContrastDark => ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00FFFF),
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFFF),
          secondary: Color(0xFF00FF00),
          surface: Color(0xFF000000),
          background: Color(0xFF000000),
          error: Color(0xFFFF0000),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onError: Colors.white,
        ),
        cardColor: const Color(0xFF000000),
        dividerColor: const Color(0xFFFFFFFF),
        textTheme: _buildTextTheme(Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        extensions: [
          IdeColors.highContrastDark,
          SyntaxColors.highContrastDark,
        ],
      );

  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 14,
        color: baseColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        color: baseColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: baseColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        color: baseColor,
      ),
    );
  }
}

/// IDE-specific colors (beyond standard Material colors)
class IdeColors extends ThemeExtension<IdeColors> {
  final Color editorBackground;
  final Color editorForeground;
  final Color sidebarBackground;
  final Color sidebarForeground;
  final Color statusBarBackground;
  final Color statusBarForeground;
  final Color panelBackground;
  final Color panelBorder;
  final Color inputBackground;
  final Color inputBorder;
  final Color selectionBackground;
  final Color lineHighlight;
  final Color cursorColor;
  final Color matchHighlight;

  const IdeColors({
    required this.editorBackground,
    required this.editorForeground,
    required this.sidebarBackground,
    required this.sidebarForeground,
    required this.statusBarBackground,
    required this.statusBarForeground,
    required this.panelBackground,
    required this.panelBorder,
    required this.inputBackground,
    required this.inputBorder,
    required this.selectionBackground,
    required this.lineHighlight,
    required this.cursorColor,
    required this.matchHighlight,
  });

  static const dark = IdeColors(
    editorBackground: Color(0xFF1E1E1E),
    editorForeground: Color(0xFFD4D4D4),
    sidebarBackground: Color(0xFF252526),
    sidebarForeground: Color(0xFFCCCCCC),
    statusBarBackground: Color(0xFF007ACC),
    statusBarForeground: Colors.white,
    panelBackground: Color(0xFF252526),
    panelBorder: Color(0xFF3E3E42),
    inputBackground: Color(0xFF3C3C3C),
    inputBorder: Color(0xFF3E3E42),
    selectionBackground: Color(0xFF264F78),
    lineHighlight: Color(0xFF2A2D2E),
    cursorColor: Color(0xFFAEAFAD),
    matchHighlight: Color(0xFF515C6A),
  );

  static const light = IdeColors(
    editorBackground: Color(0xFFFFFFFF),
    editorForeground: Color(0xFF000000),
    sidebarBackground: Color(0xFFF3F3F3),
    sidebarForeground: Color(0xFF424242),
    statusBarBackground: Color(0xFF007ACC),
    statusBarForeground: Colors.white,
    panelBackground: Color(0xFFF3F3F3),
    panelBorder: Color(0xFFE5E5E5),
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFCECECE),
    selectionBackground: Color(0xFFADD6FF),
    lineHighlight: Color(0xFFF5F5F5),
    cursorColor: Color(0xFF000000),
    matchHighlight: Color(0xFFEA5C00),
  );

  static const highContrastDark = IdeColors(
    editorBackground: Color(0xFF000000),
    editorForeground: Color(0xFFFFFFFF),
    sidebarBackground: Color(0xFF000000),
    sidebarForeground: Color(0xFFFFFFFF),
    statusBarBackground: Color(0xFF000000),
    statusBarForeground: Color(0xFF00FFFF),
    panelBackground: Color(0xFF000000),
    panelBorder: Color(0xFFFFFFFF),
    inputBackground: Color(0xFF000000),
    inputBorder: Color(0xFFFFFFFF),
    selectionBackground: Color(0xFF00FF00),
    lineHighlight: Color(0xFF1A1A1A),
    cursorColor: Color(0xFF00FFFF),
    matchHighlight: Color(0xFFFFFF00),
  );

  @override
  IdeColors copyWith({
    Color? editorBackground,
    Color? editorForeground,
    Color? sidebarBackground,
    Color? sidebarForeground,
    Color? statusBarBackground,
    Color? statusBarForeground,
    Color? panelBackground,
    Color? panelBorder,
    Color? inputBackground,
    Color? inputBorder,
    Color? selectionBackground,
    Color? lineHighlight,
    Color? cursorColor,
    Color? matchHighlight,
  }) {
    return IdeColors(
      editorBackground: editorBackground ?? this.editorBackground,
      editorForeground: editorForeground ?? this.editorForeground,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarForeground: sidebarForeground ?? this.sidebarForeground,
      statusBarBackground: statusBarBackground ?? this.statusBarBackground,
      statusBarForeground: statusBarForeground ?? this.statusBarForeground,
      panelBackground: panelBackground ?? this.panelBackground,
      panelBorder: panelBorder ?? this.panelBorder,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      selectionBackground: selectionBackground ?? this.selectionBackground,
      lineHighlight: lineHighlight ?? this.lineHighlight,
      cursorColor: cursorColor ?? this.cursorColor,
      matchHighlight: matchHighlight ?? this.matchHighlight,
    );
  }

  @override
  IdeColors lerp(ThemeExtension<IdeColors>? other, double t) {
    if (other is! IdeColors) return this;

    return IdeColors(
      editorBackground: Color.lerp(editorBackground, other.editorBackground, t)!,
      editorForeground: Color.lerp(editorForeground, other.editorForeground, t)!,
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      sidebarForeground: Color.lerp(sidebarForeground, other.sidebarForeground, t)!,
      statusBarBackground: Color.lerp(statusBarBackground, other.statusBarBackground, t)!,
      statusBarForeground: Color.lerp(statusBarForeground, other.statusBarForeground, t)!,
      panelBackground: Color.lerp(panelBackground, other.panelBackground, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      selectionBackground: Color.lerp(selectionBackground, other.selectionBackground, t)!,
      lineHighlight: Color.lerp(lineHighlight, other.lineHighlight, t)!,
      cursorColor: Color.lerp(cursorColor, other.cursorColor, t)!,
      matchHighlight: Color.lerp(matchHighlight, other.matchHighlight, t)!,
    );
  }

  /// Get IdeColors from context
  static IdeColors of(BuildContext context) {
    return Theme.of(context).extension<IdeColors>() ?? IdeColors.dark;
  }
}

/// Syntax highlighting colors
class SyntaxColors extends ThemeExtension<SyntaxColors> {
  final Color keyword;
  final Color string;
  final Color number;
  final Color comment;
  final Color function;
  final Color className;
  final Color variable;
  final Color type;
  final Color operator;
  final Color constant;
  final Color decorator;
  final Color error;
  final Color warning;

  const SyntaxColors({
    required this.keyword,
    required this.string,
    required this.number,
    required this.comment,
    required this.function,
    required this.className,
    required this.variable,
    required this.type,
    required this.operator,
    required this.constant,
    required this.decorator,
    required this.error,
    required this.warning,
  });

  static const dark = SyntaxColors(
    keyword: Color(0xFFC586C0),
    string: Color(0xFFCE9178),
    number: Color(0xFFB5CEA8),
    comment: Color(0xFF6A9955),
    function: Color(0xFFDCDCAA),
    className: Color(0xFF4EC9B0),
    variable: Color(0xFF9CDCFE),
    type: Color(0xFF4EC9B0),
    operator: Color(0xFFD4D4D4),
    constant: Color(0xFF4FC1FF),
    decorator: Color(0xFFFFD700),
    error: Color(0xFFF48771),
    warning: Color(0xFFCCA700),
  );

  static const light = SyntaxColors(
    keyword: Color(0xFF0000FF),
    string: Color(0xFFA31515),
    number: Color(0xFF098658),
    comment: Color(0xFF008000),
    function: Color(0xFF795E26),
    className: Color(0xFF267F99),
    variable: Color(0xFF001080),
    type: Color(0xFF267F99),
    operator: Color(0xFF000000),
    constant: Color(0xFF0070C1),
    decorator: Color(0xFFAF00DB),
    error: Color(0xFFE81123),
    warning: Color(0xFFBF8803),
  );

  static const highContrastDark = SyntaxColors(
    keyword: Color(0xFFFF00FF),
    string: Color(0xFF00FF00),
    number: Color(0xFF00FFFF),
    comment: Color(0xFF7F7F7F),
    function: Color(0xFFFFFF00),
    className: Color(0xFF00FFFF),
    variable: Color(0xFFFFFFFF),
    type: Color(0xFF00FFFF),
    operator: Color(0xFFFFFFFF),
    constant: Color(0xFF00FFFF),
    decorator: Color(0xFFFFFF00),
    error: Color(0xFFFF0000),
    warning: Color(0xFFFFFF00),
  );

  @override
  SyntaxColors copyWith({
    Color? keyword,
    Color? string,
    Color? number,
    Color? comment,
    Color? function,
    Color? className,
    Color? variable,
    Color? type,
    Color? operator,
    Color? constant,
    Color? decorator,
    Color? error,
    Color? warning,
  }) {
    return SyntaxColors(
      keyword: keyword ?? this.keyword,
      string: string ?? this.string,
      number: number ?? this.number,
      comment: comment ?? this.comment,
      function: function ?? this.function,
      className: className ?? this.className,
      variable: variable ?? this.variable,
      type: type ?? this.type,
      operator: operator ?? this.operator,
      constant: constant ?? this.constant,
      decorator: decorator ?? this.decorator,
      error: error ?? this.error,
      warning: warning ?? this.warning,
    );
  }

  @override
  SyntaxColors lerp(ThemeExtension<SyntaxColors>? other, double t) {
    if (other is! SyntaxColors) return this;

    return SyntaxColors(
      keyword: Color.lerp(keyword, other.keyword, t)!,
      string: Color.lerp(string, other.string, t)!,
      number: Color.lerp(number, other.number, t)!,
      comment: Color.lerp(comment, other.comment, t)!,
      function: Color.lerp(function, other.function, t)!,
      className: Color.lerp(className, other.className, t)!,
      variable: Color.lerp(variable, other.variable, t)!,
      type: Color.lerp(type, other.type, t)!,
      operator: Color.lerp(operator, other.operator, t)!,
      constant: Color.lerp(constant, other.constant, t)!,
      decorator: Color.lerp(decorator, other.decorator, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }

  /// Get SyntaxColors from context
  static SyntaxColors of(BuildContext context) {
    return Theme.of(context).extension<SyntaxColors>() ?? SyntaxColors.dark;
  }
}

/// Theme Mode Manager
class ThemeModeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
