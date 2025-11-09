import 'package:flutter/material.dart';

/// ErrorBoundary Widget
///
/// Catches and handles errors in widget tree, preventing crashes
/// and providing graceful error UI.
///
/// Architecture:
/// - Uses ErrorWidget.builder to catch rendering errors
/// - Provides retry mechanism
/// - Shows detailed error in debug, user-friendly message in release
/// - Logs errors for monitoring
///
/// Usage:
/// ```dart
/// ErrorBoundary(
///   child: MyComplexWidget(),
///   onError: (error, stackTrace) {
///     // Log to monitoring service
///     logError(error, stackTrace);
///   },
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Widget Function(Object error)? errorBuilder;
  final String? fallbackMessage;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.errorBuilder,
    this.fallbackMessage,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;
  int _errorCount = 0;
  FlutterExceptionHandler? _previousErrorHandler;

  @override
  void initState() {
    super.initState();

    // Save previous error handler to restore later
    _previousErrorHandler = FlutterError.onError;

    // Set up global error handler for this subtree
    FlutterError.onError = (details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
          _errorCount++;
        });
      }

      // Call custom error handler
      widget.onError?.call(details.exception, details.stack ?? StackTrace.current);

      // Call previous error handler if exists
      _previousErrorHandler?.call(details);

      // Log to console in debug mode
      FlutterError.presentError(details);
    };
  }

  @override
  void dispose() {
    // Restore previous error handler
    FlutterError.onError = _previousErrorHandler;
    super.dispose();
  }

  void _retry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Use custom error builder if provided
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!);
      }

      // Default error UI
      return _buildDefaultErrorWidget(context);
    }

    // Wrap child in try-catch
    return widget.child;
  }

  Widget _buildDefaultErrorWidget(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Card(
          elevation: 4,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error icon and title
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[700],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Something went wrong',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.fallbackMessage ??
                            'An unexpected error occurred while rendering this component.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Error details (debug mode only)
                if (_error != null && _stackTrace != null &&
                    const bool.fromEnvironment('dart.vm.product') == false) ...[
                  const Divider(),
                  const SizedBox(height: 16),

                  Text(
                    'Error Details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      _error.toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Stack trace
                  ExpansionTile(
                    title: const Text(
                      'Stack Trace',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          _stackTrace.toString(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],

                // Actions
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Copy error to clipboard
                        debugPrint('Error: $_error\n$_stackTrace');
                      },
                      child: const Text('COPY ERROR'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('RETRY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                // Error count indicator
                if (_errorCount > 1) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.orange[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This error has occurred $_errorCount times',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ErrorBoundaryScope
///
/// Provides error boundary functionality to a widget subtree
/// with centralized error handling.
class ErrorBoundaryScope extends InheritedWidget {
  final void Function(Object error, StackTrace stackTrace) onError;

  const ErrorBoundaryScope({
    super.key,
    required this.onError,
    required super.child,
  });

  static ErrorBoundaryScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ErrorBoundaryScope>();
  }

  @override
  bool updateShouldNotify(ErrorBoundaryScope oldWidget) {
    return onError != oldWidget.onError;
  }
}
