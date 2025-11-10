import '../models/plugin_context.dart';
import '../models/plugin_event.dart';
import '../models/plugin_manifest.dart';
import '../models/plugin_response.dart';

/// Base plugin interface
///
/// All plugins (WASM, Native, Script) implement this interface.
/// This is the primary contract for plugin lifecycle and communication.
///
/// ## Design Principles
///
/// - **Open/Closed Principle**: Plugins extend without modifying host
/// - **Liskov Substitution**: All implementations are interchangeable
/// - **Dependency Inversion**: Host depends on interface, not implementation
///
/// ## Lifecycle
///
/// ```
/// create() → initialize(context) → ready → handleEvent() → dispose()
/// ```
///
/// ## Example Implementation
///
/// ```dart
/// class MyPlugin implements IPlugin {
///   @override
///   PluginManifest get manifest => PluginManifest(
///     id: 'com.example.my-plugin',
///     name: 'My Plugin',
///     version: '1.0.0',
///     description: 'Example plugin',
///     runtime: PluginRuntimeType.native,
///   );
///
///   @override
///   Future<void> initialize(PluginContext context) async {
///     // Setup plugin
///   }
///
///   @override
///   Future<PluginResponse> handleEvent(PluginEvent event) async {
///     // Process event
///     return PluginResponse.success();
///   }
///
///   @override
///   Future<void> dispose() async {
///     // Cleanup
///   }
/// }
/// ```
abstract class IPlugin {
  /// Plugin manifest
  ///
  /// Describes plugin metadata, permissions, and requirements.
  /// Must be available before initialization.
  PluginManifest get manifest;

  /// Initialize plugin
  ///
  /// Called once after plugin is loaded but before it receives events.
  /// Plugin should setup internal state and register with services.
  ///
  /// ## Parameters
  ///
  /// - `context`: Isolated context with access to host functions
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// Future<void> initialize(PluginContext context) async {
  ///   // Register service
  ///   context.registerService<MyCache>(MyCache());
  ///
  ///   // Call host function
  ///   final capabilities = await context.callHost('get_capabilities');
  ///
  ///   // Setup internal state
  ///   await _loadConfig();
  /// }
  /// ```
  Future<void> initialize(PluginContext context);

  /// Handle event
  ///
  /// Called when plugin receives an event from host or another plugin.
  /// Plugin should process the event and return a response.
  ///
  /// ## Parameters
  ///
  /// - `event`: Event to handle (contains type, data, metadata)
  ///
  /// ## Returns
  ///
  /// `PluginResponse` indicating success or failure
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// Future<PluginResponse> handleEvent(PluginEvent event) async {
  ///   switch (event.type) {
  ///     case 'file.opened':
  ///       final filename = event.getData<String>('filename');
  ///       final icon = await _resolveIcon(filename);
  ///       return PluginResponse.success(data: {'icon': icon});
  ///
  ///     default:
  ///       return PluginResponse.error(
  ///         message: 'Unknown event type: ${event.type}',
  ///       );
  ///   }
  /// }
  /// ```
  Future<PluginResponse> handleEvent(PluginEvent event);

  /// Dispose plugin
  ///
  /// Called when plugin is being unloaded.
  /// Plugin should cleanup resources, close connections, and cancel subscriptions.
  ///
  /// ## Example
  ///
  /// ```dart
  /// @override
  /// Future<void> dispose() async {
  ///   await _cache.clear();
  ///   await _httpClient.close();
  ///   _subscription?.cancel();
  /// }
  /// ```
  Future<void> dispose();

  // Optional lifecycle hooks

  /// Called after plugin is loaded but before initialization
  ///
  /// Useful for early setup that doesn't require host access.
  Future<void> onLoad() async {}

  /// Called after successful initialization
  ///
  /// Plugin is now ready to receive events.
  Future<void> onReady() async {}

  /// Called before plugin is disposed
  ///
  /// Last chance to save state or notify other systems.
  Future<void> onBeforeDispose() async {}

  /// Called when plugin encounters an error
  ///
  /// Plugin can handle the error gracefully or let it propagate.
  Future<void> onError(Object error, StackTrace? stackTrace) async {}
}
