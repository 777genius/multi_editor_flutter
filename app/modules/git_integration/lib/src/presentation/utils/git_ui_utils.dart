import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Git UI utility functions
class GitUIUtils {
  GitUIUtils._();

  /// Generate consistent color for author based on name hash
  ///
  /// Uses HSL color space for better color distribution
  /// Keeps same saturation (0.6) and lightness (0.5) for consistency
  static Color getAuthorColor(String author) {
    final hash = author.hashCode;
    final hue = (hash.abs() % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }

  /// Get author initials from name
  ///
  /// Examples:
  /// - "John Doe" -> "JD"
  /// - "Alice" -> "A"
  /// - "Bob Smith Jones" -> "BJ" (first and last)
  static String getAuthorInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();

    // First and last name initials
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Copy text to clipboard with user feedback
  ///
  /// Shows SnackBar on success/failure
  /// Returns true if successful
  static Future<bool> copyToClipboard(
    BuildContext context,
    String text, {
    String successMessage = 'Copied to clipboard',
  }) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      return false;
    }
  }

  /// Get theme-aware addition color
  static Color getAdditionColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF8FD9A8)  // Light green on dark
        : const Color(0xFF0F6D31); // Dark green on light
  }

  /// Get theme-aware deletion color
  static Color getDeletionColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFFFF8A8A)  // Light red on dark
        : const Color(0xFFB71C1C); // Dark red on light
  }

  /// Get theme-aware warning color
  static Color getWarningColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFFFFA726)  // Light orange on dark
        : const Color(0xFFE65100); // Dark orange on light
  }
}

/// Debouncer for expensive operations
///
/// Usage:
/// ```dart
/// final debouncer = Debouncer(milliseconds: 300);
///
/// onChanged: (value) {
///   debouncer.run(() {
///     // Expensive operation here
///     _performSearch(value);
///   });
/// }
/// ```
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}

/// Throttler for scroll and other high-frequency events
///
/// Unlike debouncer, throttler executes immediately and then
/// ignores subsequent calls until cooldown period expires
///
/// Usage:
/// ```dart
/// final throttler = Throttler(milliseconds: 300);
///
/// scrollController.addListener(() {
///   throttler.run(() {
///     // Check if near bottom and load more
///     _loadMore();
///   });
/// });
/// ```
class Throttler {
  final int milliseconds;
  DateTime? _lastExecution;

  Throttler({required this.milliseconds});

  void run(VoidCallback action) {
    final now = DateTime.now();

    if (_lastExecution == null ||
        now.difference(_lastExecution!).inMilliseconds >= milliseconds) {
      _lastExecution = now;
      action();
    }
  }

  void reset() {
    _lastExecution = null;
  }
}
