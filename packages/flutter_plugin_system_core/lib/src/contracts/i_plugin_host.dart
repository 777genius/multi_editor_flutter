import 'i_host_function.dart';

/// Plugin host interface
///
/// Defines capabilities that the host system provides to plugins.
/// This is the "other side" of the plugin contract - what plugins can call.
///
/// ## Design Principles
///
/// - **Interface Segregation**: Plugins only see what they need
/// - **Capability-based Security**: Explicit function registration
/// - **Dependency Inversion**: Plugins depend on interface, not implementation
///
/// ## Host Functions
///
/// Host functions are the primary way plugins interact with the host system.
/// Examples:
/// - File operations: `get_current_file`, `open_file`, `save_file`
/// - Editor operations: `get_selection`, `insert_text`, `format_document`
/// - LSP operations: `lsp_get_completions`, `lsp_get_hover`
/// - Logging: `log_info`, `log_error`, `log_debug`
///
/// ## Example Implementation
///
/// ```dart
/// class EditorHost implements IPluginHost {
///   final _functions = <String, HostFunction>{};
///
///   EditorHost() {
///     // Register host functions
///     registerHostFunction('get_current_file', GetCurrentFileFunction());
///     registerHostFunction('open_file', OpenFileFunction());
///     registerHostFunction('log_info', LogInfoFunction());
///   }
///
///   @override
///   void registerHostFunction<T>(String name, HostFunction<T> function) {
///     _functions[name] = function;
///   }
///
///   @override
///   Future<T> callHostFunction<T>(String name, List<dynamic> args) async {
///     final function = _functions[name];
///     if (function == null) {
///       throw HostFunctionNotFoundException(name);
///     }
///     return await function.call(args) as T;
///   }
///
///   @override
///   HostCapabilities get capabilities => HostCapabilities(
///     version: '1.0.0',
///     supportedFeatures: ['file_operations', 'lsp', 'logging'],
///   );
/// }
/// ```
abstract class IPluginHost {
  /// Register host function
  ///
  /// Makes a function available to plugins.
  /// Function name should be unique and follow naming convention.
  ///
  /// ## Naming Convention
  ///
  /// - Use snake_case: `get_current_file`, not `getCurrentFile`
  /// - Use namespace prefixes: `file_open`, `lsp_get_completions`
  /// - Be descriptive: `get_file_content`, not `getContent`
  ///
  /// ## Parameters
  ///
  /// - `name`: Unique function name
  /// - `function`: Function implementation
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Register file operations
  /// host.registerHostFunction('file_open', OpenFileFunction());
  /// host.registerHostFunction('file_save', SaveFileFunction());
  /// host.registerHostFunction('file_close', CloseFileFunction());
  ///
  /// // Register LSP operations
  /// host.registerHostFunction('lsp_get_completions', GetCompletionsFunction());
  /// host.registerHostFunction('lsp_get_hover', GetHoverFunction());
  ///
  /// // Register logging
  /// host.registerHostFunction('log_info', LogInfoFunction());
  /// host.registerHostFunction('log_error', LogErrorFunction());
  /// ```
  void registerHostFunction<T>(String name, HostFunction<T> function);

  /// Call host function
  ///
  /// Invokes a registered host function with arguments.
  /// Called by plugins through their PluginContext.
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name
  /// - `args`: Function arguments (positional)
  ///
  /// ## Returns
  ///
  /// Function result (typed as T)
  ///
  /// ## Throws
  ///
  /// - `HostFunctionNotFoundException`: If function not registered
  /// - `HostFunctionException`: If function execution fails
  /// - `PermissionDeniedException`: If plugin lacks permission
  ///
  /// ## Example
  ///
  /// ```dart
  /// // No arguments
  /// final file = await host.callHostFunction<FileDocument>('get_current_file', []);
  ///
  /// // With arguments
  /// await host.callHostFunction('open_file', ['/path/to/file.txt']);
  ///
  /// // With multiple arguments
  /// final completions = await host.callHostFunction<List<CompletionItem>>(
  ///   'lsp_get_completions',
  ///   ['file123', 10, 5],
  /// );
  /// ```
  Future<T> callHostFunction<T>(String name, List<dynamic> args);

  /// Get host capabilities
  ///
  /// Returns information about host system capabilities.
  /// Plugins can use this to adapt to different host environments.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final caps = host.capabilities;
  ///
  /// if (caps.supportsFeature('lsp')) {
  ///   // Use LSP features
  /// }
  ///
  /// if (caps.version >= '2.0.0') {
  ///   // Use new features
  /// }
  /// ```
  HostCapabilities get capabilities;

  // Optional: Batch operations for performance

  /// Check if host function exists
  ///
  /// **Security Note**: Default implementation returns `false` (deny-by-default).
  /// Implementations must explicitly advertise available functions.
  bool hasHostFunction(String name) => false;

  /// Get all available host function names
  List<String> getAvailableHostFunctions() => [];

  /// Batch call multiple host functions
  ///
  /// More efficient than calling individually.
  Future<List<dynamic>> batchCallHostFunctions(
    List<HostFunctionCall> calls,
  ) async {
    return Future.wait(
      calls.map((call) => callHostFunction(call.name, call.args)),
    );
  }
}

/// Host capabilities
///
/// Describes what the host system can do.
class HostCapabilities {
  /// Host version (semantic versioning)
  final String version;

  /// Supported features
  final List<String> supportedFeatures;

  /// Maximum concurrent plugins
  final int? maxPlugins;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const HostCapabilities({
    required this.version,
    required this.supportedFeatures,
    this.maxPlugins,
    this.metadata,
  });

  /// Check if feature is supported
  bool supportsFeature(String feature) {
    return supportedFeatures.contains(feature);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'version': version,
        'supportedFeatures': supportedFeatures,
        if (maxPlugins != null) 'maxPlugins': maxPlugins,
        if (metadata != null) ...metadata!,
      };
}

/// Host function call descriptor
///
/// Used for batch operations.
class HostFunctionCall {
  /// Function name
  final String name;

  /// Function arguments
  final List<dynamic> args;

  const HostFunctionCall(this.name, [this.args = const []]);
}
