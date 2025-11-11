import 'dart:async';
import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
import '../host/host_function_registry.dart';
import '../messaging/event_dispatcher.dart';
import '../security/error_boundary.dart';
import '../security/error_tracker.dart';
import '../security/permission_system.dart';
import '../security/security_guard.dart';
import 'plugin_registry.dart';

/// Plugin manager
///
/// Facade that provides a unified interface to the plugin system.
/// Implements the Facade pattern from architecture document (lines 1278-1303).
///
/// ## Design Principles
///
/// - **Facade Pattern**: Simplifies complex subsystem interactions
/// - **Orchestration**: Coordinates all plugin system components
/// - **Unified Interface**: Single entry point for plugin operations
///
/// ## Architecture
///
/// ```
/// PluginManager (Facade)
///     ├── PluginRegistry (lifecycle)
///     ├── HostFunctionRegistry (capabilities)
///     ├── EventDispatcher (messaging)
///     ├── PermissionSystem (security)
///     ├── SecurityGuard (enforcement)
///     ├── ErrorTracker (monitoring)
///     └── ErrorBoundary (isolation)
/// ```
///
/// ## Example
///
/// ```dart
/// // Create manager with dependencies
/// final manager = PluginManager(
///   registry: PluginRegistry(),
///   hostFunctions: HostFunctionRegistry(),
///   eventDispatcher: EventDispatcher(),
///   permissionSystem: PermissionSystem(),
///   securityGuard: SecurityGuard(permissionSystem),
///   errorTracker: ErrorTracker(),
///   errorBoundary: ErrorBoundary(errorTracker),
/// );
///
/// // Register host functions
/// manager.registerHostFunction('log_info', LogInfoFunction());
///
/// // Load plugin
/// await manager.loadPlugin(
///   manifest: manifest,
///   source: PluginSource.file(path: 'plugin.wasm'),
///   runtime: wasmRuntime,
/// );
///
/// // Send event to plugin
/// final response = await manager.sendEvent(
///   PluginEvent.now(
///     type: 'file.opened',
///     targetPluginId: 'plugin.example',
///     data: {'filename': 'main.dart'},
///   ),
/// );
/// ```
class PluginManager {
  final PluginRegistry _registry;
  final HostFunctionRegistry _hostFunctions;
  final EventDispatcher _eventDispatcher;
  final PermissionSystem _permissionSystem;
  final SecurityGuard _securityGuard;
  final ErrorTracker _errorTracker;
  final ErrorBoundary _errorBoundary;

  // Track event subscriptions for cleanup
  final Map<String, List<StreamSubscription<PluginEvent>>> _eventSubscriptions =
      {};

  /// Create plugin manager
  ///
  /// ## Parameters
  ///
  /// - `registry`: Plugin registry for lifecycle management
  /// - `hostFunctions`: Host function registry
  /// - `eventDispatcher`: Event dispatcher for messaging
  /// - `permissionSystem`: Permission system for security
  /// - `securityGuard`: Security guard for enforcement
  /// - `errorTracker`: Error tracker for monitoring
  /// - `errorBoundary`: Error boundary for isolation
  PluginManager({
    required PluginRegistry registry,
    required HostFunctionRegistry hostFunctions,
    required EventDispatcher eventDispatcher,
    required PermissionSystem permissionSystem,
    required SecurityGuard securityGuard,
    required ErrorTracker errorTracker,
    required ErrorBoundary errorBoundary,
  })  : _registry = registry,
        _hostFunctions = hostFunctions,
        _eventDispatcher = eventDispatcher,
        _permissionSystem = permissionSystem,
        _securityGuard = securityGuard,
        _errorTracker = errorTracker,
        _errorBoundary = errorBoundary;

  /// Create default plugin manager
  ///
  /// Creates a plugin manager with default implementations of all components.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final manager = PluginManager.create();
  /// ```
  factory PluginManager.create() {
    final registry = PluginRegistry();
    final hostFunctions = HostFunctionRegistry();
    final eventDispatcher = EventDispatcher();
    final permissionSystem = PermissionSystem();
    final securityGuard = SecurityGuard(permissionSystem);
    final errorTracker = ErrorTracker();
    final errorBoundary = ErrorBoundary(errorTracker);

    return PluginManager(
      registry: registry,
      hostFunctions: hostFunctions,
      eventDispatcher: eventDispatcher,
      permissionSystem: permissionSystem,
      securityGuard: securityGuard,
      errorTracker: errorTracker,
      errorBoundary: errorBoundary,
    );
  }

  // ============================================================================
  // Plugin Lifecycle
  // ============================================================================

  /// Load plugin
  ///
  /// Loads a plugin using the specified runtime and registers it in the system.
  ///
  /// ## Process
  ///
  /// 1. Validate manifest
  /// 2. Check runtime compatibility
  /// 3. Register permissions
  /// 4. Load plugin through runtime
  /// 5. Create plugin context
  /// 6. Initialize plugin
  /// 7. Register in registry
  /// 8. Update state to ready
  ///
  /// ## Parameters
  ///
  /// - `manifest`: Plugin manifest
  /// - `source`: Plugin source (file, URL, memory)
  /// - `runtime`: Runtime to load plugin with
  /// - `config`: Optional plugin configuration
  /// - `permissions`: Optional custom permissions (defaults from manifest)
  ///
  /// ## Throws
  ///
  /// - [PluginLoadException] if loading fails
  /// - [PluginInitializationException] if initialization fails
  /// - [PermissionDeniedException] if permissions invalid
  ///
  /// ## Example
  ///
  /// ```dart
  /// await manager.loadPlugin(
  ///   manifest: PluginManifest(
  ///     id: 'plugin.example',
  ///     name: 'Example',
  ///     version: '1.0.0',
  ///     description: 'Example plugin',
  ///     runtime: PluginRuntimeType.wasm,
  ///     requiredHostFunctions: ['log_info'],
  ///   ),
  ///   source: PluginSource.file(path: 'plugin.wasm'),
  ///   runtime: wasmRuntime,
  /// );
  /// ```
  Future<void> loadPlugin({
    required PluginManifest manifest,
    required PluginSource source,
    required IPluginRuntime runtime,
    PluginConfig? config,
    PluginPermissions? permissions,
  }) async {
    final pluginId = manifest.id;

    // Pre-register with unloaded state to enable state tracking
    IPlugin? loadedPlugin;
    PluginContext? pluginContext;

    try {
      // 1. Validate manifest
      _validateManifest(manifest);

      // 2. Check runtime compatibility
      if (!runtime.isCompatible(manifest)) {
        throw PluginLoadException(
          'Runtime ${runtime.type} not compatible with plugin ${manifest.runtime}',
          pluginId: pluginId,
        );
      }

      // 3. Register permissions
      final pluginPermissions = permissions ??
          PluginPermissions(
            allowedHostFunctions: manifest.requiredHostFunctions,
          );
      _permissionSystem.registerPlugin(pluginId, pluginPermissions);

      // 4. Load plugin through runtime
      loadedPlugin = await runtime.loadPlugin(
        pluginId: pluginId,
        source: source,
        config: config,
      );

      // 5. Create plugin context
      pluginContext = _createPluginContext(
        pluginId: pluginId,
        config: config ?? const PluginConfig(),
      );

      // 6. Register in registry with loaded state
      _registry.register(
        pluginId,
        loadedPlugin,
        pluginContext,
        state: PluginState.loaded,
      );

      // 7. Initialize plugin (with timeout and error isolation)
      _registry.updateState(pluginId, PluginState.initializing);
      await _errorBoundary.execute(
        pluginId,
        () => _securityGuard.executeWithTimeout(
          pluginId,
          () => loadedPlugin!.initialize(pluginContext!),
        ),
      );

      // 8. Update to ready state
      _registry.updateState(pluginId, PluginState.ready);

      // 9. Subscribe to events
      _subscribeToEvents(pluginId, manifest.subscribesTo);
    } catch (e) {
      // Clean up on error
      if (_registry.isLoaded(pluginId)) {
        _registry.updateState(pluginId, PluginState.error);
      }
      _permissionSystem.unregisterPlugin(pluginId);
      rethrow;
    }
  }

  /// Unload plugin
  ///
  /// Unloads a plugin and cleans up all resources.
  ///
  /// ## Process
  ///
  /// 1. Get plugin from registry
  /// 2. Call plugin dispose
  /// 3. Unregister from registry
  /// 4. Unregister permissions
  /// 5. Clear errors
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Throws
  ///
  /// - [PluginNotFoundException] if plugin not found
  ///
  /// ## Example
  ///
  /// ```dart
  /// await manager.unloadPlugin('plugin.example');
  /// ```
  Future<void> unloadPlugin(String pluginId) async {
    final plugin = _registry.getPlugin(pluginId);
    if (plugin == null) {
      throw PluginNotFoundException(pluginId);
    }

    await _errorBoundary.execute(
      pluginId,
      () async {
        // 1. Cancel event subscriptions
        await _unsubscribeFromEvents(pluginId);

        // 2. Dispose plugin
        await plugin.dispose();

        // 3. Unregister from registry
        _registry.unregister(pluginId);

        // 4. Unregister permissions
        _permissionSystem.unregisterPlugin(pluginId);
      },
      fallback: (error) async {
        // Even if dispose fails, clean up
        await _unsubscribeFromEvents(pluginId);
        _registry.unregister(pluginId);
        _permissionSystem.unregisterPlugin(pluginId);
      },
    );
  }

  /// Reload plugin
  ///
  /// Reloads a plugin (unload + load).
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  /// - `manifest`: Plugin manifest (can be updated)
  /// - `source`: Plugin source
  /// - `runtime`: Runtime to load plugin with
  /// - `config`: Optional plugin configuration
  ///
  /// ## Example
  ///
  /// ```dart
  /// await manager.reloadPlugin(
  ///   pluginId: 'plugin.example',
  ///   manifest: updatedManifest,
  ///   source: PluginSource.file(path: 'plugin.wasm'),
  ///   runtime: wasmRuntime,
  /// );
  /// ```
  Future<void> reloadPlugin({
    required String pluginId,
    required PluginManifest manifest,
    required PluginSource source,
    required IPluginRuntime runtime,
    PluginConfig? config,
  }) async {
    await unloadPlugin(pluginId);
    await loadPlugin(
      manifest: manifest,
      source: source,
      runtime: runtime,
      config: config,
    );
  }

  // ============================================================================
  // Event Messaging
  // ============================================================================

  /// Send event to plugin
  ///
  /// Sends an event to a specific plugin and returns its response.
  ///
  /// ## Parameters
  ///
  /// - `event`: Plugin event
  ///
  /// ## Returns
  ///
  /// Plugin response
  ///
  /// ## Throws
  ///
  /// - [PluginNotFoundException] if plugin not found
  /// - [PluginExecutionException] if event handling fails
  ///
  /// ## Example
  ///
  /// ```dart
  /// final response = await manager.sendEvent(
  ///   PluginEvent.now(
  ///     type: 'file.opened',
  ///     targetPluginId: 'plugin.example',
  ///     data: {'filename': 'main.dart'},
  ///   ),
  /// );
  /// ```
  Future<PluginResponse> sendEvent(PluginEvent event) async {
    final pluginId = event.targetPluginId;
    if (pluginId == null) {
      throw ArgumentError('Event must have targetPluginId');
    }

    final plugin = _registry.getPlugin(pluginId);
    if (plugin == null) {
      throw PluginNotFoundException(pluginId);
    }

    return await _errorBoundary.execute(
      pluginId,
      () => _securityGuard.executeWithTimeout(
        pluginId,
        () => plugin.handleEvent(event),
      ),
      fallback: (error) => PluginResponse.error(
        message: 'Event handling failed: $error',
      ),
    );
  }

  /// Dispatch event
  ///
  /// Dispatches an event to all subscribed plugins via the event bus.
  ///
  /// ## Parameters
  ///
  /// - `event`: Plugin event
  ///
  /// ## Example
  ///
  /// ```dart
  /// manager.dispatchEvent(
  ///   PluginEvent.now(
  ///     type: 'file.saved',
  ///     data: {'filename': 'main.dart'},
  ///   ),
  /// );
  /// ```
  void dispatchEvent(PluginEvent event) {
    _eventDispatcher.dispatch(event);
  }

  /// Get event stream
  ///
  /// Returns the event stream for subscribing to events.
  ///
  /// ## Returns
  ///
  /// Stream of plugin events
  ///
  /// ## Example
  ///
  /// ```dart
  /// manager.eventStream.listen((event) {
  ///   print('Event: ${event.type}');
  /// });
  /// ```
  Stream<PluginEvent> get eventStream => _eventDispatcher.stream;

  // ============================================================================
  // Host Functions
  // ============================================================================

  /// Register host function
  ///
  /// Registers a host function that plugins can call.
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name
  /// - `function`: Host function implementation
  ///
  /// ## Example
  ///
  /// ```dart
  /// manager.registerHostFunction('log_info', LogInfoFunction());
  /// ```
  void registerHostFunction<T>(String name, HostFunction<T> function) {
    _hostFunctions.register(name, function);
  }

  /// Unregister host function
  ///
  /// Removes a host function from the registry.
  ///
  /// ## Parameters
  ///
  /// - `name`: Function name
  ///
  /// ## Example
  ///
  /// ```dart
  /// manager.unregisterHostFunction('log_info');
  /// ```
  void unregisterHostFunction(String name) {
    _hostFunctions.unregister(name);
  }

  /// Call host function
  ///
  /// Calls a host function with permission check.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier (for permission check)
  /// - `name`: Function name
  /// - `args`: Function arguments
  ///
  /// ## Returns
  ///
  /// Function result
  ///
  /// ## Throws
  ///
  /// - [PermissionDeniedException] if permission denied
  /// - [HostFunctionNotFoundException] if function not found
  ///
  /// ## Example
  ///
  /// ```dart
  /// final result = await manager.callHostFunction<void>(
  ///   'plugin.example',
  ///   'log_info',
  ///   ['Hello, world!'],
  /// );
  /// ```
  Future<T> callHostFunction<T>(
    String pluginId,
    String name,
    List<dynamic> args,
  ) async {
    // Check permission
    _securityGuard.enforceHostFunctionPermission(pluginId, name);

    // Call function
    return await _hostFunctions.call<T>(name, args);
  }

  // ============================================================================
  // Query Methods
  // ============================================================================

  /// Get plugin
  ///
  /// Returns the plugin instance for the specified ID.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// Plugin instance, or null if not found
  IPlugin? getPlugin(String pluginId) {
    return _registry.getPlugin(pluginId);
  }

  /// Get all plugins
  ///
  /// Returns all loaded plugins.
  ///
  /// ## Returns
  ///
  /// Map of pluginId → plugin
  Map<String, IPlugin> getAllPlugins() {
    return _registry.getAllPlugins();
  }

  /// Get plugins by state
  ///
  /// Returns all plugins in the specified state.
  ///
  /// ## Parameters
  ///
  /// - `state`: Plugin state
  ///
  /// ## Returns
  ///
  /// Map of pluginId → plugin
  Map<String, IPlugin> getPluginsByState(PluginState state) {
    return _registry.getPluginsByState(state);
  }

  /// Check if plugin is loaded
  ///
  /// Returns true if the plugin is loaded.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// `true` if loaded, `false` otherwise
  bool isLoaded(String pluginId) {
    return _registry.isLoaded(pluginId);
  }

  /// Get plugin state
  ///
  /// Returns the current state of the plugin.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// Plugin state, or null if not found
  PluginState? getPluginState(String pluginId) {
    return _registry.getState(pluginId);
  }

  // ============================================================================
  // Statistics & Monitoring
  // ============================================================================

  /// Get system statistics
  ///
  /// Returns comprehensive statistics about the plugin system.
  ///
  /// ## Returns
  ///
  /// Map with statistics:
  /// - `registry`: Plugin registry statistics
  /// - `host_functions`: Host function statistics
  /// - `events`: Event dispatcher statistics
  /// - `permissions`: Permission system statistics
  ///
  /// ## Example
  ///
  /// ```dart
  /// final stats = manager.getStatistics();
  /// print('Total plugins: ${stats['registry']['total_plugins']}');
  /// print('Total events: ${stats['events']['total_events']}');
  /// ```
  Map<String, dynamic> getStatistics() {
    return {
      'registry': _registry.getStatistics(),
      'host_functions': _hostFunctions.getStatistics(),
      'events': _eventDispatcher.getStatistics(),
      'permissions': _permissionSystem.getStatistics(),
    };
  }

  /// Get plugin errors
  ///
  /// Returns all errors for the specified plugin.
  ///
  /// ## Parameters
  ///
  /// - `pluginId`: Plugin identifier
  ///
  /// ## Returns
  ///
  /// List of plugin errors
  List<PluginError> getPluginErrors(String pluginId) {
    return _errorTracker.getErrors(pluginId);
  }

  /// Get error stream
  ///
  /// Returns the error stream for monitoring errors.
  ///
  /// ## Returns
  ///
  /// Stream of plugin errors
  ///
  /// ## Example
  ///
  /// ```dart
  /// manager.errorStream.listen((error) {
  ///   print('Error in ${error.pluginId}: ${error.message}');
  /// });
  /// ```
  Stream<PluginError> get errorStream => _errorTracker.errors;

  // ============================================================================
  // Cleanup
  // ============================================================================

  /// Dispose all plugins and clean up resources
  ///
  /// Unloads all plugins and cleans up the plugin system.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await manager.dispose();
  /// ```
  Future<void> dispose() async {
    // Get all plugin IDs
    final pluginIds = _registry.getAllPluginIds();

    // Unload all plugins - continue even if some fail
    // Use for-loop instead of Future.wait to ensure all plugins get unloaded
    for (final id in pluginIds) {
      try {
        await unloadPlugin(id);
      } catch (e, st) {
        // Log error but continue with other plugins
        _errorTracker.trackError(
          PluginErrorInfo(
            pluginId: id,
            message: 'Error unloading plugin during dispose: $e',
            originalError: e,
            stackTrace: st,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    // Dispose event dispatcher
    await _eventDispatcher.dispose();

    // Dispose error tracker
    await _errorTracker.dispose();
  }

  // ============================================================================
  // Private Helpers
  // ============================================================================

  void _validateManifest(PluginManifest manifest) {
    if (manifest.id.isEmpty) {
      throw InvalidManifestException('Plugin ID cannot be empty');
    }
    if (manifest.version.isEmpty) {
      throw InvalidManifestException('Plugin version cannot be empty');
    }
  }

  PluginContext _createPluginContext({
    required String pluginId,
    required PluginConfig config,
  }) {
    return PluginContext(
      pluginId: pluginId,
      host: _PluginHost(this, pluginId),
      config: config,
    );
  }

  void _subscribeToEvents(String pluginId, List<String> eventTypes) {
    if (eventTypes.isEmpty) return;

    final plugin = _registry.getPlugin(pluginId);
    if (plugin == null) return;

    // Initialize subscriptions list for this plugin
    _eventSubscriptions[pluginId] = [];

    // Subscribe to each event type and store subscription
    for (final eventType in eventTypes) {
      final subscription =
          _eventDispatcher.streamFor(eventType).listen((event) async {
        // Get plugin again (don't capture in closure)
        final currentPlugin = _registry.getPlugin(pluginId);
        if (currentPlugin == null) return;

        await _errorBoundary.execute(
          pluginId,
          () => _securityGuard.executeWithTimeout(
            pluginId,
            () => currentPlugin.handleEvent(event),
          ),
        );
      });

      _eventSubscriptions[pluginId]!.add(subscription);
    }
  }

  Future<void> _unsubscribeFromEvents(String pluginId) async {
    final subscriptions = _eventSubscriptions.remove(pluginId);
    if (subscriptions != null) {
      // Wait for all subscriptions to cancel to avoid race conditions
      await Future.wait(
        subscriptions.map((sub) => sub.cancel()),
      );
    }
  }
}

// ============================================================================
// Internal Plugin Host Implementation
// ============================================================================

/// Internal plugin host implementation
///
/// Provides host capabilities to plugins with permission enforcement.
class _PluginHost implements IPluginHost {
  final PluginManager _manager;
  final String _pluginId;

  _PluginHost(this._manager, this._pluginId);

  @override
  void registerHostFunction<T>(String name, HostFunction<T> function) {
    throw UnsupportedError('Plugins cannot register host functions');
  }

  @override
  Future<T> callHostFunction<T>(String name, List<dynamic> args) {
    return _manager.callHostFunction<T>(_pluginId, name, args);
  }

  @override
  HostCapabilities get capabilities {
    final permissions = _manager._permissionSystem.getPermissions(_pluginId);
    return HostCapabilities(
      availableFunctions: permissions.allowedHostFunctions,
      supportsAsync: true,
      maxExecutionTime: permissions.maxExecutionTime,
    );
  }
}
