import 'package:flutter/foundation.dart';
import 'plugin_error.dart';

/// Service for tracking and managing plugin errors
class ErrorTracker extends ChangeNotifier {
  final List<PluginError> _errors = [];
  final int maxErrors;

  ErrorTracker({this.maxErrors = 100});

  /// Get all tracked errors
  List<PluginError> get errors => List.unmodifiable(_errors);

  /// Get errors for a specific plugin
  List<PluginError> getErrorsForPlugin(String pluginId) {
    return _errors.where((error) => error.pluginId == pluginId).toList();
  }

  /// Get recent errors (most recent first)
  List<PluginError> getRecentErrors({int limit = 10}) {
    final sorted = List<PluginError>.from(_errors)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  /// Get errors by type
  List<PluginError> getErrorsByType(PluginErrorType type) {
    return _errors.where((error) => error.type == type).toList();
  }

  /// Get error statistics (count by plugin ID)
  Map<String, int> getErrorStatistics() {
    final stats = <String, int>{};
    for (final error in _errors) {
      stats[error.pluginId] = (stats[error.pluginId] ?? 0) + 1;
    }
    return stats;
  }

  /// Get error count for a specific plugin
  int getErrorCount(String pluginId) {
    return _errors.where((error) => error.pluginId == pluginId).length;
  }

  /// Record a new error
  void recordError(PluginError error) {
    _errors.add(error);

    // Maintain size limit
    while (_errors.length > maxErrors) {
      _errors.removeAt(0);
    }

    notifyListeners();
  }

  /// Clear errors for a specific plugin
  void clearPluginErrors(String pluginId) {
    _errors.removeWhere((error) => error.pluginId == pluginId);
    notifyListeners();
  }

  /// Clear all errors
  void clearAllErrors() {
    _errors.clear();
    notifyListeners();
  }

  /// Clear old errors (older than specified duration)
  void clearOldErrors(Duration maxAge) {
    final cutoff = DateTime.now().subtract(maxAge);
    _errors.removeWhere((error) => error.timestamp.isBefore(cutoff));
    notifyListeners();
  }

  /// Get plugins with critical errors
  Set<String> getPluginsWithCriticalErrors() {
    return _errors
        .where((error) => error.isCritical)
        .map((error) => error.pluginId)
        .toSet();
  }

  /// Check if a plugin has exceeded error threshold
  bool hasExceededThreshold(String pluginId, int threshold) {
    return getErrorCount(pluginId) >= threshold;
  }

  @override
  void dispose() {
    _errors.clear();
    super.dispose();
  }
}
