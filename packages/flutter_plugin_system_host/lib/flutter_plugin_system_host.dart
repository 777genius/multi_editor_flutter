/// Flutter Plugin System Host
///
/// Plugin host runtime for Flutter - manages plugin lifecycle, host functions,
/// messaging, security, and discovery. Provides the runtime environment for
/// executing plugins.
///
/// ## Features
///
/// - **Plugin Registry**: Central registry for plugin management and lifecycle
/// - **Host Functions**: Registry for host capabilities exposed to plugins
/// - **Event Dispatcher**: Pub/sub event system for plugin communication
/// - **Security**: Permission system and security guard for sandboxing
/// - **Error Isolation**: Error tracking and boundary for fault tolerance
///
/// ## Architecture
///
/// This package implements the host runtime layer of the plugin system:
///
/// ```
/// ┌─────────────────────────────────────┐
/// │  flutter_plugin_system_host         │
/// │  (Host Runtime)                     │
/// ├─────────────────────────────────────┤
/// │  - PluginRegistry                   │
/// │  - HostFunctionRegistry             │
/// │  - EventDispatcher                  │
/// │  - SecurityGuard                    │
/// │  - PermissionSystem                 │
/// │  - ErrorTracker                     │
/// │  - ErrorBoundary                    │
/// └─────────────────┬───────────────────┘
///                   │
/// ┌─────────────────▼───────────────────┐
/// │  flutter_plugin_system_core         │
/// │  (Pure Abstractions)                │
/// └─────────────────────────────────────┘
/// ```
///
/// ## Example
///
/// ```dart
/// import 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';
/// import 'package:flutter_plugin_system_host/flutter_plugin_system_host.dart';
///
/// // Create host components
/// final registry = PluginRegistry();
/// final hostFunctions = HostFunctionRegistry();
/// final eventDispatcher = EventDispatcher();
/// final permissionSystem = PermissionSystem();
/// final securityGuard = SecurityGuard(permissionSystem);
/// final errorTracker = ErrorTracker();
/// final errorBoundary = ErrorBoundary(errorTracker);
///
/// // Register a host function
/// hostFunctions.register('log_info', LogInfoFunction());
///
/// // Register plugin with permissions
/// permissionSystem.registerPlugin(
///   'plugin.example',
///   PluginPermissions(
///     allowedHostFunctions: ['log_info'],
///     maxExecutionTime: Duration(seconds: 5),
///   ),
/// );
///
/// // Register plugin in registry
/// registry.register('plugin.example', plugin, context);
///
/// // Dispatch event
/// eventDispatcher.dispatch(PluginEvent.now(
///   type: 'file.opened',
///   targetPluginId: 'plugin.example',
///   data: {'filename': 'main.dart'},
/// ));
/// ```
///
/// ## Related Packages
///
/// - **flutter_plugin_system_core**: Pure abstractions and interfaces
/// - **flutter_plugin_system_wasm**: WASM plugin adapter
/// - **flutter_plugin_system_native**: Native Dart plugin runtime
///
/// For more information, see the [architecture documentation](../../docs/PLUGIN_SYSTEM_ARCHITECTURE.md).
library flutter_plugin_system_host;

// Re-export core package for convenience
export 'package:flutter_plugin_system_core/flutter_plugin_system_core.dart';

// Export host components
export 'src/host.dart';
export 'src/messaging.dart';
export 'src/runtime.dart';
export 'src/security.dart';
